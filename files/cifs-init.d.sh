#!/bin/sh /etc/rc.common

START=99

ENABLED=0
MOUNTAREA=0
WORKGROUPD=0
IOCHARSET=0
DELAY=0
NOUNIX=""
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

#	echo "ENABLED:$ENABLED enabled:$enabled"

}

mount_natshare() {
	local server
	local name
	local natpath
	local guest
	local users
	local pwd
	local nounix
	local agm
	
	local _mount_path
	local _agm

	config_get server $1 server
	config_get name $1 name
	config_get natpath $1 natpath
	config_get guest $1 guest
	config_get users $1 users
	config_get pwd $1 pwd
	config_get nounix $1 nounix
	config_get agm $1 agm

	if [ $guest == 1 ]
	then 
	GUEST="guest,"
	USERS=""
#	echo "true-${name}-USERS:${USERS}-end"
#	echo "true-${name}-GUEST:${GUEST}-end"
	else if [ $guest == 0 ]
	then {
	if [ $users ]
	then
	USERS="username=$users,password=$pwd,"
	GUEST=""
#	echo "true-${name}-USERS:${USERS}-end"
	else
	USERS=""
	GUEST="guest,"
#	echo "false-${name}-USERS:${USERS}-end"
	fi
#	echo "false-${name}-GUEST:${GUEST}-end"
	}
	fi
	fi

	if [ $nounix != 1 ]
	then
	NOUNIX=""
#	echo "true-${name}-NOUNIX:${NOUNIX}-end"
	else
	NOUNIX=",nounix"
#	echo "false-${name}-NOUNIX:${NOUNIX}-end"
	fi
	
	if [ $agm ]
	then
	AGM=",$agm"
#	echo "true-${name}-AGM:${AGM}-end"
	else
	AGM=""
#	echo "false-${name}-AGM:${AGM}-end"
	fi

	append _mount_path "$MOUNTAREA/${server}-$name"
	append _agm "-o ${USERS}${GUEST}domain=$WORKGROUPD,iocharset=$IOCHARSET$NOUNIX$AGM"

#	echo "mkdir -p $_mount_path"
#	echo "mount -t cifs $natpath $_mount_path $_agm"
#	echo ""

	sleep 1
	mkdir -p $_mount_path
	mount -t cifs $natpath $_mount_path $_agm

}

umount_natshare() {
	local server
	local name
	local _mount_path

	config_get server $1 server
	config_get name $1 name

	append _mount_path "$MOUNTAREA/${server}-$name"
	
#	echo "$_mount_path -end"

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

	/etc/init.d/samba restart

	echo "Cifs Mount succeed."

		}
	else

	echo "Cifs Umount is Disabled.Please enter The Web Cotrol Center to enable it."

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
	echo "Umounting..."
	
	config_load cifs
	config_foreach cifs_header cifs

	/etc/init.d/samba stop

	config_foreach umount_natshare natshare

	echo "Cifs Umount succeed."

#	echo "ENABLED:$ENABLED enabled:$enabled"

	echo ""
	echo "Checking..."

	if [ $ENABLED == 1 ]
	then {

	echo "Cifs Mmount is Enabled."
	echo "Starting..."

	config_foreach mount_natshare natshare

	/etc/init.d/samba restart

	echo "Cifs Mount succeed."
		}
	else

	echo "Cifs Umount is Disabled.Please enter The Web Cotrol Center to enable it."

	fi
}