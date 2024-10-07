#!/bin/bash
usage () {
	echo "Usage:"
	echo -e "\t configure and run setup.sh"
	echo -e "\t $0 <instances>"
	echo -e "\t e.g. $0 3"
}

# check screen dependency
command -v screen || (echo "[!] Missing dependency: screen" ; exit 1)

# arguments given?
[ $# -lt 1 ] && (echo "[!] Missing argument"; usage; exit 1)
instances=$2
tUrl=$1

# 1. run controller in screen session
echo "[*] Starting controller in screen session..."
screen -S controller -dm sh -c 'cd controller; bash run.sh'
sleep 10

# 2. run haproxy in screen session
echo "[*] Starting haproxy in screen session..."
screen -S haproxy -dm sh -c 'cd haproxy; bash run.sh'
sleep 10

# 3. run EvilnoVNC instances in screen session
cd EvilnoVNC
docker build --rm -t evilnovnc .

for x in $instances; do
	[ $x -lt 10 ] && x="0$x"
	echo "[*] Starting EvilnoVNC instance $x in screen session..."
	screen -S evil$x -dm sh -c "bash run.sh $x"
	sleep 10
done

echo "[*] Check state with screen -ls, reattach with screen -r <name>"

