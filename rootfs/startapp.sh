#!/bin/sh
set -x

# Globals
config="${CONFIG_DIR:-/config/}"
log_file="${STARTUP_LOGFILE:-${config}/log/backblaze-wine-startup.log}"
install_directory="${config}/installer/"
install_file_name="install_backblaze.exe"
install_file="${install_directory}/${install_file_name}"
install_readme="${install_directory}/README.txt"

# Functions
log_message() {
    echo "$(date): $1" >> "${log_file}"
}

# STARTUP

# Pre-initialize Wine
if [ ! -f "${WINEPREFIX}system.reg" ]; then
    echo "WINE: Wine not initialized, initializing"
    wineboot -i
    log_message "WINE: Initialization done"
fi

#Configure Extra Mounts
for x in {d..z}
do
    if test -d "/drive_${x}" && ! test -d "${WINEPREFIX}dosdevices/${x}:"; then
        log_message "DRIVE: drive_${x} found but not mounted, mounting..."
        ln -s "/drive_${x}/" "${WINEPREFIX}dosdevices/${x}:"
    fi
done

# Set Virtual Desktop
cd "${WINEPREFIX}"
if [ "${DISABLE_VIRTUAL_DESKTOP}" = "true" ]; then
    log_message "WINE: DISABLE_VIRTUAL_DESKTOP=true - Virtual Desktop mode will be disabled"
    winetricks vd=off
else
    # Check if width and height are defined
    if [ -n "${DISPLAY_WIDTH}" ] && [ -n "${DISPLAY_HEIGHT}" ]; then
    log_message "WINE: Enabling Virtual Desktop mode with ${DISPLAY_WIDTH}:${DISPLAY_WIDTH} aspect ratio"
    winetricks vd="${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}"
    else
        # Default aspect ratio
        log_message "WINE: Enabling Virtual Desktop mode with recommended aspect ratio"
        winetricks vd="900x700"
    fi
fi

# Check if backblaze is not installed
if [ ! -f "${WINEPREFIX}drive_c/Program Files (x86)/Backblaze/bzbui.exe" ]; then
    log_message "BZBUI not detected as installed, starting install routine"
    # Create config directory for installer if not present
    if [ ! -d "${install_directory}" ]; then
        log_message "Install Directory created and existing"
        mkdir -p "${install_directory}";
        echo "PUT THE ${install_file_name} file in this folder and restart the container" > "${install_readme}"
        exit
    fi
    
    # Check if installer exists
    if [ ! -f "${install_file}" ]; then
        log_message $(echo "NO ${install_file_name} file found at ${install_file}" | tee "${install_readme}")
        exit
    fi

    # Copy installer to C: drive
    log_message "INSTALLER: Copying ${install_file_name} from ${install_file} -> ${WINEPREFIX}drive_c/${install_file_name}"
    cp -f "${install_file}" "${WINEPREFIX}/drive_c/${install_file_name}"

    log_message "INSTALLER: Changing to: ${WINEPREFIX}/drive_c/"
    cd "${WINEPREFIX}/drive_c/"

    # Run installer
    log_message "INSTALLER: Starting install_backblaze.exe"
    WINEARCH="$WINEARCH" WINEPREFIX="$WINEPREFIX" wine64 "install_backblaze.exe" &
    
    log_message "INSTALLER: Waiting for installer to finish"
    # First wait for the installer to start
    while [ "$(pgrep bzdoinstall)" = "" ]
    do
        sleep 1
    done
    # Now we wait for the bzgui to start
    while [ "$(pgrep bzbui)" = "" ]
    do
        sleep 1
    done
    # It's started we can wait 30 seconds, kill the installer and the bzbui, and force the container to restart
    sleep 30
    kill $(pgrep bzbui) $(pgrep bzdoinstall) $(pgrep install_backblaze)
    exit
fi

# Start the app
log_message "STARTAPP: Starting Backblaze version $(cat "$local_version_file")"
wine64 "${WINEPREFIX}drive_c/Program Files (x86)/Backblaze/bzbui.exe" -noquiet &
sleep infinity
