#!/bin/bash
##Prueba!!!
instances=-----INSTANCENUM-----
echo "[*] Starting $instances EvilnoVNC instances..."

for ((i=1; i<=$instances; i++)); do
	[ $i -lt 10 ] && i="0$i"
    ./run.sh $i >/dev/null 2>&1 &
    echo "[*] Instance $i started"
done

#jobs
sleep 5
docker ps -a
