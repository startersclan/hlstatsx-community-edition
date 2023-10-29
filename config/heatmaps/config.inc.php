<?php
error_reporting(E_ALL);
ini_set("memory_limit", "32M");
ini_set("max_execution_time", "0");

define('DB_HOST',	'db');
define('DB_USER',	'hlstatsxce');
define('DB_PASS',	'hlstatsxce');
define('DB_NAME',	'hlstatsxce');
define('HLXCE_WEB',	'/web');
define('HUD_URL',	'http://www.hlxcommunity.com');
define('OUTPUT_SIZE',	'medium');

define('DB_PREFIX',	'hlstats');
define('KILL_LIMIT',	10000);
define('DEBUG', 1);

// No need to change this unless you are on really low disk.
define('CACHE_DIR',	dirname(__FILE__) . '/cache');

