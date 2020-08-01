import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vidmapper/models/mappedVideo.dart';
import 'package:vidmapper/utils/LocationHelper.dart';

class FilterHelper {
  static List<MappedVideo> applyFiltersAndSort(List<MappedVideo> snapshot,
      {LatLng coordinate, bool byDateTime}) {
    LocationHelper locationHelper = new LocationHelper();
    if (byDateTime != null && byDateTime)
      sortByDateTime(snapshot, locationHelper);
    if (coordinate != null)
      sortByCoordinates(snapshot, coordinate, locationHelper);
    return snapshot;
  }

  static void sortByDateTime(
      List<MappedVideo> snapshot, LocationHelper locationHelper) {
    print('Function: sortByDateTime');
    snapshot.sort((a, b) {
      return a.timeStamp.compareTo(b.timeStamp);
    });
  }

  static Future<void> sortByCoordinates(List<MappedVideo> snapshot,
      LatLng coordinate, LocationHelper locationHelper) async {
    final computedDistance = <MappedVideo, double>{};
    for (final element in snapshot) {
      computedDistance[element] = await locationHelper.distanceBetween(
        coordinate.latitude,
        coordinate.longitude,
        element.coordinate.latitude,
        element.coordinate.latitude,
      );
    }
    snapshot.sort((a, b) {
      return computedDistance[a].compareTo(computedDistance[b]);
    });
  }
}
