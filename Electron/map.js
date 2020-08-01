var coord_URL = 'http://127.0.0.1:8080';
// const parseKML = require('parse-kml');
// const parseKML = require('./abcd.js')
const fs = require('fs');
const xml2js = require('xml2js');
const parser = new xml2js.Parser();
var markers = [];
var _map;
var isMapInitialized = false;
var isIntervalSetted = false;
var positions = null;
var rem_path;
var completed_path;
var last_index = 0;
var vid = document.getElementById('vid');

vid.ontimeupdate = function () {
	updateMap();
};



function updateMap() {
	console.log(vid.currentTime);
	var curr_pos_index = Math.floor(vid.currentTime);
	if (vid.currentTime == 0 || curr_pos_index == last_index) {
		// console.log("nope")
		return;
	}
	last_index = curr_pos_index;
	var travelled = [];
	var remaining = [];
	if (markers.length == 3) {
		console.log(markers);
		markers[2].setMap(null);
		markers.splice(2, 1);
	}
	
	addMarker(positions[curr_pos_index], 'Curr');
	// rem_path.setMap(null)
	// completed_path.setMap(null)
	for (i = 0; i <= curr_pos_index; i++) {
		travelled.push(positions[i]);
	}
	for (i = curr_pos_index; i < positions.length; i++) {
		remaining.push(positions[i]);
	}
	// addMarker(positions[0],"Start")
	// addMarker(positions[positions.length-1],"End")

	// rem_path = new google.maps.Polyline({
	// 	path: remaining,
	// 	geodesic: true,
	// 	strokeColor: '#FF0000',
	// 	strokeOpacity: 1.0,
	// 	strokeWeight: 2
	// });
	// completed_path = new google.maps.Polyline({
	// 	path: travelled,
	// 	geodesic: true,
	// 	strokeColor: '#008000',
	// 	strokeOpacity: 1.0,
	// 	strokeWeight: 2
	// });
	// console.log(rem_path)
	// console.log(completed_path)
	// rem_path.setMap(_map)
	// completed_path.setMap(_map)
}

function initMap() {
	var kml_url = decodeURI(window.location.href)
	var vars = {};
	var parts = kml_url.replace(/[?&]+([^=&]+)=([^&]*)/gi, function (m, key, value) {
		vars[key] = value;
	});
	let kml = fs.readFileSync(vars['kml_src']).toString('utf-8');
	// let kmlString;
	parser.parseString(kml, function (err, result) {
		kmlString = result['kml']
		['Document'][0]
		['Placemark'][0]
		['LineString'][0]
		['coordinates'][0]
			.trim()
			.split(' ')
		let kmlArray = kmlString.map((abc) => (abc.trim().split(',')));
		kmlArray = kmlArray.map(function(elem){
			return elem.map(function(elem2){
				return parseFloat(elem2)
			})
		})
		let output = kmlArray.map(([lng, lat]) => ({ lng, lat }));
		// console.log(output)
		positions = output
		// console.log(positions)
		rem_path = new google.maps.Polyline({
			path: positions,
			geodesic: true,
			strokeColor: '#FF0000',
			strokeOpacity: 1.0,
			strokeWeight: 2
		});
		if (isMapInitialized === false) {
			_map = new google.maps.Map(document.getElementById('map'), {
				zoom: 15,
				center: new google.maps.LatLng(0, 0)
			});
			rem_path.setMap(_map);
			isMapInitialized = true;
		} else {
			rem_path.setMap(_map);
		}
		google.maps.event.trigger(_map, 'resize');
		deleteMarkers();
		var bounds = new google.maps.LatLngBounds();
		for (var i = 0; i < positions.length; i++) {
			var myLatLng = new google.maps.LatLng(positions[i].lat, positions[i].lng);
			bounds.extend(myLatLng);
			var position = positions[i];
			var loc_type = 'normal';
			if (i == 0) {
				loc_type = 'Start';
			} else if (i == positions.length - 1) {
				loc_type = 'End';
			}
			addMarker(position, loc_type);
		}
		_map.fitBounds(bounds);
	});

	if (isIntervalSetted === false) {
		setTimeout(initMap, 0);
		isIntervalSetted = true;
	}
}

function clearMarkers() {
	for (i = 0; i < markers.length; i++) {
		markers[i].setMap(null);
	}
}

function deleteMarkers() {
	clearMarkers();
	markers = [];
}

function addMarker(pos, loc_type) {
	var marker = null;
	const image = 'https://developers.google.com/maps/documentation/javascript/examples/full/images/beachflag.png';
	if (loc_type == 'Start' || loc_type == 'End') {
		marker = new google.maps.Marker({
			position: { lat: pos.lat, lng: pos.lng },
			label: loc_type,
			title: loc_type,
			map: _map,
			icon: image
		});
		markers.push(marker);
	} else if (loc_type == 'Curr') {
		console.log('added');
		marker = new google.maps.Marker({
			position: { lat: pos.lat, lng: pos.lng },
			title: 'Current Location',
			map: _map
		});
		markers.push(marker);
	}
}
