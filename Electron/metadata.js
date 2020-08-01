var ffprobe = require('ffprobe'),
	ffprobeStatic = require('ffprobe-static');

function getMetadata() {
	let vid_url;
	if (process.platform == 'win32') {
		vid_url = 'file://' + __dirname + '/videos/lok_bharti_drive.mp4';
	} else if (process.platform == 'linux') {
		vid_url = 'file://' + __dirname + '/videos/lok_bharti_drive.mp4';
	}
	var vid = document.getElementById('vid').src || vid_url;
	if (process.platform == 'win32') {
		vid = vid.substring(8);
	} else if (process.platform == 'linux') {
		vid = vid.substring(7);
	}

	var split_vid = vid.split('/');
	ffprobe(vid, { path: ffprobeStatic.path })
		.then(function(info) {
			// file name
			var name = split_vid[split_vid.length - 1];
			document.getElementById('name').innerHTML = name;

			// file size
			var stats = fs.statSync(vid);
			document.getElementById('size').innerHTML = (stats['size'] / 1000000.0).toFixed(2);

			// date
			if (info['streams'][0].tags.creation_time == undefined) {
				document.getElementById('date').innerHTML = 'NA';
				document.getElementById('time').innerHTML = '';
			} else {
				var t = info['streams'][0].tags.creation_time.split('T');
				document.getElementById('date').innerHTML = t[0];
				// time
				var v = new Date(info['streams'][0].tags.creation_time);
				v = v.toString().split(' ');
				document.getElementById('time').innerHTML = v[4];
			}

			// duration
			var duration = info['streams'][0].duration;

			var totalNumberOfSeconds = duration;
			var hours = parseInt(totalNumberOfSeconds / 3600);
			var minutes = parseInt((totalNumberOfSeconds - hours * 3600) / 60);
			var seconds = Math.floor(totalNumberOfSeconds - (hours * 3600 + minutes * 60));
			var result =
				(hours > 0 ? (hours < 10 ? '0' + hours + ':' : hours + ':') : '') +
				(minutes < 10 ? '0' + minutes : minutes) +
				':' +
				(seconds < 10 ? '0' + seconds : seconds);
			document.getElementById('duration').innerHTML = result;

			// bitrate
			document.getElementById('bits').innerHTML = (parseInt(info['streams'][0].bit_rate) / 8000).toFixed(2);

			// resolution
			document.getElementById('width').innerHTML = info['streams'][0].width;
			document.getElementById('height').innerHTML = info['streams'][0].height;
			var f = info['streams'][0].r_frame_rate.split('/');
			document.getElementById('fps').innerHTML = f[0];
		})
		.catch(function(err) {
			console.error(err);
		});
}

getMetadata();
module.exports = { getMetadata };
