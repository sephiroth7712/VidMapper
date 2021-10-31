const fs = require('fs');
const xml2js = require('xml2js');
const parser = new xml2js.Parser();
let markers = [];
let _map;
let isMapInitialized = false;
let isIntervalSetted = false;
let positions = null;
let rem_path;
let completed_path;
let last_index = 0;
let vid = document.getElementById('vid');
let headingExists
let headingString
vid.ontimeupdate = function () {
	updateMap();
};

const updateMap = () => {
	let curr_pos_index = Math.floor(vid.currentTime);
	if (vid.currentTime === 0 || curr_pos_index === last_index) {
		return;
	}
	last_index = curr_pos_index;
	let travelled = [];
	let remaining = [];
	if (markers.length == 3) {
		markers[2].setMap(null);
		markers.splice(2, 1);
	}
	if (headingExists) {
		let icon_type
		if (curr_pos_index >= headingString.length) {
			icon_type = Math.floor(headingString[headingString.length - 1] / 22.5)
		}
		else {
			icon_type = Math.floor(headingString[curr_pos_index] / 22.5)
		}
		
		addMarker(positions[curr_pos_index], 'Curr', icon_type)
	}
	else {
		addMarker(positions[curr_pos_index], 'Curr', -1);
	}

	if (completed_path !== undefined) {
		completed_path.setMap(null)
	}
	let currentLocation = document.getElementById("currentCoordinates")
	currentLocation.innerHTML = `Current Location:<br>Latitude: ${positions[curr_pos_index].lat} Longtitude: ${positions[curr_pos_index].lng}`
	travelled = [...positions.slice(0, curr_pos_index + 1)];
	completed_path = new google.maps.Polyline({
		path: travelled,
		geodesic: true,
		strokeColor: '#287ac6',
		strokeOpacity: 1.0,
		strokeWeight: 6
	});
	completed_path.setMap(_map)
}

const initMap = () => {
	let kml_url = decodeURI(window.location.href)
	let vars = {};
	let parts = kml_url.replace(/[?&]+([^=&]+)=([^&]*)/gi, function (m, key, value) {
		vars[key] = value;
	});
	let kml = fs.readFileSync(vars['kml_src']).toString('utf-8');
	parser.parseString(kml, function (err, result) {
		// console.log(result['kml']['Document'][0]['Placemark'][0]['LineString'][0]['headings'])
		headingExists = !result['kml']['Document'][0]['Placemark'][0]['LineString'][0]['headings'] === undefined
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
		if (headingExists) {
			headingString = result['kml']
			['Document'][0]
			['Placemark'][0]
			['LineString'][0]
			['headings'][0]
				.trim()
				.split(' ')
			if (headingString[0] === null) {
				headingExists = false
			}
			else {
				headingString = headingString.map(Number)
			}
		}
		positions = output
		rem_path = new google.maps.Polyline({
			path: positions,
			geodesic: true,
			strokeColor: '#000000',
			strokeOpacity: 1.0,
			strokeWeight: 6
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
		let bounds = new google.maps.LatLngBounds();
		for (let i = 0; i < positions.length; i++) {
			let myLatLng = new google.maps.LatLng(positions[i].lat, positions[i].lng);
			bounds.extend(myLatLng);

		}
		addMarker(positions[0], "Start", -1);
		addMarker(positions[positions.length - 1], "End", -1);
		_map.fitBounds(bounds);
	});
}

const clearMarkers = () => {
	for (i = 0; i < markers.length; i++) {
		markers[i].setMap(null);
	}
}

const deleteMarkers = () => {
	clearMarkers();
	markers = [];
}

const addMarker = (pos, loc_type, icon_type) => {
	let marker = null;
	const image = 'https://developers.google.com/maps/documentation/javascript/examples/full/images/beachflag.png';
	if (loc_type === 'Start' || loc_type === 'End') {
		marker = new google.maps.Marker({
			position: { lat: pos.lat, lng: pos.lng },
			// label: loc_type,
			title: loc_type,
			map: _map,
			icon: image
		});
		markers.push(marker);
	} else if (loc_type === 'Curr') {
		// console.log(_map.getZoom())
		let dir_img
		if (icon_type === -1) {
			dir_img = "http://earth.google.com/images/kml-icons/track-directional/track-none.png"
			var icon = {
				url: dir_img, // url
				scaledSize: new google.maps.Size(50, 50), // scaled size
				origin: new google.maps.Point(0,0), // origin
				anchor: new google.maps.Point(25, 25) // anchor
			};
			
			marker = new google.maps.Marker({
				position: { lat: pos.lat, lng: pos.lng },
				title: 'Current Location',
				map: _map,
				icon: icon
			});
		}
		else {
			dir_img = `http://earth.google.com/images/kml-icons/track-directional/track-${icon_type}.png`
			var icon = {
				url: dir_img, // url
				scaledSize: new google.maps.Size(50, 50), // scaled size
				origin: new google.maps.Point(0,0), // origin
				anchor: new google.maps.Point(25,25) // anchor
			};
			marker = new google.maps.Marker({
				position: { lat: pos.lat, lng: pos.lng },
				title: 'Current Location',
				map: _map,
				icon: icon
			});
		}

		markers.push(marker);
	}
}
