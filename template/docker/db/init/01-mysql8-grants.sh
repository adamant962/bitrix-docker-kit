#!/usr/bin/env bash
set -e

VERSION="$(mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -Nse "SELECT VERSION();")"

case "$VERSION" in
  8.*)
    echo "MySQL 8 detected: $VERSION"
    echo "Granting SESSION_VARIABLES_ADMIN and SYSTEM_VARIABLES_ADMIN to $MYSQL_USER..."

    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
      GRANT SESSION_VARIABLES_ADMIN ON *.* TO '$MYSQL_USER'@'%';
      GRANT SYSTEM_VARIABLES_ADMIN ON *.* TO '$MYSQL_USER'@'%';
      FLUSH PRIVILEGES;
    "
    ;;
  *)
    echo "Database version is $VERSION"
    echo "Skipping MySQL 8 grants."
    ;;
esac
