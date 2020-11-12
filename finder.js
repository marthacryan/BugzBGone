process.on('uncaughtException', function(err) {
	console.log('Caught exception: ' + err);
	console.log(err.stack);
});

import fs from 'fs';
import ffmpegStream from 'ffmpeg-stream';
import Jimp from 'jimp';
import request from 'request';
import  TJBot from 'tjbot';
import express from 'express';
import raspividStream from 'raspivid-stream';
import wss from 'express-ws';
import ws from 'ws';
const app = wss(express()).app;

const hardware = [TJBot.HARDWARE.LED_NEOPIXEL];
const tj = new TJBot();
tj.initialize(hardware);

// defining a route
import { fileURLToPath } from 'url';
import { dirname } from 'path';
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
app.get('/', (req, res) => res.sendFile(__dirname + '/index.html'));

// web-socket route

var readyToMakeNextAPIRequest = true;
let locustFound = false;
app.ws('/video-stream', (ws, req) => {
	console.log('Client connected');

	ws.send(JSON.stringify({
		action: 'init',
		width: '960',
		height: '540'
	}));


	var videoStream = raspividStream({  });
	//    var videoStream = raspividStream({ rotation: 180 }); 
	videoStream.on('data', (data) => {
		ws.send(data, { binary: true }, (error) => { if (error) console.error(error); });
	})

	ws.on('close', () => {
		console.log('Client left');

		videoStream.removeAllListeners('data');
	});
});


// Process Video
var latestVideoFrame = null;
async function processVideo(){
	// var videoStream = raspividStream({ rotation: 180
	var videoStream = raspividStream({ });
	var converter = new ffmpegStream.Converter();
	var input = converter.createInputStream({f: "h264"});
	var output = converter.createOutputStream({f: "rawvideo", pix_fmt: "rgb24"});
	videoStream.on('data', (data) => {
		input.write(data);
	});
	output.on('readable', () => {
		const temp = output.read(3*960*540);
		if(temp != null){
			latestVideoFrame = temp;

		}
	});

	//    output.on('readable', () => {
	//        latestVideoFrame = output.read(3*960*540);
	//	console.log(latestVideoFrame);


	//    }); 
	await converter.run();

}

processVideo();

// Image Classification
var options = {
	method: "POST",
	url: "https://gateway.watsonplatform.net/visual-recognition/api/v3/classify?version=2019-02-11",
	port: 443,
	auth: {
		"user": "apikey",
		"pass": "ZWaz8cmXfsOAoNJn69VLoUe9Ko9KA7r3T9doRKj4VBIK"
	},  
	headers: {
		"Content-Type": "multipart/form-data"
	},  
	formData : { 
		"images_file": {
			"value": null,
			"options": {"filename": "images_file"}
		}   
	}   
};

app.ws('/locust-found', (wsLocust, reqLocust) => {
	const classifyLatestFrame = function() {
		if(latestVideoFrame != null && readyToMakeNextAPIRequest){
			new Jimp({data: latestVideoFrame, width: 960, height: 540}, (err, image) => {
				if(image != null){
					console.log("Image created");
					image.getBuffer(Jimp.MIME_JPEG, (err, buffer) => {
						console.log("JPEG Data: ", buffer);
						fs.writeFile("test.jpg", buffer, "binary", () => {console.log("file written");});
						readyToMakeNextAPIRequest = false;
						options["formData"]["images_file"]["value"] = buffer;
						request(options, function (err, res, body) {
							if(err) console.log("request error: ", err);
							console.log("request response", body);
							var n = body.search("locust");
							if(n != -1) {
								//light LED
								locustFound = true;
								console.log("found a locust");
								tj.shine("green");
							}
							else {
								locustFound = false;
								tj.shine('off');

							}
							console.log(locustFound);
							wsLocust.send(JSON.stringify({
								locustFound: locustFound
							}));
							readyToMakeNextAPIRequest = true;
						});
					});
				}else{
					console.log("Jimp error: ", err);
				}
			});
		}
	}
	setInterval(classifyLatestFrame, 2000);
});

app.use(function (err, req, res, next) {
	console.error(err);
	next(err);
})

app.listen(8080, () => console.log('Server started on 8080'));
