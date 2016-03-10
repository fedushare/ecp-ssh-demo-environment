CREATE DATABASE `accounts`;

USE `accounts`;

CREATE TABLE `accounts` (
    `eppn` VARCHAR(30) NOT NULL,
    PRIMARY KEY(`eppn`),
    `local_account` VARCHAR(30) NOT NULL
);

INSERT INTO `accounts` VALUES ("jsmith@vagrant.test", "user1");
INSERT INTO `accounts` VALUES ("jbrown@vagrant.test", "user2");
INSERT INTO `accounts` VALUES ("jamesj@vagrant.test", "user3");
