#!/bin/sh

set -euo pipefail

MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-""}
MYSQL_DATABASE=${DB_NAME:-""}
MYSQL_USER=${DB_USER:-""}
MYSQL_PASSWORD=${DB_PASS:-""}

execute_pre_init_scripts() {
    for i in /scripts/pre-init.d/*sh
    do
        if [ -e "${i}" ]; then
            echo "[i] pre-init.d - processing $i"
            . "${i}"
        fi
    done
}

setup_mysqld_directory() {
    if [ -d "/run/mysqld" ]; then
        echo "[i] mysqld already present, skipping creation"
        chown -R mysql:mysql /run/mysqld
    else
        echo "[i] mysqld not found, creating...."
        mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld
    fi
}

initialize_mysql_data_directory() {
    if [ -d /var/lib/mysql/mysql ]; then
        echo "[i] MySQL directory already present, skipping creation"
        chown -R mysql:mysql /var/lib/mysql
    else
        echo "[i] MySQL data directory not found, creating initial DBs"
        chown -R mysql:mysql /var/lib/mysql
        mysql_install_db --user=mysql --ldata=/var/lib/mysql > /dev/null
        create_initial_mysql_config
    fi
}

create_initial_mysql_config() {
    tfile=`mktemp`
    if [ ! -f "$tfile" ]; then
        return 1
    fi

    cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES ;
GRANT ALL ON *.* TO 'root'@'%' identified by '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION ;
GRANT ALL ON *.* TO 'root'@'localhost' identified by '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION ;
SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}') ;
DROP DATABASE IF EXISTS test ;
FLUSH PRIVILEGES ;
EOF

    if [ "$MYSQL_DATABASE" != "" ]; then
        echo "[i] with character set: 'utf8' and collation: 'utf8_general_ci'"
        echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile
        if [ "$MYSQL_USER" != "" ]; then
            echo "[i] Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
            echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
        fi
    fi

    /usr/bin/mysqld --user=mysql --bootstrap --verbose=0 --skip-name-resolve --skip-networking=0 < $tfile
    rm -f $tfile

    process_seed_files
    echo "[i] MySQL init process done. Ready for start up."
}

process_seed_files() {
    if [ "$MYSQL_DATABASE" != "" ] && [ "$(ls -A /scripts/docker-entrypoint-initdb.d 2>/dev/null)" ]; then
        echo
        echo "Preparing to process the contents of /scripts/docker-entrypoint-initdb.d"
        echo
        TEMP_OUTPUT_LOG=/tmp/mysqld_output
        /usr/bin/mysqld --user=mysql --skip-name-resolve --skip-networking=0 --silent-startup > "${TEMP_OUTPUT_LOG}" 2>&1 &
        PID="$!"

        until tail "${TEMP_OUTPUT_LOG}" | grep -q "Version:"; do
            sleep 0.2
        done

        MYSQL_CLIENT="/usr/bin/mysql -u root -p$MYSQL_ROOT_PASSWORD"

        for f in /scripts/docker-entrypoint-initdb.d/*; do
            case "$f" in
                *.sql)    echo "  $0: running $f"; eval "${MYSQL_CLIENT} ${MYSQL_DATABASE} < $f"; echo ;;
                *.sql.gz) echo "  $0: running $f"; gunzip -c "$f" | eval "${MYSQL_CLIENT} ${MYSQL_DATABASE}"; echo ;;
            esac
        done

        kill -s TERM "${PID}"
        wait "${PID}"
        rm -f TEMP_OUTPUT_LOG
        echo "Completed processing seed files."
    fi
}

execute_pre_exec_scripts() {
    for i in /scripts/pre-exec.d/*sh
    do
        if [ -e "${i}" ]; then
            echo "[i] pre-exec.d - processing $i"
            . ${i}
        fi
    done
}

main() {
    execute_pre_init_scripts
    setup_mysqld_directory
    initialize_mysql_data_directory

    echo
    echo 'MySQL init process done. Ready for start up.'
    echo

    execute_pre_exec_scripts

    exec /usr/bin/mysqld --user=mysql --console --skip-name-resolve --skip-networking=0 "$@"
}

main "$@"