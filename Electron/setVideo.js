var fs = require('fs');
var os = require('os');

const { error } = require('console');
const axios = require('axios')
var ffprobe = require('ffprobe'),
	ffprobeStatic = require('ffprobe-static');

const metadata = require('./metadata.js');
const getPreviewMap = require('./getPreviewMap.js');

async function createThumbnail() {
	return new Promise(async function (resolve, reject) {
		try {
			// read videos from /videos
			var files = fs.readdirSync('./videos');
			var files_length = files.length;
			var z = -1;
			files.map((i, j) => {
				var org_name = i;
				name = i.split('.');
				index = name.indexOf(',');
				name = name.slice(0, index);
				var ss_folder = fs.readdirSync('./thumbnails');

				var flag = 0;
				// checking whether ss already exists
				for (var k = 0; k < ss_folder.length; k++) {
					ss_folder[k] = ss_folder[k].split('.');
					ss_index = ss_folder[k].indexOf(',');
					ss_folder[k] = ss_folder[k].slice(0, ss_index);
					if (ss_folder[k][0] === name) {
						flag = 1;
					}
				}
				if (flag == 0) {
					require('child_process').exec(
						`ffmpeg -ss 00:00:02 -i ./videos/${i} -vframes 1 -q:v 2 ./thumbnails/${name}.jpg`,
						function (err) {
							z = z + 1;
							if (z === files_length - 1) {
								resolve();
							}
							console.log(err);
						}
					);
				} else if (flag == 1) {
					resolve();
				}
			});
		} catch (err) {
			reject(err);
		}
	});
}

// getLiveStreams()
// 	.then(() => createThumbnail()
// 		.then(() => renderVideo())
// 		.catch((err) => console.log(err)))
// 	.catch((err) => console.log(err))

createThumbnail()
	.then(() => renderVideo())
	.catch((err) => console.log(err));

function setVideo(name) {
	var s = name.split('.');
	index = s.indexOf(',');
	s = s.slice(0, index);

	document.getElementById('vid').src = './videos/' + s[0] + '.mp4';
	metadata.getMetadata();
	getPreviewMap.getMapStaticImage(s[0]);
}

async function getLiveStreams() {
	return new Promise(async function (resolve, reject) {
		try {
			const res = await axios.get("http://159.65.145.166:8888/api/streams")
			let streams = res.data
			if (typeof (streams["live"] !== "undefined")) {
				// getStreamsInfo(streams["live"]);
				const streamInfo = await axios.post("http://159.65.145.166:5000/streamsInfo",
					{
						streams: streams["live"]
					})
				for (let stream of streamInfo.data) {
					console.log(stream)
					let key = stream["stream_key"]
					let imgSrc = `http://159.65.145.166:5000/thumbnails/${key}.png`
					document.getElementById('rec').innerHTML =
						"<div class='col s12 m6 l6 blue-grey darken-1'><div class='card hoverable' style = 'background-color: red;color: white;padding: 1px 5px;'><div class='card-image '><img height=200 src=" +
						imgSrc +
						// "' onclick=" +
						// tmp +
						" alt='Map'></div><div class='card-content' id='card-title'><p>Time: 12:20" +
						// date +
						' ' +
						// time +
						'<br>Username: ' +
						stream["username"] +
						'</p></div></div></div>' + document.getElementById('rec').innerHTML
				}
			}
			resolve()
		}
		catch (err) {
			reject(err)
		}
	})
}
// getLiveStreams()
function renderVideo() {
	getLiveStreams()
	var files = fs.readdirSync('./thumbnails');

	files.map((i) => {
		var tmp = "setVideo('" + i + "')";
		j = i.split('.');
		index = j.indexOf(',');
		j = j.slice(0, index);
		vid_file = j + '.mp4';

		var cwd = process.cwd();
		let location_file;

		vid = './videos/' + vid_file;
		if (process.platform == 'win32') {
			location_file = cwd + '\\videos\\' + vid_file;
		} else if (process.platform == 'linux') {
			location_file = cwd + '/videos/' + vid_file;
		}
		// Uncomment this if the code is messing up
		// vid = './videos/' + vid_file;

		ffprobe(vid, { path: ffprobeStatic.path })
			.then(function (info) {
				// date
				if (info['streams'][0].tags.creation_time == undefined) {
					var date = '';
					var time = 'NA';
				} else {
					var t = info['streams'][0].tags.creation_time.split('T');
					var date = t[0];
					// time
					var v = new Date(info['streams'][0].tags.creation_time);
					v = v.toString().split(' ');
					var time = v[4];
				}
				document.getElementById('rec').innerHTML +=
					"<div class='col s12 m6 l6 blue-grey darken-1'><div class='card hoverable' ><div class='card-image'><img height=200 src='./thumbnails/" +
					i +
					"' onclick=" +
					tmp +
					" alt='Map'></div><div class='card-content' id='card-title'><p>Time: " +
					date +
					' ' +
					time +
					'<br>Location: ' +
					location_file +
					'</p></div></div></div>';
			})
			.catch(function (err) {
				console.error(err);
			});
	});
}
