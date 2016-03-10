CREATE DATABASE `identities`;

USE `identities`;

CREATE TABLE `identities` (
    `uid` VARCHAR(10) NOT NULL,
    PRIMARY KEY(`uid`),
    `password` VARCHAR(30) NOT NULL,
    `first_name` VARCHAR(30) NOT NULL,
    `last_name` VARCHAR(30) NOT NULL,
    `email` VARCHAR(30) NOT NULL
);

INSERT INTO `identities` VALUES ("jsmith", "password", "John", "Smith", "jsmith@vagrant.test");
INSERT INTO `identities` VALUES ("jbrown", "password", "Jane", "Brown", "jbrown@vagrant.test");
INSERT INTO `identities` VALUES ("jamesj", "password", "James", "Jones", "jamesj@vagrant.test");
