# Base Image
FROM jlesage/baseimage-gui:debian-11-v4

ENV WINEPREFIX /config/wine/
ENV LANG en_US.UTF-8
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

RUN apt-get update && \
    sed -r -i 's/main$/main contrib non-free/g' /etc/apt/sources.list && \
    apt-get install -y curl software-properties-common gnupg2 winbind xvfb wget procps && \
    dpkg --add-architecture i386 && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bullseye/winehq-bullseye.sources && \
    apt-get update && \
    apt-get install -y winehq-stable && \
    apt-get install -y winetricks && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y locales && \
    sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8 && \
    apt-get clean -y && apt-get autoremove -y

EXPOSE 5900

# Copy all the files
COPY rootfs /

# Make scripts executable
RUN chmod +x /startapp.sh
RUN chmod +x /etc/cont-init.d/50-bz-disable-autoupdate
