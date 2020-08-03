const electron = require('electron');
const path = require('path');
//const fs = require('fs');
const archiver = require('archiver');
const { remote } = require('electron');
const extract = require('extract-zip');
const { availableCodecs } = require('fluent-ffmpeg');
const dialog = electron.remote.dialog;

var src = document.getElementById('vid').src;
let vid_url;

if (process.platform == 'win32') {
	vid_url = 'file://' + __dirname + '/videos/jb_nagar_drive.mp4';
} else if (process.platform == 'linux') {
	vid_url = 'file://' + __dirname + '/videos/jb_nagar_drive.mp4';
}

document.getElementById('vid').src = src || vid_url;

var uploadFile = document.getElementById('open');
var merge = document.getElementById('merge');
var ss = document.getElementById('ss');

// for opening file
global.open_files_path = [null, null];

// empty array declaration for merging
global.merge_files_path = [null, null];

// FOR MERGING
merge.addEventListener('click', () => {
	if (process.platform !== 'darwin') {
		dialog
			.showOpenDialog({
				title: 'Select Video file',
				defaultPath: path.join(__dirname, ''),
				buttonLabel: 'Select',
				properties: ['openFile'],
				filters: [
					{
						name: ' Select the Video File',
						extensions: ['mp4', 'webm', 'ogg']
					}
				]
			})
			.then((file) => {
				//returns boolean value
				if (!file.canceled) {
					// push the path of video to the array
					global.merge_files_path[0] = file.filePaths[0].toString();
					dialog
						.showOpenDialog({
							title: 'Select KML file',
							defaultPath: path.join(__dirname, ''),
							buttonLabel: 'Select',
							properties: ['openFile'],
							filters: [
								{
									name: ' Select the KML File',
									extensions: ['kml']
								}
							]
						})
						.then((file) => {
							try {
								global.merge_files_path[1] = file.filePaths[0].toString();
								let vid_name
								let kml_name
								let slash
								if (process.platform == "win32") {
									vid_name = global.merge_files_path[0].split("\\")
									kml_name = global.merge_files_path[1].split("\\")
									slash="\\"
								}
								else if (process.platform == "linux") {
									vid_name = global.merge_files_path[0].split("/")
									kml_name = global.merge_files_path[1].split("/")
									slash = "/"
								}
								vid_name = vid_name[vid_name.length - 1]
								vid_name = vid_name.split(".")
								vid_name = vid_name[0]
								kml_name = kml_name[kml_name.length - 1]
								kml_name = kml_name.split(".")
								kml_name = kml_name[0]
								if (!file.canceled && (kml_name === vid_name)) {
									// push the path of kml to the array
									dialog
										.showSaveDialog({
											title: 'Save file to',
											defaultPath: path.join(__dirname, slash+"kmz")+slash+vid_name,
											buttonLabel: 'Save As',
											filters: [
												{
													name: 'Save the KMZ File',
													extensions: ['kmz']
												}
											]
										})
										.then((file) => {
											if (!file.canceled) {
												let output = fs.createWriteStream(file.filePath + '.kmz');
												let archive = archiver('zip', {
													gzip: true,
													zlib: { level: 9 } // Sets the compression level.
												});

												// Log any errors
												archive.on('error', function (err) {
													throw err;
												});

												// pipe archive data to the output file
												archive.pipe(output);

												// append files
												for (let i = 0; i < global.merge_files_path.length; i++) {
													let name = global.merge_files_path[i].split('/');
													name = name[name.length - 1];
													let ext = name.split('.');
													if (ext[1] === 'mp4') {

														name = '/files/' + name;
													}
													archive.file(global.merge_files_path[i], { name: name });
												}

												// Wait for streams to complete
												archive.finalize();
												let video_path_array = '';
												let kml_path_array = '';
												// direct the video and kml to player.html
												if (process.platform == 'win32') {
													video_path_array = global.merge_files_path[0].split('\\')
													kml_path_array = global.merge_files_path[1].split('\\')
												}
												else if (process.platform == 'linux') {
													video_path_array = global.merge_files_path[0].split('/')
													kml_path_array = global.merge_files_path[1].split('/')
												}
												let video_file = video_path_array[video_path_array.length - 1]
												let kml_file = kml_path_array[kml_path_array.length - 1]

												vid_url = 'player.html?vid_src=./videos/' + video_file + '&?kml_src=./kml/' + kml_file;
												vid_url = encodeURI(vid_url);
												if (process.platform == 'win32') {
													let dir = __dirname
													dir = dir.split('\\',).join('/')
													electron.remote.getCurrentWindow().loadURL(`file://${dir}/${vid_url}`);
												}
												else if (process.platform == 'linux') {
													electron.remote.getCurrentWindow().loadURL(`file://${__dirname}/${vid_url}`);
												}

												// emptying the array
												global.merge_files_path = [null, null];
											}
										});
								}
							}
							catch (err) {
								console.error(err)
							}
						})
						.catch((err) => {
							console.log(err);
						});
				}
			})
			.catch((err) => {
				console.log(err);
			});
	} else {
		dialog
			.showOpenDialog({
				title: 'Select the Video file',
				defaultPath: path.join(__dirname, ''),
				buttonLabel: 'Select',
				properties: ['openFile'],

				filters: [
					{
						name: 'Video File',
						extensions: ['mp4', 'ogg', 'avi']
					}
				]
			})
			.then((file) => {
				if (!file.canceled) {
					//push the video path
					global.merge_files_path[0] = file.filePaths[0].toString();
					dialog
						.showOpenDialog({
							title: 'Select KML file',
							defaultPath: path.join(__dirname, ''),
							buttonLabel: 'Select',
							properties: ['openFile'],
							filters: [
								{
									name: ' Select the KML File',
									extensions: ['kml']
								}
							]
						})
						.then((file) => {
							if (!file.canceled) {
								// push the path of kml to the array
								global.merge_files_path[1] = file.filePaths[0].toString();

								// set the metadata
								// document.getElementById('metadata').innerHTML = global.merge_files_path;

								//emptying the array
								global.merge_files_path.length = 0;
							}
						})
						.catch((err) => {
							console.log(err);
						});
				}
			})
			.catch((err) => {
				console.log(err);
			});
	}
});

// OPENING FILE
uploadFile.addEventListener('click', () => {
	// If the platform is 'win32' or 'Linux'
	if (process.platform !== 'darwin') {
		// Resolves to a Promise<Object>
		dialog
			.showOpenDialog({
				title: 'Select the File to be uploaded',
				defaultPath: path.join(__dirname, ''),
				buttonLabel: 'Upload',
				// Restricting the user to only Video Files.
				filters: [
					{
						name: 'Video or KMZ Files',
						extensions: ['mp4', 'webm', 'ogg', 'kmz']
					}
				],
				properties: ['openFile']
			})
			.then((file) => {
				if (!file.canceled) {
					global.open_files_path[0] = file.filePaths[0].toString();
					let fileExtension = global.open_files_path[0].split('.');
					let extension = fileExtension[fileExtension.length - 1];
					let fileName = fileExtension[0].split('/')
					fileName = fileName[fileName.length - 1]
					if (extension == 'kmz') {
						async function main() {
							try {
								await extract(global.open_files_path[0], { dir: __dirname + '/extracted' });
								global.open_files_path = [];
								global.open_files_path.push(__dirname + `/extracted/files/${fileName}.mp4`)
								global.open_files_path.push(__dirname + `/extracted/${fileName}.kml`)
								vid_url =
									'player.html?vid_src=' +
									global.open_files_path[0] +
									'&?kml_src=' +
									global.open_files_path[1];
								vid_url = encodeURI(vid_url);
								// emptying the array
								global.open_files_path = [null, null];
								electron.remote.getCurrentWindow().loadURL(`file://${__dirname}/${vid_url}`);
							} catch (err) {
								// handle any errors
								console.error(err);
							}
						}
						main();
					} else {
						dialog
							.showOpenDialog({
								title: 'Select KML file',
								defaultPath: path.join(__dirname, ''),
								buttonLabel: 'Select',
								properties: ['openFile'],
								filters: [
									{
										name: ' Select the KML File',
										extensions: ['kml']
									}
								]
							})
							.then((file) => {
								if (!file.canceled) {
									// push the path of kml to the array
									global.open_files_path[1] = file.filePaths[0].toString();
									vid_url =
										'player.html?vid_src=' +
										global.open_files_path[0] +
										'&?kml_src=' +
										global.open_files_path[1];
									vid_url = encodeURI(vid_url);
									//emptying the array
									global.open_files_path = [null, null];
									electron.remote.getCurrentWindow().loadURL(`file://${__dirname}/${vid_url}`);
								}
							});
					}
				}
			})
			.catch((err) => {
				console.log(err);
			});
	} else {
		dialog
			.showOpenDialog({
				title: 'Select the File to be uploaded',
				defaultPath: path.join(__dirname, '../assets/'),
				buttonLabel: 'Upload',
				// Restricting the user to only Video Files.
				filters: [
					{
						name: 'Video Files',
						extensions: ['mp4', 'avi', 'ogg']
					}
				],
				properties: ['openFile']
			})
			.then((file) => {
				if (!file.canceled) {
				}
			})
			.catch((err) => {
				console.log(err);
			});
	}
});
