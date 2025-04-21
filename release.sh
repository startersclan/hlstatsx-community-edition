#!/bin/sh
# This script makes it easy to create a new release.
# It requires git, which is only used to detect the previous tag.

set -eu

TAG=${1:-}
COMMENT=${2:-}
if [ -z "$TAG" ]; then
    echo "Please specify a tag as a first argument. E.g. v1.2.3"
    exit 1
fi
TAG_REGEX='^v?[0-9]+\.[0-9]+\.[0-9]+$'
if ! echo "$TAG" | grep -E "$TAG_REGEX" > /dev/null; then
    echo "Tag does not match regex: $TAG_REGEX"
    exit 1
fi
TAG_PREV=$( git --no-pager tag -l --sort=-version:refname | head -n1 )
if ! echo "$TAG_PREV" | grep -E "$TAG_REGEX" > /dev/null; then
    echo "Previous git tag is invalid. It does not match regex: $TAG_REGEX"
    exit 1
fi

VERSION=$( echo "$TAG" | sed 's/^v//' )
VERSION_PREV=$( echo "$TAG_PREV" | sed 's/^v//' )
VERSION_PREV_REGEX=$( echo "$VERSION_PREV" | sed 's/\./\\./g' ) # '1.0.0' -> '1\.0\.0'
DBVERSION_PREV=$( ls src/web/updater | grep -E '^[0-9]+\.php$' | sort -n | tail -n1 | cut -d '.' -f1 )
DBVERSION=$(( $DBVERSION_PREV + 1 ))

# Bump version in docs, .php, and .sql files
sed -i "s/$VERSION_PREV/$VERSION/" README.md
sed -i "s/$VERSION_PREV/$VERSION/" docker-compose.example.yml
sed -i "s/^SET @DBVERSION=.*/SET @DBVERSION=\"$DBVERSION\";/" src/sql/install.sql
sed -i "s/^SET @VERSION=.*/SET @VERSION=\"$VERSION\";/" src/sql/install.sql
echo "Creating src/web/updater/$DBVERSION.php"
cat - > src/web/updater/$DBVERSION.php <<EOF
<?php
    if ( !defined('IN_UPDATER') )
    {
        die('Do not access this file directly.');
    }

    \$dbversion = $DBVERSION;
    \$version = "$VERSION";

    // Perform database schema update notification
    print "Updating database and version schema numbers.<br />";
    \$db->query("UPDATE hlstats_Options SET \`value\` = '\$version' WHERE \`keyname\` = 'version'");
    \$db->query("UPDATE hlstats_Options SET \`value\` = '\$dbversion' WHERE \`keyname\` = 'dbversion'");
?>
EOF

echo "Done bumping version to $TAG in all files"
