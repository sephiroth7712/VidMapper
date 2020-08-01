import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as locationPac;

class GoogleMapWidget extends StatefulWidget {
  final Function updateAlignment;
  final double widthWidget;
  final double heightWidget;
  GoogleMapWidget({
    this.updateAlignment,
    this.widthWidget = 132,
    this.heightWidget = 180,
  });
  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<GoogleMapWidget> {
  Completer<GoogleMapController> _controller = Completer();
  Future<LatLng> futureLatLng;

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);
    final GoogleMapController mapController = await _controller.future;
    locationPac.Location location = new locationPac.Location();
    location.onLocationChanged().listen((locationPac.LocationData cLoc) {
      print('Location changed $cLoc');
      setState(() {
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(cLoc.latitude, cLoc.longitude),
              zoom: 17,
            ),
          ),
        );
      });
    });
  }

  Future<LatLng> getCurrentPosition() async {
    Geolocator geolocator = Geolocator();
    Position position = await geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemark = await geolocator.placemarkFromCoordinates(
        position.latitude, position.longitude);
    Map<String, dynamic> placemarkJson = placemark[0].toJson();
    String placemarkString =
        placemarkJson["subLocality"] + ", " + placemarkJson["locality"];
    print(position);
    print(placemarkString);
    return LatLng(position.latitude, position.longitude);
  }

  Widget mapWidget(dynamic snapshot) {
    return Container(
      width: widget.widthWidget,
      height: widget.heightWidget,
      child: GoogleMap(
        mapType: MapType.normal,
        buildingsEnabled: false,
        //liteModeEnabled: true,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        onMapCreated: _onMapCreated,
        zoomControlsEnabled: false,
        // onCameraMove: _onCameraMove,
        // onCameraIdle: _onCameraIdle,
        initialCameraPosition: CameraPosition(
          target: snapshot.data,
          zoom: 17.0,
        ),
      ),
    );
  }

  void _onDraggableCanceled(Velocity velocity, Offset offset) {
    print(velocity);
    print(offset);
    Alignment _alignment;
    print(offset.dx);
    print(MediaQuery.of(context).size.width);
    if (offset.dx < MediaQuery.of(context).size.width / 2) {
      if (offset.dy < MediaQuery.of(context).size.height / 3)
        _alignment = Alignment.topLeft;
      else
        _alignment = Alignment.centerLeft;
    } else {
      if (offset.dy < MediaQuery.of(context).size.height / 3)
        _alignment = Alignment.topRight;
      else
        _alignment = Alignment.centerRight;
    }
    widget.updateAlignment(_alignment);
  }

  @override
  void initState() {
    futureLatLng = getCurrentPosition();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.widthWidget,
      height: widget.heightWidget,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 36),
      child: FutureBuilder(
        future: futureLatLng,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Widget _googleMap = mapWidget(snapshot);

            return Draggable(
              child: _googleMap,
              feedback: _googleMap,
              childWhenDragging: Container(),
              onDraggableCanceled: _onDraggableCanceled,
            );
          } else {
            return Align(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
