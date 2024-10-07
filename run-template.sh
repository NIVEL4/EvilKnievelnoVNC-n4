#!/bin/bash
# build and run EvilKnievelnoVNC after setup via setup.sh
shell=/bin/bash
url="---tUrl---"
instances=---inst---

###############################################################
## BUILD & RUN

# build & run controller
echo "[*] Starting controller..."
cd controller && $shell run.sh &
sleep 15

# build & run haproxy/backend
# there needs to be another server container running, else haproxy would fail starting up...
echo "[*] Starting haproxy..."
cd ../haproxy && $shell run.sh &
sleep 15

# build & run EvilnoVNC instances
echo "[*] Starting $instances EvilnoVNC instances..."
cd ../EvilnoVNC

for ((i=1; i<=$instances; i++)); do
        [ $i -lt 10 ] && i="0$i"

	$shell run.sh "$url" $i &

	echo "[*] Instance $i started"
	sleep 15
done

cd ..
echo "[*] EvilnoVNC instances started, pointing to $url"

#jobs
docker ps -a

