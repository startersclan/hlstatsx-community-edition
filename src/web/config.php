<?php
/*
HLstatsX Community Edition - Real-time player and clan rankings and statistics
Copyleft (L) 2008-20XX Nicholas Hastings (nshastings@gmail.com)
http://www.hlxcommunity.com

HLstatsX Community Edition is a continuation of
ELstatsNEO - Real-time player and clan rankings and statistics
Copyleft (L) 2008-20XX Malte Bayer (steam@neo-soft.org)
http://ovrsized.neo-soft.org/

ELstatsNEO is an very improved & enhanced - so called Ultra-Humongus Edition of HLstatsX
HLstatsX - Real-time player and clan rankings and statistics for Half-Life 2
http://www.hlstatsx.com/
Copyright (C) 2005-2007 Tobias Oetzel (Tobi@hlstatsx.com)

HLstatsX is an enhanced version of HLstats made by Simon Garner
HLstats - Real-time player and clan rankings and statistics for Half-Life
http://sourceforge.net/projects/hlstats/
Copyright (C) 2001  Simon Garner

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

For support and installation notes visit http://www.hlxcommunity.com
*/

if (!defined("IN_HLSTATS")) {
	die("Do not access this file directly.");
}

function defineVar($name, $default) {
	$value = getenv($name) ? getenv($name) : $default;
	if (gettype($default) == 'array' && is_string($value)) {
		eval("\$value = $value;");
	}
	$value = gettype($default) == 'boolean' && $value == 'false' ? false : $value; // Fix string 'false' becoming true for boolean when using settype
	settype($value, gettype($default));
	define($name, $value);
}

// DB_ADDR - The address of the database server, in host:port format.
//           (You might also try setting this to e.g. ":/tmp/mysql.sock" to
//           use a Unix domain socket, if your mysqld is on the same box as
//           your web server.)
defineVar("DB_ADDR", 'localhost');

// DB_USER - The username to connect to the database as
defineVar("DB_USER", '');

// DB_PASS - The password for DB_USER
defineVar("DB_PASS", '');

// DB_NAME - The name of the database
defineVar("DB_NAME", '');

// DB_TYPE - The database server type. Only "mysql" is supported currently
defineVar("DB_TYPE", 'mysql');

// default 'utf8mb4'
defineVar("DB_CHARSET", 'utf8mb4');

// default 'utf8mb4_unicode_ci'
defineVar("DB_COLLATE", 'utf8mb4_unicode_ci');

// DB_PCONNECT - Set to 1 to use persistent database connections. Persistent
//               connections can give better performance, but may overload
//               the database server. Set to 0 to use non-persistent
//               connections.
defineVar("DB_PCONNECT", 0);

// INCLUDE_PATH - Filesystem path to the includes directory, relative to hlstats.php. This must be specified
//		as a relative path.
//
//                Under Windows, make sure you use forward slash (/) instead
//                of back slash (\) and use absolute paths if you are having any issue.
defineVar("INCLUDE_PATH", './includes');


// PAGE_PATH - Filesystem path to the pages directory, relative to hlstats.php. This must be specified
//		as a relative path.
//
//                Under Windows, make sure you use forward slash (/) instead
//                of back slash (\) and use absolute paths if you are having any issue.
defineVar("PAGE_PATH", './pages');


// PAGE_PATH - Filesystem path to the hlstatsimg directory, relative to hlstats.php. This must be specified
//		as a relative path.
//
//                Under Windows, make sure you use forward slash (/) instead
//                of back slash (\) and use absolute paths if you are having any issue.
//
// 		Note: the progress directory under hlstatsimg must be writable!!
defineVar("IMAGE_PATH", './hlstatsimg');

// MODES_RESTRICTED - Require logged-in access to certain pages. For more modes, see hlstats.php
// 80 - Restricted users and above
// 100 - Administrator access only
defineVar("MODES_RESTRICTED", [
	// 'chat' => 80,
	// 'chathistory' => 80,
	// 'search' => 80
]);

// How often dynamicly generated images are updated (in seconds)
defineVar("IMAGE_UPDATE_INTERVAL", 300);

defineVar('GOOGLE_MAPS_API_KEY', "");

defineVar("DB_DEBUG", false);

?>
