
         DROP TABLE IF EXISTS `geoLiteCity_Blocks`;
         DROP TABLE IF EXISTS `geolitecity_blocks`;
         DROP TABLE IF EXISTS `geolitecity_location`;
         DROP TABLE IF EXISTS `geoLiteCity_Location`;

         CREATE TABLE `geoLiteCity_Blocks` 
         (`startIpNum` bigint(11) unsigned NOT NULL default '0',
         `endIpNum` bigint(11) unsigned NOT NULL default '0',
         `locId` bigint(11) unsigned NOT NULL default '0'
         ) ENGINE=MyISAM DEFAULT CHARSET=utf8;

         CREATE TABLE `geoLiteCity_Location` (
         `locId` bigint(11) unsigned NOT NULL default '0',
         `country` varchar(2) NOT NULL,
         `region` varchar(50) default NULL,
         `city` varchar(50) default NULL,
         `postalCode` varchar(10) default NULL,
         `latitude` decimal(14,4) default NULL,
         `longitude` decimal(14,4) default NULL,
         PRIMARY KEY  (`locId`)
         ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
