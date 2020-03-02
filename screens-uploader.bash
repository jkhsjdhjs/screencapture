#!/usr/bin/env bash
#
# This script sends a file to a remote server using curl.
#
# Usage: ./screens-uploader.bash <file>
# file: the file you want to upload
# returns: 0 on success
#          1 on any error
# prints the link on success

response="$(curl -s \
    -F "file=@$1" \
    -F "secret=<insert secret>" \
    -w "\n%{http_code}\n" \
    "https://example.com/upload.php")"

http_code="$(echo "$response" | tail -1)"

[[ "$http_code" != "200" ]] && exit 1

echo "$response" | head -1
