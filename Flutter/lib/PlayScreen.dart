import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:vidmapper/utils/LocationHelper.dart';
import 'package:vidmapper/utils/XMLHelper.dart';
import 'package:xml/xml.dart';

import 'models/mappedVideo.dart';
import 'models/styles.dart';

class PlayScreen extends StatefulWidget {
  final MappedVideo video;

  PlayScreen({@required this.video, Key key}) : super(key: key);
  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  // VideoPlayerController _controller;
  FlickManager flickManager;
  VideoPlayerController videoPlayerController;
  XMLHelper xmlHelper;
  // Future<void> _initializeVideoPlayerFuture;

  //Google Map stuff
  GoogleMapController mapController;

  //CALDEN: Coordinates
  LatLng _center = const LatLng(40.3399, 127.5101);
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  List<LatLng> polylineCoordinatesCovered = [];
  List<LatLng> polylineCoordinatesToBeCovered = [];
  XmlDocument document;
  List<List<double>> coordinates = [];

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setPolyLines();
  }

  Future<void> setPolyLines() async {
    xmlHelper = new XMLHelper(kmlFile: widget.video.kml);
    await xmlHelper.initializeDocument();
    coordinates = xmlHelper.getCoordinatesFromXML();
    // mapController.moveCamera(CameraUpdate.newCameraPosition(
    //   CameraPosition(
    //     target: LatLng(coordinates[0][1], coordinates[0][0]),
    //     zoom: 14.0,
    //   ),
    // ));
    //Add coordinates to polylineCoordinates in LatLng format
    coordinates.forEach((element) {
      polylineCoordinates.add(LatLng(element[1], element[0]));
    });
    mapController.moveCamera(CameraUpdate.newLatLngBounds(
        boundsFromLatLngList(polylineCoordinates), 50));
    // //Create a polyline
    // //Pratik Set style for line to be covered
    // Polyline polyline = Polyline(
    //   polylineId: PolylineId("poly"),
    //   color: Color.fromARGB(255, 40, 122, 198),
    //   points: polylineCoordinates,
    // );
    // Marker marker = getMarker(
    //   markerId: '0',
    //   position: LatLng(coordinates[0][1], coordinates[0][0]),
    // );
    // //Set polyline & marker
    // setState(() {
    //   _polylines.add(polyline);
    //   _markers.add(marker);
    // });
  }

  LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1) y1 = latLng.longitude;
        if (latLng.longitude < y0) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }

  _googleMapOnTap(LatLng coordinate) async {
    // print('Function: _googleMapOnTap $coordinate');
    // LocationHelper locationHelper = new LocationHelper();
    // int index = 0;
    // double minLatLngDistance = double.infinity;
    // for (var i = 0; i < polylineCoordinates.length; i++) {
    //   double currentDistance = await locationHelper.distanceBetween(
    //     coordinate.latitude,
    //     coordinate.longitude,
    //     polylineCoordinates[i].latitude,
    //     polylineCoordinates[i].latitude,
    //   );
    //   if (currentDistance < minLatLngDistance) {
    //     index = i;
    //     minLatLngDistance = currentDistance;
    //   }
    // }
    // //Get sample duration of kml
    // int sampleDuration = xmlHelper.getSampleDuration();
    // print('index: $index');
    // videoPlayerController
    //     .seekTo(Duration(milliseconds: index * sampleDuration));
  }

  _videoPlayerListener() async {
    if (!mounted) return;
    //Get video timestamp
    Duration duration = await videoPlayerController.position;
    //Get sample duration of kml
    int sampleDuration = xmlHelper.getSampleDuration();
    //Calculate index
    int index = ((duration.inMilliseconds) / sampleDuration).floor();
    index = index >= coordinates.length ? coordinates.length - 1 : index;
    if (index == -1) return;
    //Set Marker
    Marker marker = getMarker(
      markerId: index.toString(),
      position: LatLng(coordinates[index][1], coordinates[index][0]),
    );
    //////////////////////////////////////////////////////////////
    ///Polyline
    //////////////////////////////////////////////////////////////
    polylineCoordinatesToBeCovered = polylineCoordinates.sublist(0, index + 1);
    polylineCoordinatesCovered = polylineCoordinates.sublist(index);
    // polylineCoordinates.removeWhere((element) =>
    //     element == LatLng(coordinates[index][1], coordinates[index][0]));
    // polylineCoordinatesCovered
    //     .add(LatLng(coordinates[index][1], coordinates[index][0]));
    //Pratik Set style for not covered same as above
    Polyline polyline = Polyline(
      polylineId: PolylineId("poly"),
      color: Color.fromARGB(255, 40, 122, 198),
      points: polylineCoordinatesToBeCovered,
    );
    //Pratik Set Style for covered
    Polyline polylineCovered = Polyline(
      polylineId: PolylineId("polyCovered"),
      color: Color.fromARGB(255, 0, 0, 0),
      points: polylineCoordinatesCovered,
    );
    if (!mounted) return;
    //Set polyline & markerint
    setState(() {
      _markers = {};
      _markers.add(marker);
      _polylines.clear();
      _polylines.add(polyline);
      _polylines.add(polylineCovered);
    });
    //print("Change in videoPlayer");
  }

  Marker getMarker({String markerId, LatLng position}) {
    //Pratik add styling here for marker
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
    );
  }

  addListenerToVideoPlayer() async {
    videoPlayerController.addListener(_videoPlayerListener);
  }

  @override
  void initState() {
    videoPlayerController = VideoPlayerController.file(widget.video.video);
    flickManager = FlickManager(
      videoPlayerController: videoPlayerController,
      autoPlay: true,
    );
    addListenerToVideoPlayer();

    //Old Code in case needed
    // _controller = VideoPlayerController.asset("assets/video/filler.mp4");

    // _initializeVideoPlayerFuture = _controller.initialize();

    // _controller.play();
    // _controller.setLooping(false);

    super.initState();
  }

  @override
  void dispose() {
    // _controller.dispose();
    videoPlayerController.removeListener(_videoPlayerListener);
    //videoPlayerController.dispose();
    flickManager.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Hero(
              tag: widget.video.thumbnail,
              child: FlickVideoPlayer(
                flickManager: flickManager,
              ),
            ),
            Container(
              height: 4,
              width: double.infinity,
              color: Styles.brightIndigo,
            ),
            Expanded(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                polylines: _polylines,
                markers: _markers,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 6.0,
                ),
                onTap: (argument) {
                  _googleMapOnTap(argument);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
