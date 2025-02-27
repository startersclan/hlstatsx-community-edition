#!/bin/sh
set -eu

echo "[test-routes]"
echo "Testing anonymous routes..."
command -v curl || apk add --no-cache curl
URLS="
http://web/ 302
http://web/css/spinner.gif 200
http://web/hlstatsimg/ajax.gif 200
http://web/includes/ 401
http://web/pages/ 401
http://web/pages/.htaccess 401
http://web/styles/classic.css 200
http://web/updater/ 401
http://web/autocomplete.php 200
http://web/config.php 401
http://web/hlstats.php 200
http://web/hlstats.php?mode=contents 200
http://web/hlstats.php?game=tf 200
http://web/hlstats.php?mode=actioninfo&action=headshot&game=tf 200
http://web/hlstats.php?mode=actions&game=tf 200
http://web/hlstats.php?mode=admin 200
http://web/hlstats.php?mode=awards&game=tf 200
http://web/hlstats.php?mode=awards&game=tf&tab=ranks&type=ajax 200
http://web/hlstats.php?mode=awards&game=tf&tab=daily&type=ajax 200
http://web/hlstats.php?mode=awards&game=tf&tab=global&type=ajax 200
http://web/hlstats.php?mode=awards&game=tf&tab=ranks&type=ajax 200
http://web/hlstats.php?mode=awards&game=tf&tab=ribbons&type=ajax 200
http://web/hlstats.php?mode=bans&game=tf 200
http://web/hlstats.php?mode=chat&game=tf 200
http://web/hlstats.php?mode=chathistory&player=1 200
http://web/hlstats.php?mode=claninfo&clan=1 200
http://web/hlstats.php?mode=claninfo&clan=1&tab=actions&type=ajax 200
http://web/hlstats.php?mode=claninfo&clan=1&tab=general&type=ajax 200
http://web/hlstats.php?mode=claninfo&clan=1&tab=mapperformance&type=ajax 200
http://web/hlstats.php?mode=claninfo&clan=1&tab=teams&type=ajax 200
http://web/hlstats.php?mode=claninfo&clan=1&tab=weapons&type=ajax 200
http://web/hlstats.php?mode=clans&game=tf 200
http://web/hlstats.php?mode=contents 200
http://web/hlstats.php?mode=countryclansinfo&flag=SG&game=tf 200
http://web/hlstats.php?mode=countryclans&game=tf 200
http://web/hlstats.php?mode=dailyawardinfo&award=63&game=tf 200
http://web/hlstats.php?mode=mapinfo&game=tf&map=cp_well 200
http://web/hlstats.php?mode=maps&game=tf 200
http://web/hlstats.php?mode=playerawards&player=1 200
http://web/hlstats.php?mode=playerhistory&player=1 200
http://web/hlstats.php?mode=playerinfo&player=1 200
http://web/hlstats.php?mode=playerinfo&player=1&tab=aliases&type=ajax 200
http://web/hlstats.php?mode=playerinfo&player=1&tab=general&type=ajax 200
http://web/hlstats.php?mode=playerinfo&player=1&tab=killstats&type=ajax 200
http://web/hlstats.php?mode=playerinfo&player=1&tab=mapperformance&type=ajax 200
http://web/hlstats.php?mode=playerinfo&player=1&tab=playeractions&type=ajax 200
http://web/hlstats.php?mode=playerinfo&player=1&tab=servers&type=ajax 200
http://web/hlstats.php?mode=playerinfo&player=1&tab=teams&type=ajax 200
http://web/hlstats.php?mode=playerinfo&player=1&tab=weapons&type=ajax 200
http://web/hlstats.php?mode=playersessions&player=1 200
http://web/hlstats.php?mode=players&game=tf 200
http://web/hlstats.php?mode=rankinfo&rank=1&game=tf 200
http://web/hlstats.php?mode=ribboninfo&ribbon=1&game=tf 200
http://web/hlstats.php?mode=roles&game=tf 200
http://web/hlstats.php?mode=rolesinfo&role=Engineer&game=tf 200
http://web/hlstats.php?mode=search 200
http://web/hlstats.php?mode=servers&server_id=1 200
http://web/hlstats.php?mode=teamspeak&tsId=1 200
http://web/hlstats.php?mode=updater&task=tools_updater 200
http://web/hlstats.php?mode=ventrilo&game=tf&veId=1 200
http://web/hlstats.php?mode=weaponinfo&weapon=tf_projectile_rocket&game=tf 200
http://web/hlstats.php?mode=weapons&game=tf 200
http://web/ingame.php?mode=accuracy&player=1&game=tf 200
http://web/ingame.php?mode=actions&player=1&game=tf 200
http://web/ingame.php?mode=actioninfo&action=1&game=tf 200
http://web/ingame.php?mode=bans&game=tf 200
http://web/ingame.php?mode=claninfo&clan=1&game=tf 200
http://web/ingame.php?mode=clans&game=tf 200
http://web/ingame.php?mode=help&game=tf 200
http://web/ingame.php?mode=kills&player=1&game=tf 200
http://web/ingame.php?mode=load&server_id=1&game=tf 200
http://web/ingame.php?mode=mapinfo&map=cp_well&game=tf 200
http://web/ingame.php?mode=maps&player=1&game=tf 200
http://web/ingame.php?mode=motd 200
http://web/ingame.php?mode=players&game=tf 200
http://web/ingame.php?mode=servers&game=tf 200
http://web/ingame.php?mode=statsme&player=1&game=tf 200
http://web/ingame.php?mode=status&server_id=1&game=tf 200
http://web/ingame.php?mode=targets&player=1&game=tf 200
http://web/ingame.php?mode=weapons&player=1&game=tf 200
http://web/ingame.php?mode=weaponinfo&weapon=tf_projectile_rocket&game=tf 200
http://web/index.php 302
http://web/ingame.php 200
http://web/show_graph.php 200
http://web/sig.php 200
http://web/status.php 200
http://web/trend_graph.php 200
"
echo "$URLS" | awk NF | while read -r i j; do
    if wget -q -SO- "$i" 2>&1 | grep "HTTP/1.1 $j " > /dev/null; then
        echo "PASS: $i"
    else
        echo "FAIL: $i"
        exit 1
    fi
done

echo "Testing admin routes..."
URLS_ADMIN="
http://web/hlstats.php?mode=admin 200
http://web/hlstats.php?mode=admin&task=options 200
http://web/hlstats.php?mode=admin&task=adminusers 200
http://web/hlstats.php?mode=admin&task=games 200
http://web/hlstats.php?mode=admin&task=hostgroups 200
http://web/hlstats.php?mode=admin&task=clantags 200
http://web/hlstats.php?mode=admin&task=voicecomm 200
http://web/hlstats.php?mode=admin&game=tf 200
http://web/hlstats.php?mode=admin&game=tf&task=newserver 200
http://web/hlstats.php?mode=admin&game=tf&task=servers 200
http://web/hlstats.php?mode=admin&game=tf&task=actions 200
http://web/hlstats.php?mode=admin&game=tf&task=teams 200
http://web/hlstats.php?mode=admin&game=tf&task=roles 200
http://web/hlstats.php?mode=admin&game=tf&task=weapons 200
http://web/hlstats.php?mode=admin&game=tf&task=awards_weapons 200
http://web/hlstats.php?mode=admin&game=tf&task=awards_plyractions 200
http://web/hlstats.php?mode=admin&game=tf&task=awards_plyrplyractions 200
http://web/hlstats.php?mode=admin&game=tf&task=awards_plyrplyractions_victim 200
http://web/hlstats.php?mode=admin&game=tf&task=ranks 200
http://web/hlstats.php?mode=admin&game=tf&task=ribbons 200
http://web/hlstats.php?mode=admin&task=tools_adminevents 200
http://web/hlstats.php?mode=admin&task=tools_editdetails 200
http://web/hlstats.php?mode=admin&task=tools_editdetails_clan 200
http://web/hlstats.php?mode=admin&task=tools_editdetails_player 200
http://web/hlstats.php?mode=admin&task=tools_ipstats 200
http://web/hlstats.php?mode=admin&task=tools_optimize 200
http://web/hlstats.php?mode=admin&task=tools_perlcontrol 200
http://web/hlstats.php?mode=admin&task=tools_reset 200
http://web/hlstats.php?mode=admin&task=tools_reset_2 200
http://web/hlstats.php?mode=admin&task=tools_resetdbcollations 200
http://web/hlstats.php?mode=admin&task=tools_settings_copy 200
http://web/hlstats.php?mode=admin&task=tools_synchronize 200
"
COOKIE=$( curl -X POST -vkL -H "Content-Type: application/x-www-form-urlencoded" -d 'authusername=admin&authpassword=123456' http://web/hlstats.php?mode=admin -o/dev/null 2>&1 | grep -i set-cookie | awk '{print $3}' )
echo "Cookie: $COOKIE"
echo "$URLS_ADMIN" | awk NF | while read -r i j; do
    if curl -vkL -H "Content-Type: application/x-www-form-urlencoded" -H "Cookie: $COOKIE" "$i" 2>&1 | grep "HTTP/1.1 $j " > /dev/null; then
        echo "PASS: $i"
    else
        echo "FAIL: $i"
        exit 1
    fi
done
