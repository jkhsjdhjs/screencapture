#!/usr/bin/env bash
#
# This script creates a temporary file where ffmpeg will
# start recording to. If the script is invoked again it
# will stop the running recording, the previously ran
# script will then upload the script using
# "screens-uploader.bash" and copy the link to the clipboard.
# The user will get notified of any errors via notify-send.
#
# Usage: ./screencast.bash [<audio devices>]
# audio devices: pulseaudio device name (e.g. alsa_output.usb-Logitech_Logitech_G930_Headset-00.analog-stereo)
#                or "default-sink", which selects the monitor device for the default sink
#                or "default-source", which selects the default source
# returns: 0 on success
#          1-4,6-7 as in slop-ffmpeg.bash
#          8 cd failed
#          9 failed to create temporary file
#         10 upload failed

cd "$(dirname "$0")" || exit 8

title="Screencast Uploader"
pid_file="/run/user/$UID/ffmpeg-screencapture.pid"

if [[ ! -r "$pid_file" ]]; then
    if ! file="$(mktemp)"; then
        notify-send -a "$title" "Error creating temporary file for recording!"
        exit 9
    fi

    "./slop-ffmpeg.bash" "$pid_file" "$file" "$@"

    slop_ffmpeg_exit_code="$?"

    case "$slop_ffmpeg_exit_code" in
        0) notify-send -a "$title" "Recording stopped" ;;
        2) notify-send -a "$title" "Temporary file doesn't exist or isn't writeable!" "$file" ;;
        3) notify-send -a "$title" "Error getting default sink!" ;;
        4) notify-send -a "$title" "Error getting default source!" ;;
        5) rm -f "$file"; exit 0 ;;
        6) notify-send -a "$title" "slop encountered an error!" ;;
        7) notify-send -a "$title" "ffmpeg encountered an error!" ;;
        *) notify-send -a "$title" "Unexpected error!" ;;
    esac

    if [[ "$slop_ffmpeg_exit_code" != 0 ]]; then
        rm -f "$file"
        exit "$slop_ffmpeg_exit_code"
    fi

    if ! link="$("./screens-uploader.bash" "$file")"; then
        notify-send -a "$title" "Upload failed!" "$link"
        rm -f "$file"
        exit 10
    fi

    rm -f "$file"

    echo -n "$link" | xsel -ib
    notify-send -a "$title" "Upload successful!" "The link has been copied to clipboard."
else
    if ! kill -15 "$(< "$pid_file")"; then
        notify-send -a "$title" "Failed to end running recording!" "Try removing the pid file: $pid_file"
    fi
fi
