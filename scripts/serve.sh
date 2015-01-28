#!/usr/bin/env bash
echo "Args: 1[$1] 2[$2] 3[$3] 4[$4]"
vhost_conf="/etc/httpd/vhosts.d/$1.conf"
today=`date +%Y%m%d.%H%M%S`
vhost_backups="/etc/httpd/vhosts.d/backups/$today"
if [ -e $vhost_conf ]; then
  echo "vhost Config File for $1 exists - backing up"
  if [ ! -d "$vhost_backups" ]; then
    mkdir $vhost_backups
  fi
  mv $vhost_conf $vhost_backups
fi

if [ ! -z "$3" ]; then
    #phperr=$(php -r "echo $3;")
    php_options="# PHP Options, if any"$'\n'"    php_value error_reporting $3"
fi

if [ ! -z "$4" ]; then
  aliases="# Aliases, if any"
  IFS=':' read -a alias_array <<< $4
  for i in $alias_array; do
    alias_name=$(echo $i | cut -f1 -d,)
    alias_path=$(echo $i | cut -f2 -d,)
    aliases="$aliases"$'\n'"    Alias $alias_name  $alias_path"
  done
fi

block="<VirtualHost *:80>
    ServerName $1
    DocumentRoot $2

    $aliases

    $php_options

    ErrorLog /var/log/httpd/$1-default-error_log
    CustomLog /var/log/httpd/$1-default-access_log combined
    php_value error_log /var/log/httpd/phperrors
    HostnameLookups Off
    UseCanonicalName Off
    ServerSignature On
</VirtualHost>
"

echo "$block" > "$vhost_conf"
