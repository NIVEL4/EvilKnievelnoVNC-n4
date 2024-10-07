#!/bin/bash
docker build --rm -t evilnovnc .

# start.sh dynamic "url" instance-id
# e.g. start.sh dynamic "https://example.com" 02
if [ -n "$2" ]
then
        ./start.sh dynamic "$1" "$2"
else
	./start.sh dynamic "---tUrl---" "$1"
fi

