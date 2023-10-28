## HLstatsX : Community Edition


HLstatsX Community Edition is an open-source project licensed
under GNU General Public License v2 and is a real-time stats
and ranking for Source engine based games. HLstatsX Community
Edition uses a Perl daemon to parse the log streamed from the
game server. The data is stored in a MySQL Database and has
a PHP frontend.


#### :loudspeaker: Important changes
| Date  | Description | Additional information |
| ------------- | ------------- | ------------- |
| 07.01.2020  | [#45](https://github.com/NomisCZ/hlstatsx-community-edition/issues/45) GeoIP2 Linux script updated, GeoLite2 MaxMind database (GDPR and CCPA) | https://blog.maxmind.com/2019/12/18/significant-changes-to-accessing-and-using-geolite2-databases/ |

> Date format: DD.MM.YYYY
---

### :book: Documentation
* https://github.com/NomisCZ/hlstatsx-community-edition/wiki 🚧 Wiki - work in progress 🚧
### :speech_balloon: Help
*  https://forums.alliedmods.net/forumdisplay.php?f=156
---

## Development

```sh
# 1. Start Counter-strike 1.6 server, source-udp-forwarder, HLStatsX:CE stack
docker-compose up
# HLStatsX:CE web frontend available at http://localhost:8081/. Admin Panel username: admin, password 123456
# phpmyadmin available at http://localhost:8083. Root username: root, root password: root. Username: hlstatsxce, password: hlstatsxce

# Development - Install vscode extensions
# Once installed, set breakpoints in code, and press F5 to start debugging.
code --install-extension bmewburn.vscode-intelephense-client # PHP intellisense
code --install-extension xdebug.php-debug # PHP remote debugging via xdebug
code --install-extension ms-python.python # Python intellisense
# If xdebug is not working, iptables INPUT chain may be set to DROP on the docker bridge.
# Execute this to allow php to reach the host machine via the docker0 bridge
sudo iptables -A INPUT -i br+ -j ACCEPT

# CS 1.6 server - Restart server
docker-compose restart cstrike
# CS 1.6 server - Attach to the CS 1.6 server console
docker attach $( docker-compose ps -q cstrike )
# CS 1.6 server - Exec into container
docker exec -it $( docker-compose ps -q cstrike) bash

# asp-php - Exec into container
docker exec -it $( docker-compose ps -q web-php ) sh

# Test production builds locally
docker build -t startersclan/hlstatsx-community-edition:daemon -f Dockerfile.daemon .
docker build -t startersclan/hlstatsx-community-edition:web-nginx -f Dockerfile.web-nginx .
docker build -t startersclan/hlstatsx-community-edition:web-php -f Dockerfile.web-php .

# Dump the DB
docker exec $( docker-compose ps -q db ) mysqldump -uroot -proot hlstatsxce | gzip > hlstatsxce.sql.gz

# Restore the DB
zcat hlstatsxce.sql.gz | docker exec -i $( docker-compose ps -q db ) mysql -uroot -proot hlstatsxce

# Stop Counter-strike 1.6 server, source-udp-forwarder, HLStatsX:CE stack
docker-compose down

# Cleanup
docker-compose down
docker volume rm hlstatsx-community-edition_dns-volume
docker volume rm hlstatsx-community-edition_db-volume
```
