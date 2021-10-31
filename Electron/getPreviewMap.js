// const xml2js = require('xml2js');
// const parser = new xml2js.Parser();

function getMapStaticImage() {
	let vid_url = document.getElementById('vid').src;
	vid_url = vid_url.split('/');
	kml_name = vid_url[vid_url.length - 1].split('.');
	kml_name = kml_name[0];
	if (kml_name == '') return;
	let kml = fs.readFileSync(`./kml/${kml_name}.kml`).toString('utf-8');
	// let kmlString;
	parser.parseString(kml, function(err, result) {
		kmlString = result['kml']['Document'][0]['Placemark'][0]['LineString'][0]['coordinates'][0].trim().split(' ');
		let kmlArray = kmlString.map((abc) => abc.trim().split(','));
		kmlArray = kmlArray.map(function(elem) {
			return elem.map(function(elem2) {
				return parseFloat(elem2);
			});
		});
		let output = kmlArray.map(([ lng, lat ]) => ({ lng, lat }));
		let api = 'https://maps.googleapis.com/maps/api/staticmap?size=600x300&maptype=roadmap';
		let api_key = '&key=' + process.env.API_KEY;
		api += `&markers=color:red|label:S|${output[0].lat},${output[0].lng}&markers=color:red|label:E|${output[
			output.length - 1
		].lat},${output[output.length - 1].lng}`;
		let path = '&path=color:0xFF0000FF|geodesic:true|weight:2';
		for (i = 0; i < output.length; i++) {
			path += `|${output[i].lat},${output[i].lng}`;
		}
		let final_api= api + path + api_key;
		if(final_api.length>12478){
			path = '&path=color:0xFF0000FF|geodesic:true|weight:2';
			for (i = 0; i < output.length; i+=2) {
				path += `|${output[i].lat},${output[i].lng}`;
			}
		}
		final_api = api+path+api_key
		final_api = encodeURI(final_api);
		document.getElementById('preview_img').src = final_api;
	});
}
getMapStaticImage();
module.exports = { getMapStaticImage };
