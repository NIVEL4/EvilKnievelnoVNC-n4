#!/bin/bash
if [ -z "$1" ]
then
        echo "Error, missing parameters:"
        echo -e "\t $0 (<custom-URL>) <instance-number>"
        echo -e "\t\t custom-URL is optional, see setup.sh"
        echo -e "\t e.g. $0 01"
        echo -e "\t or $0 \"https://target.com\" 01"
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

