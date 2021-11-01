const ffprobe = require('ffprobe'),
	ffprobeStatic = require('ffprobe-static');

const getMetadata = () => {
	let vid_url;
	const isPlatformWindows = process.platform === 'win32' || process.platform === 'win64'
	const isPlatformLinux = process.platform === 'linux'
	if (isPlatformWindows) {
		vid_url = 'file:\\\\\\' + __dirname + '\\videos\\jb_nagar_drive.mp4';
	} else if (isPlatformLinux) {
		vid_url = 'file://' + __dirname + '/videos/jb_nagar_drive.mp4';
	}

	let vid = document.getElementById('vid').src || vid_url;
	if (isPlatformWindows) {
		vid = vid.substring(8);
		let split_vid = vid.split('\\');

	} else if (isPlatformLinux) {
		vid = vid.substring(7);
		let split_vid = vid.split('/');

	}

	ffprobe(vid, { path: ffprobeStatic.path })
		.then((info) => {
			// file name
			let name = split_vid[split_vid.length - 1];
			document.getElementById('name').innerHTML = name;

			// file size
			let stats = fs.statSync(vid);
			document.getElementById('size').innerHTML = (stats['size'] / 1000000.0).toFixed(2);

			// date
			if (info['streams'][0].tags.creation_time == undefined) {
				document.getElementById('date').innerHTML = 'NA';
				document.getElementById('time').innerHTML = '';
			} else {
				let t = info['streams'][0].tags.creation_time.split('T');
				document.getElementById('date').innerHTML = t[0];
				// time
				let v = new Date(info['streams'][0].tags.creation_time);
				v = v.toString().split(' ');
				document.getElementById('time').innerHTML = v[4];
			}

			// duration
			let duration = info['streams'][0].duration;

			let totalNumberOfSeconds = duration;
			let hours = parseInt(totalNumberOfSeconds / 3600);
			let minutes = parseInt((totalNumberOfSeconds - hours * 3600) / 60);
			let seconds = Math.floor(totalNumberOfSeconds - (hours * 3600 + minutes * 60));
			let result =
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
			let f = info['streams'][0].r_frame_rate.split('/');
			document.getElementById('fps').innerHTML = f[0];
		})
		.catch((err) => {
			console.error(err);
		});
}
getMetadata();
module.exports = { getMetadata };
