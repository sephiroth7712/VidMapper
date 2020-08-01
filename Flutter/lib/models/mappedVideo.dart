import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MappedVideo {
  final String location; //Location?
  final DateTime timeStamp; //Datetime
  final String fileSize; //Get from file
  final String duration; //Get from file
  final String resolution; //Get from file
  final String distance; //Calculate
  final File thumbnail;
  final File video;
  final File kml;
  final LatLng coordinate;
  final String creator;

  MappedVideo({
    this.location,
    this.timeStamp,
    this.fileSize,
    this.duration,
    this.resolution,
    this.distance,
    this.thumbnail,
    this.video,
    this.kml,
    this.coordinate,
    this.creator,
  });
}
