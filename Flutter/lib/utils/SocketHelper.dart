import 'dart:async';
import 'dart:convert';

import 'package:camera_with_rtmp/camera.dart';
import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:flutter_socket_io/socket_io_manager.dart';
import 'package:vidmapper/utils/LocationHelper.dart';
import '../models/globals.dart' as globals;

class SocketHelper {
  static startSendingCoordinates(
      {String streamKey, CameraController controller}) async {
    print('Function: startSendingCoordinates');
    //Helpers
    LocationHelper locationHelper = new LocationHelper();
    print('Socket reached here#1');
    //Socket
    SocketIO socket = new SocketIOManager().createSocketIO("${globals.ip}", "/",
        query: "stream_key=$streamKey", socketStatusCallback: _socketStatus);
    print('Socket reached here#2');
    socket.init();
    print('Socket reached here#3');
    socket.connect();
    print('Socket reached here#4');

    socket.sendMessage(
        'joinRoom', json.encode({'stream_key': streamKey}), _socketStatus);

    print('Socket reached here#5');
    new Timer.periodic(Duration(milliseconds: 1000), (timer) async {
      Map<String, dynamic> currentPosition =
          await locationHelper.getCurrentPosition(withLocationString: false);
      print('SocketHelper Timer $currentPosition');
      socket.sendMessage(
          'sendLocation',
          json.encode({
            'stream_key': streamKey,
            'latitude': currentPosition['latitude'],
            'longitude': currentPosition['longitude']
          }),
          _socketStatus);
      if (!controller.value.isStreamingVideoRtmp) {
        timer.cancel();
        socket.disconnect();
        socket.destroy();
      }
    });
  }

  static _socketStatus(dynamic data) {
    print('Socket: _socketStatus: $data');
  }
}
