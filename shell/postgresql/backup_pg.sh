#!/bin/bash

# crontab
# sudo vim /usr/local/bin/pg-backup
# sudo chmod 744 /usr/local/bin/pg-backup
# sudo crontab -e
# 0 0 * * * /usr/local/bin/pg-backup > /root/pg-backup.log 2>&1


rm -rf /data/pg_backup/pg_data_backup_*.tar.gz

cd /

tar -czvf /data/pg_backup/"pg_data_backup_$(date +%Y-%m-%d-%s)_full.tar.gz" data/ssd data/swdb var/lib/postgresql/11/main etc/postgresql/11/main

scp /data/pg_backup/pg_data_backup*.tar.gz root@XXYY-APP-001:/data/pg_backup/pg_data_backup_full.tar.gz