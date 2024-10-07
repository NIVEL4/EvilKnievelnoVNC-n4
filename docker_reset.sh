#!/bin/bash

# Remove all unused containers, networks, images (both dangling and unused), and optionally, volumes.
docker system prune --all #--force

# Restore permissions of docker socket
chmod 660 /var/run/docker.sock
