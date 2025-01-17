#!/bin/bash
DOMAIN='vip.local'

if [ "" == "$1" ] || [ "" == "$2" ]
then
	echo 'syntax: db-import.sh <site-slug> <sql-file>'
	exit
fi

site_slug=$1
sql_file=$2

if [ ! -f "${sql_file}" ]; then
	echo "File not found: ${sql_file}"
	exit
fi

site_id=`/usr/bin/wp --path=/srv/www/wp site list --fields=blog_id,domain --format=csv|grep "${site_slug}.${DOMAIN}" | cut -d',' -f1`

if [ "" != "${site_id}" ]
then
	site_theme=`/usr/bin/wp --path=/srv/www/wp --url=${site_slug}.${DOMAIN} theme list --fields=name,status --format=csv | grep ',active' | cut -d',' -f1`
	echo "Importing ${sql_file} into ${site_slug} site id ${site_id}"
	sed -e "s/CREATE TABLE IF NOT EXISTS \`wp_/CREATE TABLE IF NOT EXISTS \`wp_${site_id}_/g" -e "s/ INTO \`wp_/ INTO \`wp_${site_id}_/g" -e "s/ TABLE \`wp_/ TABLE \`wp_${site_id}_/g" -e "s/table \`wp_/table \`wp_${site_id}_/g" -e "s/LOCK TABLES \`wp_/LOCK TABLES \`wp_${site_id}_/g" -e "s/DROP TABLE IF EXISTS \`wp_/DROP TABLE IF EXISTS \`wp_${site_id}_/g" ${sql_file} | mysql -uroot wordpress
	sudo service memcached restart
	/usr/bin/wp --path=/srv/www/wp pmc-site fix "${site_slug}.${DOMAIN}" --title="${site_slug}"
	sudo service memcached restart
	/usr/bin/wp --path=/srv/www/wp --url=${site_slug}.${DOMAIN} theme activate ${site_theme}
	sudo service memcached restart
else
	echo 'Wordpress Site not found'
fi

if [ "uls" = "${site_slug}" ]
then
	echo "Importing ${sql_file} into ${site_slug} db uls_wwd_local"
	mysql -uroot -e "drop database uls_wwd_local"
	mysql -uroot -e "create database uls_wwd_local"
	mysql -uroot uls_wwd_local < ${sql_file}
else
	echo 'ULS Site not found'
fi
