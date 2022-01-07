for i in $(grep ipv4 docker-compose.yml | cut -d ':' -f 2 | tr -d '[:blank:]')
do
	ssh -oStrictHostKeyChecking=no ansible@$i true
done
