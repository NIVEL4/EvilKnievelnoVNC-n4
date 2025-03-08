#!/bin/bash
if [ -z "$1" ]
then
        echo "Error: missing instance parameter"
	echo "Usage:"
        echo -e "\t $0 (<custom-URL>) <two digit instance number>"
        echo -e "\t\t $0 01"
        echo -e "\t\t $0 02"
	echo -e "\t\t ..."
        echo -e "\t\t custom-URL is optional, configure URL with setup.sh"
        exit 1
fi

docker build --rm -t evilnovnc .

# start.sh dynamic "url" instance-id
# e.g. start.sh dynamic "https://example.com" 02
if [ -n "$2" ]
then
        ./start.sh dynamic "$1" "$2"
else
	./start.sh dynamic "---tUrl---" "$1"
fi

