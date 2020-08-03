var fs = require('fs');
var os = require('os');
const xml2js = require('xml2js');
const parser = new xml2js.Parser();
const { error } = require('console');
const axios = require('axios')
var ffprobe = require('ffprobe'),
    ffprobeStatic = require('ffprobe-static');
const geocoder = new google.maps.Geocoder()
const metadata = require('./metadata.js');
const getPreviewMap = require('./getPreviewMap.js');
async function delExtra() {
    return new Promise(async function (resolve, reject) {
        try {
            var files = fs.readdirSync('./videos');
            var files_length = files.length;
            var ss_folder = fs.readdirSync('./thumbnails');

            for (var a = 0; a < ss_folder.length; a++) {
                var thumbnail = ss_folder[a]

                var thumbnailWithoutExt = ss_folder[a].split('.');
                var index = thumbnailWithoutExt.indexOf(',');
                thumbnailWithoutExt = thumbnailWithoutExt.slice(0, index);
                let isVideoOfThumbnailNotPresent = 0
                for (var b = 0; b < files.length; b++) {
                    var fileWithoutExt = files[b].split('.');
                    var file_index = fileWithoutExt.indexOf(',');
                    fileWithoutExt = fileWithoutExt.slice(0, file_index);
                    // console.log("comparing", thumbnailWithoutExt[0], fileWithoutExt[0])
                    if (thumbnailWithoutExt[0] !== fileWithoutExt[0]) {
                        isVideoOfThumbnailNotPresent = 1
                    }
                    else {
                        isVideoOfThumbnailNotPresent = 0
                        break;
                    }
                }
                if (isVideoOfThumbnailNotPresent === 1) {
                    let cwd = process.cwd()
                    var p = './thumbnails/' + thumbnail
                    fs.unlink(p, (err => {
                        if (err) console.log(err);
                        // else {
                        //     console.log("\nDeleted file:");
                        // }
                    }));
                }
            }
            resolve()
        }
        catch (err) {
            reject(err);
        }
    });
}

async function createThumbnail() {
    return new Promise(async function (resolve, reject) {
        try {
            // read videos from /videos


            delExtra()
                .then(() => {

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
                })
                .catch((err) => console.log(err));

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

function whichClick(event, tmp) {
    if (event.button === 0) {
        setVideo(tmp)
    }
    else if (event.button === 2) {
        //send this file to the next window
        file = tmp.split(".")
        index = file.indexOf(',');
        file = file.slice(0, index);

        vid_url = 'player.html?vid_src=./videos/' + file + '.mp4' + '&?kml_src=./kml/' + file + '.kml';
        vid_url = encodeURI(vid_url);
        if (process.platform == 'win32') {
            let dir = __dirname
            dir = dir.split('\\',).join('/')
            electron.remote.getCurrentWindow().loadURL(`file://${dir}\\${vid_url}`);
        }
        else if (process.platform == 'linux') {
            electron.remote.getCurrentWindow().loadURL(`file://${__dirname}/${vid_url}`);
        }


    }
}

function whichClickServer(event, tmp) {
    if (event.button === 0) {
        console.log("To Do")
    }
    else {
        let filesURL = `playerServer.html?files_src=${tmp}`;
        filesURL = encodeURI(filesURL);
        if (process.platform == 'win32') {
            let dir = __dirname
            dir = dir.split('\\',).join('/')
            electron.remote.getCurrentWindow().loadURL(`file://${dir}\\${filesURL}`);
        }
        else if (process.platform == 'linux') {
            electron.remote.getCurrentWindow().loadURL(`file://${__dirname}/${filesURL}`);
        }
    }
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
async function getServerVideos() {
    try {
        const res = await axios.get("http://159.65.145.166:5000/getVideos")
        let serverVideos = res.data
        for (let serverVideo of serverVideos) {
            let thumbnail = `http://159.65.145.166:5000/uploads/${serverVideo["fileName"]}.png`
            document.getElementById('rec').innerHTML =
                "<div class='col s12 m6 l6 blue-grey darken-1'><div class='card hoverable' style = 'background-color: grey;color: white;padding: 1px 3px;'><div class='card-image '><img height=200 src=" +
                thumbnail +
                " onmousedown=whichClickServer(event,'" + serverVideo["fileName"] + "')" +
                // tmp +
                " alt='Map'></div><div class='card-content' id='card-title'><p>Username: " +
                serverVideo["username"] +
                ' ' +
                // time +
                '<br>Location: ' +
                serverVideo["location"] +
                '</p></div></div></div>' + document.getElementById('rec').innerHTML
        }
    }
    catch (err) {
        console.error(err)
    }
}
// getLiveStreams()
function renderVideo() {
    getLiveStreams()
    getServerVideos()
    var files = fs.readdirSync('./thumbnails');
    files.map((i) => {
        var tmp = "setVideo('" + i + "')";
        j = i.split('.');
        index = j.indexOf(',');
        j = j.slice(0, index);
        vid_file = j + '.mp4';

        var cwd = process.cwd();
        let location_file;
        let kml_loc
        let file_name = vid_file.split(".")
        vid = './videos/' + vid_file;
        if (process.platform == 'win32') {
            location_file = cwd + '\\videos\\' + vid_file;
            kml_loc = cwd + '\\kml\\' + file_name[0] + ".kml"
        } else if (process.platform == 'linux') {
            location_file = cwd + '/videos/' + vid_file;
            kml_loc = cwd + '/kml/' + file_name[0] + ".kml"
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
                let kml = fs.readFileSync(kml_loc).toString('utf-8');
                parser.parseString(kml, function (err, result) {
                    kmlString = result['kml']
                    ['Document'][0]
                    ['Placemark'][0]
                    ['LineString'][0]
                    ['coordinates'][0]
                        .trim()
                        .split(' ')
                    let kmlArray = kmlString.map((abc) => (abc.trim().split(',')));
                    kmlArray = kmlArray.map(function (elem) {
                        return elem.map(function (elem2) {
                            return parseFloat(elem2)
                        })
                    })
                    let output = kmlArray.map(([lng, lat]) => ({ lng, lat }));
                    geocoder.geocode({ location: output[0] }, (results, status) => {
                        if (status === "OK") {
                            if (results[0]) {
                                let address = results[0].formatted_address
                                address = address.split(",")
                                address = address[address.length - 4].trim() + ", " + address[address.length - 3].trim()
                                document.getElementById('rec').innerHTML +=
                                    "<div class='col s12 m6 l6 blue-grey darken-1'><div class='card hoverable'><div class='card-image'><img height=200 src='./thumbnails/" +
                                    i +
                                    "' onmousedown=whichClick(event,'" + i + "') alt='Map'></div><div class='card-content' id='card-title'><p>Time: " +
                                    date +
                                    ' ' +
                                    time +
                                    '<br>Location: ' +
                                    address +
                                    '</p></div></div></div>';
                            } else {
                                document.getElementById('rec').innerHTML +=
                                    "<div class='col s12 m6 l6 blue-grey darken-1'><div class='card hoverable'><div class='card-image'><img height=200 src='./thumbnails/" +
                                    i +
                                    "' onmousedown=whichClick(event,'" + i + "') alt='Map'></div><div class='card-content' id='card-title'><p>Time: " +
                                    date +
                                    ' ' +
                                    time +
                                    '<br>Location: ' +
                                    'NA' +
                                    '</p></div></div></div>';
                            }
                        } else {
                            document.getElementById('rec').innerHTML +=
                                "<div class='col s12 m6 l6 blue-grey darken-1'><div class='card hoverable'><div class='card-image'><img height=200 src='./thumbnails/" +
                                i +
                                "' onmousedown=whichClick(event,'" + i + "') alt='Map'></div><div class='card-content' id='card-title'><p>Time: " +
                                date +
                                ' ' +
                                time +
                                '<br>Location: ' +
                                'NA' +
                                '</p></div></div></div>';
                        }
                    });

                    // document.getElementById('rec').innerHTML +=
                    //     "<div class='col s12 m6 l6 blue-grey darken-1'><div class='card hoverable'><div class='card-image'><img height=200 src='./thumbnails/" +
                    //     i +
                    //     "' onmousedown=whichClick(event,'" + i + "') alt='Map'></div><div class='card-content' id='card-title'><p>Time: " +
                    //     date +
                    //     ' ' +
                    //     time +
                    //     '<br>Location: ' +
                    //     location_file +
                    //     '</p></div></div></div>';
                });
            })
            .catch(function (err) {
                console.error(err);
            });
    });
}
