#!/bin/bash

# build
docker build --rm -t haproxy .

# run
docker run --rm --name hap --network evil -p ---victimPort---:443 -p ---adminPort---:1300 \
	-v ---certandkey---:/etc/certandkey.pem \
	-v ./whitelist.acl:/etc/whitelist.acl \
	-v ./blacklist.acl:/etc/blacklist.acl \
	-v ./503.http:/etc/haproxy/503.http \
	haproxy 

	#-v /root/haproxy/cors.lua:/etc/cors.lua \

# certandkey.pem built from cert.pem and privatekey.pem
