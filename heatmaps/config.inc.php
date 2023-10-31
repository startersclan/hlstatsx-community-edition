<?php
function iniSet($name, $default) {
	$value = getenv($name) ? getenv($name) : $default;
	ini_set($name, $value);
}
function defineVar($name, $default) {
	$value = getenv($name) ? getenv($name) : $default;
	$value = gettype($default) == 'boolean' && $value == 'false' ? false : $value; // Fix string 'false' becoming true for boolean when using settype
	settype($value, gettype($default));
	define($name, $value);
}

error_reporting(E_ALL);
iniSet("memory_limit", "32M");
iniSet("max_execution_time", "0");

defineVar('DB_HOST',	'localhost');
defineVar('DB_USER',	'');
defineVar('DB_PASS',	'');
defineVar('DB_NAME',	'');
defineVar('HLXCE_WEB',	'/path/to/where/you/have/your/hlstats/web');
defineVar('HUD_URL',	'http://www.hlxcommunity.com');
defineVar('OUTPUT_SIZE',	'medium');

defineVar('DB_PREFIX',	'hlstats');
defineVar('KILL_LIMIT',	10000);
defineVar('DEBUG', 1);

// No need to change this unless you are on really low disk.
defineVar('CACHE_DIR',	dirname(__FILE__) . '/cache');

