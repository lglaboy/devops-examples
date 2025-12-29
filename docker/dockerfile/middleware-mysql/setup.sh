#!/bin/bash

echo 'checking mysql status.'
service mysql status

echo '1.start mysql....'
service mysql start
sleep 10
service mysql status

echo '2.start changing password....'
mysql < /mysql/privileges.sql
echo '3.end changing password....'

sleep 3
service mysql status

echo '4.start importing data....'
mysql < /mysql/schema.sql
mysql < /mysql/nacos-init.sql
echo '5.end importing data....'

sleep 3
service mysql status
echo 'mysql is ready'

tail -f /dev/null