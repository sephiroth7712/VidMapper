const electron = require('electron');
const url = require('url');
const path = require('path');

const { app, BrowserWindow, Menu, ipcMain } = electron;

global.filepath = undefined;

app.on('ready', function () {
	let splash = new BrowserWindow({
		width: 640,
		height: 480,
		icon: __dirname+'/assets/icons/logo_64x64.png',
		frame: false,
		backgroundColor: '#000000',
		transparent:true
	});
	splash.loadURL(
		url.format({
			pathname: path.join(__dirname, 'splash.html'),
			protocol: 'file',
			slashes: true
		})
	);
	splash.show();
	let main = new BrowserWindow({
		show: false,
		icon: __dirname+'/assets/icons/logo_64x64.png',
		webPreferences: {
			nodeIntegration: true,
			enableRemoteModule: true
		},
		autoHideMenuBar:true
	});
	main.loadURL(
		url.format({
			pathname: path.join(__dirname, 'main.html'),
			protocol: 'file',
			slashes: true
		})
	);
	main.webContents.on('did-finish-load', function() {
		splash.destroy();
		main.maximize();
	});

	main.webContents.openDevTools();
	// main.once('ready-to-show', () => {
	// 	splash.destroy();
	// 	main.maximize();
	// });
	main.on('window-all-closed', () => {
		if (process.platform !== 'darwin') {
		  app.quit()
		}
	  })
	  main.on('activate', () => {
		// On macOS it's common to re-create a window in the app when the
		// dock icon is clicked and there are no other windows open.
		if (BrowserWindow.getAllWindows().length === 0) {
		  createWindow()
		}
	  })
});