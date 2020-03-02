<?php

/*
 * A script to place on your server.
 * It acts as a backend for screens-uploader.bash
 */

function exit_response($code, $text) {
    http_response_code($code);
    exit($text);
}

// allowed mime types
const EXTENSIONS = [
    "image/png" => "png",
    "video/webm" => "webm",
    "video/mp4" => "mp4"
];

// validate request
if(!isset($_POST["secret"])
|| $_POST["secret"] !== "<insert secret>"
|| !isset($_FILES["file"]))
    exit_response(400, "bad request");

$tmp_name = $_FILES["file"]["tmp_name"];

// if we post from stdin curl will not set the content-type. so we'll just determine it here
$mime = mime_content_type($tmp_name);

if(!array_key_exists($mime, EXTENSIONS))
    exit_response(400, "invalid mime type: {$mime}");

// path and filename
$path = date("Y/m");
$name = uniqid() . "." . EXTENSIONS[$mime];

// check if path exists, create if not
if(!is_dir($path))
    if(!mkdir($path, 0755, true))
        exit_response(500, "error creating directories");


if(!move_uploaded_file($tmp_name, $path . "/" . $name))
    exit_response(500, "error moving uploaded file");


exit_response(200, "https://{$_SERVER['HTTP_HOST']}/{$path}/{$name}");
