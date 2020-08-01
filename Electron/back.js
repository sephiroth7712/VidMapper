const electron = require('electron');
const path = require('path');

var back = document.getElementById('back');
console.log('vjhdvh')
back.addEventListener('click', () => {
    if (process.platform !== 'darwin') {
        console.log('hai bhai')
        vid_url='main.html'
        electron.remote.getCurrentWindow().loadURL(`file://${__dirname}/${vid_url}`);

    }
    else {
        console.log('bade log')
        vid_url='main.html'
        electron.remote.getCurrentWindow().loadURL(`file://${__dirname}/${vid_url}`);
    }
})
