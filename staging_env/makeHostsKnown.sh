#!/bin/bash

COMPOSE=docker-compose.yml
[ ! -f "$COMPOSE" ] && cd staging_env

for C in $(cat "$COMPOSE" | yq '.["services"][]["networks"]["staging_net"]["ipv4_address"]' | grep -v null | sed -s "s|\"||g")
do
	sed -i -e "/$C/d" ~/.ssh/known_hosts
	ssh-keyscan "$C" | grep -v "#" >> ~/.ssh/known_hosts
#	echo "$C $(cat keys/ssh_host_rsa_key.pub | cut -d ' ' -f -2)" >> ~/.ssh/known_hosts
done
