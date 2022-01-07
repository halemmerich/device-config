docker exec -ti $(docker ps | grep "$1" | cut -d ' ' -f1) /bin/bash
