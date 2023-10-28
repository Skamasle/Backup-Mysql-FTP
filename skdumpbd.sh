#!/bin/bash
# Respaldamos todas las bases de datos del servidor, 
# Creamos un archivo con el log, 
# 
# v0.5 
# 21 de dic del 2014 | 0.5 2019
# fix 0.5 cpanel obtenemos la contraseña mas limpiamente 
# fix max_allowed_packet en mysqldump -- 14 feb 2023

backupin=/root/mysql_backup # Ruta para guardar los backup
logfile=/root/BackupLog.txt
expira=7 	# Número de días que se retienen los backups de MSYQL en local (archivos mayores a 2 días se borran antes del backup)
# Datos de mysql.
# Tipo de servidor.
# Detectamos el tipo de servidor, plesk, cpanel o ispconfig para obtener automaticamente la clave de la base de datos.
# Si el servidor no es plesk, cpanel o ispconfig dejamos como "normal" y definimos la clave en la parte de abajo en mypass.
#################
#################
servertype=plesk # Opciones: normal, cpanel, plesk, ipsconfig, directadmin
#################
#################
myuser="root"
mypass="pass" # Root Password
myhost="localhost"

if [ $servertype = plesk ]; then
	myuser="admin"	
	mypass=$(cat /etc/psa/.psa.shadow)
fi
if [ $servertype = cpanel ]; then
	#mypass=$(cat /root/.my.cnf |grep password | tr '"' ' ' | tr "'" " " | awk '{ print $2 }')
	mypass=$(cat /root/.my.cnf |grep password | tr '"' ' ' | tr "'" " " | awk -F "=" '{ print $2 }' | sed -e "s/ //g") 
fi
if [ $servertype = ispconfig ]; then
	mypass=$(cat /usr/local/ispconfig/server/lib/mysql_clientdb.conf |grep password | cut -d "'" -f2)
fi
if [ $servertype = directadmin ]; then
	myuser="da_admin"
	mypass=$(cat /usr/local/directadmin/conf/mysql.conf |grep passwd | cut -d "=" -f2)
fi

MKDIR=/bin/mkdir
TOUCH=/bin/touch
fecha=$(/bin/date)
if [ ! -d $backupin ]; then
	$MKDIR $backupin 
else
	find "$backupin" -type d -mtime +$expira | xargs rm -Rf
	
fi
if [ ! -e $logfile ]; then
	$TOUCH $logfile
fi
carpetabk=$backupin/$(date +%Y-%m-%d-h%H%M-%S)

if [ ! -d $carpetabk ]; then
	$MKDIR -p $carpetabk
fi
# no hace falta cambiarlo
lists=$(echo "show databases;" | mysql -h $myhost -u $myuser -p${mypass} | grep -v Database | grep -v information_schema | grep -v performance_schema | grep -v mysql)

echo "Comenzando el respaldo de las bases de datos" >> $logfile
tput setaf 1
tput bold
echo "Comenzando el respaldo de las bases de datos"
tput sgr0 
echo $fecha >> $logfile
C=0
for db in $lists
do
		tput setaf 2	
 	echo "Respaldo base de datos $db"
	mysqldump -h $myhost -u$myuser -p${mypass} --max_allowed_packet=256M --single-transaction --opt --events --routines --triggers $db > $carpetabk/$db.sql 2>${logfile}
	echo "Respaldando $db" >> $logfile
	tput setaf 3	
	echo "Comprimiendo base de datos --- $db"
	tput sgr0	
	sha256sum $carpetabk/$db.sql > $carpetabk/$db.sql.sha
	# gzip $carpetabk/$db.sql
	zstd --rm --no-progress $carpetabk/$db.sql
	let "C = $C + 1"
done
echo "Backup completo, se respaldaron $C Bases de Datos!" >> $logfile
echo $fecha >> $logfile
tput setaf 2
echo "Se respaldaron $C Bases de datos"
tput sgr0
