-- update system databases
FLUSH PRIVILEGES;

-- give root user a password
ALTER USER `root`@`localhost` IDENTIFIED BY '${DB_ROOT_PASSWORD}';

-- create wordpress database
CREATE DATABASE IF NOT EXISTS `${DB_NAME}`;
-- create the custom wordpress user, with the custom password and make it accessible from anywhere
CREATE USER IF NOT EXISTS `${DB_USER}`@`%` IDENTIFIED BY '${DB_PASSWORD}';

-- grant wordpress user all privileges for the wordpress database
GRANT ALL PRIVILEGES ON `${DB_NAME}`.* TO `${DB_USER}`@`%`;

-- update system databases
FLUSH PRIVILEGES;
