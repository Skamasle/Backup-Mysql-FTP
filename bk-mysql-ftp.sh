#!/bin/bash
bk_host=host
bk_ftp_user=
bk_ftp_pass=
bk_ftp_port=21
bk_ftp_path=/backup
log=~/tmp/bk.log
DATE=$(date)
# Mysql Connect
# We wait .my.cnf for connection this do it compatible whit any system easy
# More secure and not need your password here
if [ ! -d ~/tmp ];then
mkdir ~/tmp
fi
cd ~/tmp
databases=$(echo "show databases;" | mysql |grep -v performance_schema |grep -v information_schema |grep -v Database)
for bd in $databases
do
DATE=$(date)
echo "Respaldando $bd -- $DATE" >> $log
mysqldump $bd > $bd.sql || rm -f $bd.sql
if [ -e $bd.sql ];then
echo "Comprimiendo $bd" >> $log
gzip $bd.sql
echo "Transfiriendo $bd" >> $log
/usr/bin/lftp -c "open -u $bk_ftp_user,$bk_ftp_pass ftp://$bk_host -p $bk_ftp_port; put -O $bk_ftp_path $bd.sql.gz " >> log
rm -f $bd.sql.gz
else
echo "BD $bd no se a podido respaldar -- $DATE " >> ~/MYSQLDUMP-ERROR.log
echo "Error al Respaldar $bd" >> $log
fi
done
exit 0



