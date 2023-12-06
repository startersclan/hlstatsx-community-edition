<?php
    if ( !defined('IN_UPDATER') )
    {
        die('Do not access this file directly.');
    }

    echo "Adding support for Counter-Strike 2<br />";

    //
    // Add support for Counter-Strike 2
    //
    $db->query("
        INSERT INTO `hlstats_Games` (`code`, `name`, `realgame`, `hidden`) VALUES
            ('cs2', 'Counter-Strike 2', 'cs2', '1');
    ");
    $db->query("
        INSERT INTO `hlstats_Games_Supported` VALUES ('cs2', 'Counter-Strike 2'); 
    ");
    // Copy from CS:GO
    $db->query("
        INSERT INTO `hlstats_Games_Defaults` (`code`, `parameter`, `value`) 
        SELECT 'cs2', parameter, value FROM `hlstats_Games_Defaults` WHERE code = 'csgo';
    ");
    $db->query("
        INSERT INTO `hlstats_Actions`(`game`, `code`, `reward_player`, `reward_team`, `team`, `description`, `for_PlayerActions`, `for_PlayerPlayerActions`, `for_TeamActions`, `for_WorldActions`)
        SELECT 'cs2', code, reward_player, reward_team, team, description, for_PlayerActions, for_PlayerPlayerActions, for_TeamActions, for_WorldActions FROM hlstats_Actions WHERE game='csgo';
    ");
    $db->query("
        INSERT INTO hlstats_Awards (game, awardType, code, name, verb)
        SELECT 'cs2', awardType, code, name, verb FROM hlstats_Awards WHERE game='csgo';
    ");
    $db->query("
        INSERT INTO hlstats_Ribbons (game, awardCode, awardCount, special, image, ribbonName)
        SELECT 'cs2', awardCode, awardCount, special, image, ribbonName FROM hlstats_Ribbons WHERE game='csgo';
    ");
    $db->query("
        INSERT INTO hlstats_Ranks (game, image, minKills, maxKills, rankName)
        SELECT 'cs2', image, minKills, maxKills, rankName FROM hlstats_Ranks WHERE game='csgo';
    ");
    $db->query("
        INSERT INTO hlstats_Teams (game, code, name, hidden, playerlist_bgcolor, playerlist_color, playerlist_index)
        SELECT 'cs2', code, name, hidden, playerlist_bgcolor, playerlist_color, playerlist_index FROM hlstats_Teams WHERE game='csgo';
    ");
    $db->query("
        INSERT INTO hlstats_Weapons (game, code, name, modifier)
        SELECT 'cs2', code, name, modifier FROM hlstats_Weapons WHERE game='csgo';
    ");

    echo "Done.<br />";

    $dbversion = 84;
    $version = "1.11.0";

    // Perform database schema update notification
    print "Updating database and verion schema numbers.<br />";
    $db->query("UPDATE hlstats_Options SET `value` = '$version' WHERE `keyname` = 'version'");
    $db->query("UPDATE hlstats_Options SET `value` = '$dbversion' WHERE `keyname` = 'dbversion'");

?>
