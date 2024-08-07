# Base Image
FROM jlesage/baseimage-gui:alpine-3.20-v4.6.3@sha256:37c970f3aa3287e3dc3c5e8d5e273425b149eb44992c8ce658c83f767ae218a5

ENV WINEPREFIX /config/wine/
ENV APP_NAME="Backblaze Personal Backup"
ENV FORCE_LATEST_UPDATE="false"
ENV DISABLE_AUTOUPDATE="true"
ENV DISABLE_VIRTUAL_DESKTOP="false"
ENV DISPLAY_WIDTH="1080"
ENV DISPLAY_HEIGHT="960"
# Disable WINE Debug messages
ENV WINEDEBUG -all
# Set DISPLAY to allow GUI programs to be run
ENV DISPLAY=:0

RUN apk update && \
    apk add --no-cache \
        curl \
        wine=9.0-r0 \
        samba \
        xvfb \
        dpkg \
        dpkg \
    && apk add --no-cache --virtual .build-deps \
    && curl -Lo /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/local/bin/winetricks \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

COPY rootfs/ /
# Make scripts executable
RUN chmod +x /startapp.sh
RUN chmod +x /etc/cont-init.d/*
