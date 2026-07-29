<?php
foreach (['80', '8080', '8000', '8888'] as $port) {
    $url = ($port == '80') 
        ? 'http://localhost/minesec_api/api/auth.php'
        : "http://localhost:$port/minesec_api/api/auth.php";
    $ctx = stream_context_create(['http' => ['timeout' => 2]]);
    $res = @file_get_contents($url, false, $ctx);
    if ($res !== false) {
        echo "FOUND API ON PORT: $port\n";
    } else {
        echo "Port $port: failed\n";
    }
}
