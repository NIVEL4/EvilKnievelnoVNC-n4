#!/bin/bash
# stops all running docker containers!
docker stop $(docker ps -a -q)
