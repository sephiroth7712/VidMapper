const fs = require('fs');
const axios = require('axios')
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

function updateMap() {
    let curr_pos_index = Math.floor(vid.currentTime);
    if (vid.currentTime == 0 || curr_pos_index == last_index) {
        return;
    }
    last_index = curr_pos_index;
    let travelled = [];
    let remaining = [];
    if (markers.length == 3) {
        markers[2].setMap(null);
        markers.splice(2, 1);
    }
    if (headingExists === true) {
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
    // addMarker(positions[curr_pos_index], 'Curr');
    if (completed_path != undefined) {
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

async function initMap() {
    let kml_url = decodeURI(window.location.href)
    let vars = {};
    let parts = kml_url.replace(/[?&]+([^=&]+)=([^&]*)/gi, function (m, key, value) {
        vars[key] = value;
    });
    const res = await axios.get(`http://159.65.145.166:5000/kml?fileName=${vars["files_src"]}`)
    positions = res.data
    if (res.data.headingExists) {
        positions = res.data.output;
        headingExists = res.data.headingExists;
        headingString = res.data.headingString;
    } else {
        positions = res.data.output;
        headingExists = res.data.headingExists;
    }
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
        let position = positions[i];
        let loc_type = 'normal';
        if (i == 0) {
            loc_type = 'Start';
        } else if (i == positions.length - 1) {
            loc_type = 'End';
        }
        addMarker(position, loc_type);
    }
    _map.fitBounds(bounds);
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

function addMarker(pos, loc_type, icon_type) {
    let marker = null;
    const image = 'https://developers.google.com/maps/documentation/javascript/examples/full/images/beachflag.png';
    if (loc_type == 'Start' || loc_type === 'End') {
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
                origin: new google.maps.Point(0, 0), // origin
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
                origin: new google.maps.Point(0, 0), // origin
                anchor: new google.maps.Point(25, 25) // anchor
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

