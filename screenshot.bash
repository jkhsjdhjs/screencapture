#!/usr/bin/bash
#
# This script uses flameshot or maim to take a screenshot and
# upload it.
#
# Usage: ./screenshot.bash <option>
# option: gui: start flameshot gui
#        full: capture all screens with flameshot (the whole resolution)
#      screen: capture a specific screen (e.g. ./screenshot.bash screen -n 0)
#      active: capture the currently active window with maim
# returns: 0 on success
#          1 on any error

title="Screenshot Uploader"

[[ "$1" != "gui" && "$1" != "full" && "$1" != "screen" && "$1" != "active" ]] && exit 1

cd "$(dirname "$0")" || exit 1

file="$(mktemp)"

if [[ "$1" != "active" ]]; then
    if ! flameshot "$@" -r > "$file"; then
        notify-send -a "$title" "flameshot encountered an error!" "$(tr < "$file" -d '\000')"
        rm -f "$file"
        exit 1
    fi

    if [[ "$(tr < "$file" -d '\000')" == "screenshot aborted" ]]; then
        rm -f "$file"
        exit
    fi
else
    if ! maim -i "$(xdotool getactivewindow)" > "$file"; then
        notify-send -a "$title" "maim/xdotool encountered an error!" "$(tr < "$file" -d '\000')"
        rm -f "$file"
        exit 1
    fi
fi

if ! link="$("./screens-uploader.bash" "$file")"; then
    notify-send -a "$title" "Upload failed!" "$link"
    rm -f "$file"
    exit 1
fi

rm -f "$file"

echo -n "$link" | xsel -ib
notify-send -a "$title" "Upload successful!" "The link has been copied to clipboard."
