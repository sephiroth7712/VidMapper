const electron = require('electron');
const path = require('path');

var back = document.getElementById('back');
back.addEventListener('click', () => {
    if (process.platform !== 'darwin') {
        vid_url='main.html'
        electron.remote.getCurrentWindow().loadURL(`file://${__dirname}/${vid_url}`);

    }
    else {
        vid_url='main.html'
        electron.remote.getCurrentWindow().loadURL(`file://${__dirname}/${vid_url}`);
    }
})
