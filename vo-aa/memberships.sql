CREATE DATABASE `memberships`;

USE `memberships`;

CREATE TABLE `vo_memberships` (
    `eppn` VARCHAR(30) NOT NULL,
    `vo_name` VARCHAR(30) NOT NULL,
    PRIMARY KEY(`eppn`, `vo_name`)
);

INSERT INTO `vo_memberships` VALUES ("jsmith@vagrant.test", "AllowedUsers");
INSERT INTO `vo_memberships` VALUES ("jsmith@vagrant.test", "AnotherGroup");
INSERT INTO `vo_memberships` VALUES ("jbrown@vagrant.test", "AllowedUsers");
INSERT INTO `vo_memberships` VALUES ("jamesj@vagrant.test", "GroupTwo");
