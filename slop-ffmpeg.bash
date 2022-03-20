#!/usr/bin/env bash
#
# This script will run slop (select operation) so the user
# can select an area (or a window). The selected area will
# then get recorded by ffmpeg, until the ffmpeg process is
# killed.
#
# Usage: ./slop-ffmpeg.bash <pid file> <output file> [<audio devices>]
# pid file:      the file where the ffmpeg process pid will be written to
# output file:   file where ffmpeg should write the recorded video to
# audio devices: pulseaudio device name (e.g. alsa_output.usb-Logitech_Logitech_G930_Headset-00.analog-stereo)
#                or "@DEFAULT_SINK@", which selects the monitor device for the default sink
#                or "@DEFAULT_SOURCE@", which selects the default source
# returns: 0 on success
#          1 if another instance of this script is already running (pid file exists)
#          2 if the output file doesn't exists or is not writeable
#          3 if the script failed to get the name of the default sink
#          4 if the script failed to get the name of the default source
#          5 if slop exited with 1 (user abort)
#          6 if slop exited with an exit code other than 1 or 0
#          7 if ffmpeg errored

pid_file="$1"
ffmpeg_out="$2"
shift 2

# check if another instance is already running
[[ -e "$pid_file" ]] && exit 1

# check if file exists and is writeable
[[ ! -w "$ffmpeg_out" ]] && exit 2

# get audio devices
audio_devices=()
for arg in "$@"; do
    case "$arg" in
        "@DEFAULT_SINK@")
            device="$(pactl get-default-sink).monitor" || exit 3
            ;;
        "@DEFAULT_SOURCE@")
            device="$(pactl get-default-source)" || exit 4
            ;;
        *) device="$arg" ;;
    esac
    audio_devices+=(
        "-thread_queue_size"
        "512"
        "-f"
        "pulse"
        "-i"
        "$device"
    )
done

(( ${#audio_devices[@]} > 6 )) && audio_devices+=(
    "-filter_complex"
    "amix=inputs=$(( ${#audio_devices[@]} / 6 ))"
)

# selection screen area
slop="$(slop -lc 0,.4,.7,.6 -f "%x %y %w %h")"
slop_exit_code="$?"
[[ "$slop_exit_code" == 1 ]] && exit 5
[[ "$slop_exit_code" != 0 ]] && exit 6

# read variables
read -r X Y W H < <(echo "$slop")

# check again if another instance is already running
[[ -e "$pid_file" ]] && exit 1

# record mp4
ffmpeg -y -probesize 32 \
    -thread_queue_size 1024 -f x11grab -s "$W"x"$H" -r 60 -i :0.0+"$X","$Y" \
    "${audio_devices[@]}" \
    -f mp4 -preset ultrafast -pix_fmt yuv420p -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" "$ffmpeg_out" &

# write pid to file
echo -n "$!" > "$pid_file"

# wait for ffmpeg to exit
wait "$!"
ffmpeg_exit_code="$?"

# remove pid file
rm -f "$pid_file"

# check ffmpeg exit code, return 0 if 255 (killed by SIGTERM), otherwise return 7
[[ "$ffmpeg_exit_code" != "255" ]] && exit 7 || exit 0
