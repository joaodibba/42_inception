#!/bin/sh

MYSQL_ROOT_PASSWORD==${MYSQL_ROOT_PASSWORD:-"mysql"}
MYSQL_DATABASE=${MYSQL_DATABASE:-"mysql"}
MYSQL_USER=${MYSQL_USER:-"mysql"}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-"mysql"}
BIND_ADDRESS=${BIND_ADDRESS:-"0.0.0.0"}
MYSQL_CHARSET=${MYSQL_CHARSET:-"utf8"}
MYSQL_COLLATION=${MYSQL_COLLATION:-"utf8_general_ci"}

exec_pre_init_scripts() {
    for i in /scripts/pre-init.d/*sh
    do
        if [ -e "${i}" ]; then
            echo "[i] pre-init.d - processing $i"
            . "${i}"
        fi
    done
}

create_mysqld_directory() {
    if [ -d "/run/mysqld" ]; then
        echo "[i] mysqld already present, skipping creation"
        chown -R mysql:mysql /run/mysqld
    else
        echo "[i] mysqld not found, creating...."
        mkdir -p /run/mysqld
        chown -R mysql:mysql /run/mysqld
    fi
}

create_initial_mysql_database(){
    if [ -d /var/lib/mysql/$MYSQL_DATABASE ]; then
        echo "[i] MySQL directory already present, skipping creation"
        chown -R mysql:mysql /var/lib/mysql
    else
        echo "[i] MySQL data directory not found, creating initial DBs"

        chown -R mysql:mysql /var/lib/mysql

        mysql_install_db -u=$MYSQL_USER --ldata=/var/lib/mysql > /dev/null

        tfile=$(mktemp)
        if [ ! -f "$tfile" ]; then
            return 1
        fi

    cat << EOF > $tfile
USE mysql;

-- Reload grant tables (only once at the end or before changes)
FLUSH PRIVILEGES;

-- Grant privileges to root for remote and localhost access
GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;
GRANT ALL ON *.* TO 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;

-- Update the password for root@localhost using the modern way
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Drop the test database if it exists
DROP DATABASE IF EXISTS test;

-- Create the specified database with character set and collation
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE} CHARACTER SET ${MYSQL_CHARSET} COLLATE ${MYSQL_COLLATION};

-- Create a new user and grant privileges for the specific database
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- (Optional) Grant global privileges to the new user (use with caution)
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;

-- Reload the grant tables (you only need this once)
FLUSH PRIVILEGES;

EOF

        mysqld --user=mysql --bootstrap --verbose=0 --skip-name-resolve --silent-startup --skip-networking=0 < $tfile 2>&1 &
        rm -f $tfile
        fi
}

process_docker_entrypoint_initdb_scripts() {
    if [ -d "/var/lib/mysql/$DB_NAME" ]; then
        return
    fi

    if [ "$(ls -A /docker-entrypoint-initdb.d 2>/dev/null)" ]; then
        echo
        echo "Preparing to process the contents of /docker-entrypoint-initdb.d/"
        echo
        TEMP_OUTPUT_LOG=/tmp/mysqld_output
        mysqld --user=mysql --skip-name-resolve --skip-networking=0 --silent-startup > "$TEMP_OUTPUT_LOG" 2>&1 &
        PID="$!"

        until tail "$TEMP_OUTPUT_LOG" | grep -q "Version:"; do
            sleep 0.2
        done

        for f in /docker-entrypoint-initdb.d/*; do
            if [ "${f##*.}" = "sql" ]; then
                echo "[i] docker-entrypoint-initdb.d - processing $f"
                mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < "$f"
                echo "[i] docker-entrypoint-initdb.d - Completed processing $f"
            fi
        done

        kill -s TERM $PID
        wait $PID
        rm -f "$TEMP_OUTPUT_LOG"
        echo "Completed processing the contents of /docker-entrypoint-initdb.d/"
    fi
}


exec_pre_exec_scripts() {
    if [ -d "/var/lib/mysql/$DB_NAME" ]; then
        return
    fi

    for i in /scripts/pre-exec.d/*sh
    do
        if [ -e $i ]; then
            echo "[i] pre-exec.d - processing $i"
            exec "$i"
        fi
    done
}

main() {

    exec_pre_init_scripts
    create_mysqld_directory
    create_initial_mysql_database
    process_docker_entrypoint_initdb_scripts

    echo
    echo 'MySQL init process done. Ready for start up.'
    echo

    exec_pre_exec_scripts
    exec mysqld --user=mysql --console --skip-name-resolve --bind-address=$BIND_ADDRESS

}

main