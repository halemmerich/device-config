#!/bin/bash
KEY_SOURCE=/root/.ssh/id_rsa.pub

if [ -f "staging.conf" ]
then
	. staging.conf
fi

if [ -n "$1" ]
then
	KEY_SOURCE="/home/$1/.ssh/id_rsa.pub"
fi

docker-compose up -d
sleep 5

echo
echo

RC=0;


NAMESERVERS=$(yq -r '.services | to_entries[] | select(.key | contains("dns")) | [ .value.networks.staging_net.ipv4_address ] | join(" ")' docker-compose.yml | sed 's/^/nameserver /')

TEMPLOG=$(mktemp)

mkdir -p keys
[ -f keys/ssh_host_rsa_key ] || ssh-keygen -N '' -t rsa -f keys/ssh_host_rsa_key

for C in $(docker-compose ps -q)
do
	NAME=$(docker container inspect $C | grep Name | head -n 1 | cut -d '"' -f 4)
	echo Handling $NAME
	
	docker exec -ti $C bash -c "umount /etc/hosts" >> $TEMPLOG
	CRC=$?; [ $CRC -ne 0 ] && (( RC++ ))
	echo - Disabled /etc/hosts mount with RC $CRC | tee -a $TEMPLOG
	echo > $TEMPLOG
	
	if echo "$NAME" | grep -q arch
	then
		docker exec -ti $C bash -c "pacman-key --init" >> $TEMPLOG
		CRC=$?; [ $CRC -ne 0 ] && (( RC++ ))
		echo - Generated pacman key with RC $CRC | tee -a $TEMPLOG
		echo > $TEMPLOG
	fi
	
	docker exec -ti $C bash -c "rm /etc/ssh/ssh_host_*_key*" >> $TEMPLOG
	CRC=$?; [ $CRC -ne 0 ] && (( RC++ ))
	echo - Remove existing host keys with RC $CRC | tee -a $TEMPLOG
	echo > $TEMPLOG
	
	docker cp keys/ssh_host_rsa_key $C:/etc/ssh/ssh_host_rsa_key >> $TEMPLOG
	CRC=$?; [ $CRC -ne 0 ] && (( RC++ ))
	echo - Set rsa host private key with RC $CRC | tee -a $TEMPLOG
	echo > $TEMPLOG
	
	docker cp keys/ssh_host_rsa_key.pub $C:/etc/ssh/ssh_host_rsa_key.pub >> $TEMPLOG
	CRC=$?; [ $CRC -ne 0 ] && (( RC++ ))
	echo - Set rsa host public key with RC $CRC | tee -a $TEMPLOG
	echo > $TEMPLOG
	
	docker exec -ti $C bash -c "echo $(cat "$KEY_SOURCE") > /home/ansible/.ssh/authorized_keys" >> $TEMPLOG
	CRC=$?; [ $CRC -ne 0 ] && (( RC++ ))
	echo - Set authorized keys with RC $CRC | tee -a $TEMPLOG
	echo > $TEMPLOG
	
	if echo "$NAME" | grep -q -v dns
	then
		
		docker exec -ti $C bash -c "echo -e \"$NAMESERVERS\" > /etc/resolv.conf" >> $TEMPLOG
		CRC=$?; [ $CRC -ne 0 ] && (( RC++ ))
		echo - Set /etc/resolv.conf with RC $CRC | tee -a $TEMPLOG
		echo > $TEMPLOG
	fi
done

echo
[ $RC -ne 0 ] && cat $TEMPLOG
rm $TEMPLOG

[ $RC -ne 0 ] && echo Overall failure count is $RC
exit $RC
