const electron = require('electron');
const url = require('url');
const path = require('path');

const { app, BrowserWindow, Menu, ipcMain } = electron;

global.filepath = undefined;

const isPlatformDarwin = process.platform === 'darwin';

app.on('ready', () => {
	const splash = new BrowserWindow({
		width: 1024,
		height: 768,
		icon: __dirname+'/assets/icons/logo_64x64.png',
		frame: false,
		backgroundColor: '#0f0f0f',
		transparent: false
	});
	splash.loadURL(
		url.format({
			pathname: path.join(__dirname, 'splash.html'),
			protocol: 'file',
			slashes: true
		})
	);
	splash.show();
	const main = new BrowserWindow({
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
	main.on('window-all-closed', () => {
		if (!isPlatformDarwin) {
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
