#!/bin/dash
# Autostart script for kiosk mode
clear
/usr/local/bin/mupibox/./startup.sh &

rm -f ~/.config/chromium/Singleton*

CONFIG="/etc/mupibox/mupiboxconfig.json"

eval $(/usr/bin/jq -r '
  "RES_X='\''" + (.chromium.resX | tostring) + "'\''
  RES_Y='\''" + (.chromium.resY | tostring) + "'\''
  DEBUG='\''" + (.chromium.debug | tostring) + "'\''
  FORCE_GPU='\''" + (.chromium.gpu | tostring) + "'\''
  SCROLL_ANIMATION='\''" + (.chromium.scrollanimation | tostring) + "'\''
  CACHE_PATH='\''" + (.chromium.cachepath | tostring) + "'\''
  CACHE_SIZE='\''" + (.chromium.cachesize | tostring) + "'\''
  KIOSK='\''" + (.chromium.kiosk | tostring) + "'\''
  START_SOUND='\''" + (.mupibox.startSound | tostring) + "'\''
  START_VOLUME='\''" + (.mupibox.startVolume | tostring) + "'\''
  AUDIO_DEVICE='\''" + (.mupibox.audioDevice | tostring) + "'\''"
' "${CONFIG}")

CACHE_SIZE=$(( $CACHE_SIZE * 1024 * 1024))

CHROMIUM_OPTS="--fast --fast-start --skip-gpu-data-loading"
CHROMIUM_OPTS="${CHROMIUM_OPTS} --renderer-process-limit=4 --js-flags=--max-old-space-size=128"
CHROMIUM_OPTS="${CHROMIUM_OPTS} --no-first-run --no-default-browser-check --password-store=basic"
CHROMIUM_OPTS="${CHROMIUM_OPTS} --disable-extensions --disable-component-extensions-with-background-pages"
CHROMIUM_OPTS="${CHROMIUM_OPTS} --disable-background-networking --disable-sync --disable-translate"
CHROMIUM_OPTS="${CHROMIUM_OPTS} --disable-features=Translate,OptimizationHints,MediaRouter,DialMediaRouteProvider,CalculateNativeWinOcclusion,InterestFeedContentSuggestions,OverscrollHistoryNavigation"
CHROMIUM_OPTS="${CHROMIUM_OPTS} --hide-scrollbars"

if [ "${FORCE_GPU}" = "true" ] ; then
        CHROMIUM_OPTS="${CHROMIUM_OPTS} --ignore-gpu-blocklist --enable-gpu --use-gl=egl --enable-unsafe-webgpu --enable-gpu-rasterization"
else
        CHROMIUM_OPTS="${CHROMIUM_OPTS} --disable-gpu --disable-software-rasterizer"
fi

if [ "${SCROLL_ANIMATION}" = "true" ] ; then
        CHROMIUM_OPTS="${CHROMIUM_OPTS} --enable-smooth-scrolling"
else
        CHROMIUM_OPTS="${CHROMIUM_OPTS} --disable-smooth-scrolling"
fi

CHROMIUM_OPTS="${CHROMIUM_OPTS} --noerrdialogs"
CHROMIUM_OPTS="${CHROMIUM_OPTS} --window-size=${RES_X:-1280},${RES_Y:-720} --window-position=0,0"
CHROMIUM_OPTS="${CHROMIUM_OPTS} --cast-app-background-color=44afe2ff --default-background-color=44afe2ff"

if [ "${KIOSK}" = "true" ] ; then
        CHROMIUM_OPTS="${CHROMIUM_OPTS} --kiosk --start-fullscreen --start-maximized"
fi

# use in-memory cache in /dev/shm (RAM-backed) by default
CACHE_DIR=/dev/shm/chromium_cache
mkdir -p "${CACHE_DIR}"
CHROMIUM_OPTS="${CHROMIUM_OPTS} --disk-cache-dir=${CACHE_DIR} --disk-cache-size=${CACHE_SIZE:-33554432}"
if [ "${DEBUG}" = "1" ]; then
        CHROMIUM_OPTS="${CHROMIUM_OPTS} --enable-logging --v=1 --disable-pinch"
fi

CHROMIUM_OPTS="${CHROMIUM_OPTS} --autoplay-policy=no-user-gesture-required"

FP_CHROMIUM=$(command -v chromium-browser || command -v chromium)
STARTX='xinit'
[ "$USER" = 'root' ] || STARTX='startx'

# Start X/Chromium in background
"$STARTX" "$FP_CHROMIUM" $CHROMIUM_OPTS --homepage "http://localhost:8200/" -- -nocursor vt$(fgconsole) &

pactl load-module module-bluetooth-discover &

# START SOUND 
/usr/bin/pactl set-sink-volume @DEFAULT_SINK@ ${START_VOLUME}%
/usr/bin/paplay --volume=65536 "${START_SOUND}" &

(
    sleep 10
    # Renice Node and Chromium efficiently without read loops
    pgrep -f "chromium" | xargs -r sudo renice -n -10 -p
    pgrep -f "node" | xargs -r sudo renice -n -10 -p
    
    sleep 15
    x11vnc -ncache 0 -forever -display :0
) &

clear
