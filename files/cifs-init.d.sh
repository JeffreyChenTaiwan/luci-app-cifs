#!/bin/sh /etc/rc.common

START=99

ENABLED=0
MOUNTAREA=0
WORKGROUPD=0
IOCHARSET=0
DELAY=0
GUEST=""
USERS=""
AGM=""

cifs_header() {
	local enabled
	local workgroup 
	local mountarea
	local delay
	local iocharset

	config_get enabled $1 enabled
	config_get mountarea $1 mountarea
	config_get workgroup $1 workgroup
	config_get delay $1 delay
	config_get iocharset $1 iocharset

	ENABLED=$enabled
	MOUNTAREA=$mountarea
	WORKGROUPD=$workgroup
	IOCHARSET=$iocharset

	if [ $delay != 0 ]	
	then
	DELAY=$delay
	fi
}

mount_natshare() {
	local server
	local name
	local natpath
	local guest
	local users
	local pwd
	local agm
	local smbver
	
	local _mount_path
	local _agm

	config_get server $1 server
	config_get name $1 name
	config_get natpath $1 natpath
	config_get guest $1 guest
	config_get users $1 users
	config_get pwd $1 pwd
	config_get agm $1 agm
	config_get smbver $1 smbver

	if [ "$guest" == 1 ]
	then 
		GUEST="guest,"
		USERS=""
		else if [ "$guest" == 0 ]
		then {
			if [ "$users" ]
			then
				USERS="username=\"$users\",password=\"$pwd\","
				GUEST=""
			else
				USERS=""
				GUEST="guest,"
			fi
			}
		fi
	fi
	
	if [ $agm ]
	then
		AGM=",$agm"
	else
		AGM=""
	fi

	append _mount_path "$MOUNTAREA/${server}-$name"
	#windows 7 use vers 1.0, win10 need 2.0
	append _agm "${USERS}${GUEST}domain=$WORKGROUPD,iocharset=$IOCHARSET$AGM,vers=$smbver"
	
	sleep 1
	mkdir -p $_mount_path
	mount -t cifs $natpath $_mount_path -o "$_agm"
}

umount_natshare() {
	local server
	local name
	local _mount_path

	config_get server $1 server
	config_get name $1 name

	append _mount_path "$MOUNTAREA/${server}-$name"

	sleep 1
	umount -d -l $_mount_path
	rm -r -f $_mount_path 
}

change_natshare() {
	sleep 1
}

start() {
	config_load cifs
	config_foreach cifs_header cifs

	echo "Checking..."

	if [ $ENABLED == 1 ]
	then {
		echo "Cifs Mount is Enabled."
		echo "Starting..."
		if [ $DELAY != 0 ]
		then
			sleep $DELAY
			echo "DELAY Operation ${DELAY}s"
		else
			echo "Not DELAY ${DELAY}s"
		fi

		config_foreach mount_natshare natshare
		/etc/init.d/samba4 restart

		echo "Cifs Mount succeed."
		}
	else
		echo "Cifs Mount is Disabled.Please enter The Web Cotrol Center to enable it."
	fi
}

stop() {
	echo "Umounting..."

	config_load cifs
	config_foreach cifs_header cifs
	config_foreach umount_natshare natshare

	echo "Cifs Umount succeed."

}

restart() {
	echo 'Umounting... '
	
	config_load cifs
	config_foreach cifs_header cifs

	/etc/init.d/samba4 stop

	config_foreach umount_natshare natshare

	echo "Cifs Umount succeed."

	echo ''
	echo 'Checking... '

	if [ $ENABLED == 1 ]
	then {
		echo 'Cifs Mmount is Enabled. '
		echo 'Starting... '

		config_foreach mount_natshare natshare
		/etc/init.d/samba4 restart

		echo "Cifs Mount succeed."
		}
	else
		/etc/init.d/cifs disable
		echo "Cifs Mount is Disabled.Please enter The Web Cotrol Center to enable it."
	fi
}
