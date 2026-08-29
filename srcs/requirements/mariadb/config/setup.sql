-- update system databases
FLUSH PRIVILEGES;

-- give root user a password
ALTER USER `root`@`localhost` IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';

-- create wordpress database
CREATE DATABASE IF NOT EXISTS `${WORDPRESS_DB_NAME}`;
-- create the custom wordpress user, with the custom password and make it accessible from anywhere
CREATE USER IF NOT EXISTS `${WORDPRESS_DB_USER}`@`%` IDENTIFIED BY '${MARIADB_USER_PASSWORD}';

-- grant wordpress user all privileges for the wordpress database
GRANT ALL PRIVILEGES ON `${WORDPRESS_DB_NAME}`.* TO `${WORDPRESS_DB_USER}`@`%`;

-- update system databases
FLUSH PRIVILEGES;
