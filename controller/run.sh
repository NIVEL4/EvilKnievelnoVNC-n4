#!/bin/bash
docker build --rm -t webdevops/php-nginx .

# remove --rm if no modifications to image
docker run --rm --network evil --name controller \
	-v "./vhost.conf:/opt/docker/etc/nginx/vhost.conf:ro" \
	-v "./10-location-root.conf:/opt/docker/etc/nginx/conf.d/vhost.common.d/10-location-root.conf:ro" \
	-v "./src:/app:ro" \
	-v "./cert.crt:/etc/nginx/cert.crt:ro" \
	-v "./key.key:/etc/nginx/key.key:ro" \
	-v "/var/run/docker.sock:/var/run/docker.sock" \
	-v "$(realpath ..)/targets.json:/etc/targets.json" \
	-v "$(realpath ..)/accesslog.txt:/etc/accesslog.txt" \
	-v "$(realpath ..)/submitlog.txt:/etc/submitlog.txt" \
	-v "$(realpath ..)/EvilnoVNC/tmp:/tmp" \
	-v "$(realpath ..)/EvilnoVNC/Files/content.js:/etc/content.js" \
	-v "$(realpath ..)/haproxy/whitelist.acl:/etc/whitelist.acl" \
	-v "$(realpath ..)/haproxy/blacklist.acl:/etc/blacklist.acl" \
	-v "$(realpath ..)/Loot:/etc/Loot" \
	 webdevops/php-nginx #> /dev/null 2>&1

