import 'package:geolocator/geolocator.dart';

class LocationHelper {
  Geolocator geolocator;

  LocationHelper() {
    geolocator = Geolocator();
  }

  Future<Map<String, dynamic>> getCurrentPosition(
      {bool withLocationString}) async {
    Position position;
    List<Placemark> placemark;
    Map<String, dynamic> placemarkJson;
    String placemarkString;
    Map<String, dynamic> returnData = Map<String, dynamic>();

    //Get current location this is the coordinates
    position = await geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    //If user has requestion location string
    if (withLocationString != null && withLocationString) {
      placemark = await geolocator.placemarkFromCoordinates(
          position.latitude, position.longitude);
      placemarkJson = placemark[0].toJson();
      placemarkString =
          placemarkJson["subLocality"] + ", " + placemarkJson["locality"];
      returnData['location'] = placemarkString;
    }

    returnData['latitude'] = position.latitude;
    returnData['longitude'] = position.longitude;
    returnData['altitude'] = position.altitude;

    return returnData;
  }

  Future<double> distanceBetween(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) async {
    return await geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);
  }
}
