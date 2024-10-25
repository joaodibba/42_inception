#!/bin/sh

function with_backoff {
  local max_attempts=${ATTEMPTS-5}
  local timeout=${TIMEOUT-1}
  local attempt=0
  local exitCode=0

  while [[ $attempt < $max_attempts ]]
  do
    "$@"
    exitCode=$?

    if [[ $exitCode == 0 ]]
    then
      break
    fi

    echo "Failure! Retrying in $timeout.." 1>&2
    sleep $timeout
    attempt=$(( attempt + 1 ))
    timeout=$(( timeout * 2 ))
  done

  if [[ $exitCode != 0 ]]
  then
    echo "You've failed me for the last time! ($@)" 1>&2
  fi

  return $exitCode
}

with_backoff mariadb -h $WORDPRESS_DB_HOST -u$WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD $WORDPRESS_DB_NAME &>/dev/null;

if [ ! -f "/opt/setup_done" ]; then

    echo "Setting up WordPress for the first time"
    wp core download --allow-root

    echo "Creating wp-config.php"
    wp config create \
        --dbname=$WORDPRESS_DB_NAME \
        --dbuser=$WORDPRESS_DB_USER \
        --dbpass=$WORDPRESS_DB_PASSWORD \
        --dbhost=$WORDPRESS_DB_HOST \
        --dbcharset=$WORDPRESS_DB_CHARSET \
        --dbcollate=$WORDPRESS_DB_COLLATION \
        --allow-root
    echo "Installing WordPress"
    wp core install \
        --url=$DOMAIN_NAME/wordpress \
        --title=$COMPOSE_PROJECT_NAME \
        --admin_user=$WORDPRESS_ADMIN \
        --admin_email=$WORDPRESS_ADMIN_EMAIL \
        --admin_password=$WORDPRESS_ADMIN_PASSWORD \
        --skip-email \
        --allow-root

    echo "Creating user $WORDPRESS_USER"
    wp user create $WORDPRESS_USER $WORDPRESS_USER_EMAIL \
        --role=author \
        --user_pass=$WORDPRESS_USER_PASSWORD \
        --allow-root

    wp theme install inspiro --activate --allow-root

    wp plugin install wp-healthcheck --activate --allow-root

    touch /opt/setup_done
fi

/usr/sbin/php-fpm7 -F