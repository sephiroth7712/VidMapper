// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart' as cam;
import 'package:camera_with_rtmp/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:vidmapper/main.dart';
import 'package:vidmapper/utils/SharedPreferenceHelper.dart';
import 'package:vidmapper/utils/SocketHelper.dart';
import 'package:wakelock/wakelock.dart';

class CameraExampleHome extends StatefulWidget {
  @override
  _CameraExampleHomeState createState() {
    return _CameraExampleHomeState();
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class _CameraExampleHomeState extends State<CameraExampleHome>
    with WidgetsBindingObserver {
  CameraController controller;
  String imagePath;
  String videoPath;
  String url;
  VideoPlayerController videoController;
  VoidCallback videoPlayerListener;
  bool enableAudio = true;
  bool useOpenGL = true;
  TextEditingController _textFieldController =
      TextEditingController(text: "rtmp://159.65.145.166:1935/live/FHBN3rhGu");
  SharedPreferenceHelper sharedPreferenceHelper = new SharedPreferenceHelper();
  String streamKey;

  Timer _timer;

  @override
  void initState() {
    super.initState();
    onNewCameraSelected(cameras.first);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
      if (_timer != null) {
        _timer.cancel();
        _timer = null;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double _recordButtonBorderRadius = 24;
  double _recordButtonMargin = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            child: _cameraPreviewWidget(),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: controller != null && controller.value.isRecordingVideo
                    ? controller.value.isStreamingVideoRtmp
                        ? Colors.redAccent
                        : Colors.orangeAccent
                    : controller != null &&
                            controller.value.isStreamingVideoRtmp
                        ? Colors.greenAccent
                        : Colors.transparent,
                width: 5.0,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                      color: controller.value.isStreamingVideoRtmp
                          ? Colors.transparent
                          : Colors.black38),
                  Container(
                      height: 2,
                      width: double.infinity,
                      color: controller.value.isStreamingVideoRtmp
                          ? Colors.transparent
                          : Colors.white),
                  Spacer(),
                  Container(
                    alignment: Alignment.bottomCenter,
                    margin: EdgeInsets.only(top: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _recordButtonBorderRadius =
                              !controller.value.isStreamingVideoRtmp ? 0 : 24;
                          _recordButtonMargin =
                              !controller.value.isStreamingVideoRtmp ? 16 : 4;
                        });
                        onVideoStreamingButtonPressed();
                      },
                      onLongPress: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white,
                              width: 2,
                              style: BorderStyle.solid),
                        ),
                        child: Container(
                            child: AnimatedContainer(
                          margin: EdgeInsets.all(_recordButtonMargin),
                          duration: Duration(milliseconds: 500),
                          decoration: BoxDecoration(
                            //shape: BoxShape.circle,
                            borderRadius: BorderRadius.circular(
                                _recordButtonBorderRadius),
                            color: Colors.greenAccent,
                          ),
                        )),
                      ),
                    ),
                  ),
                  Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    //_scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: enableAudio,
      androidUseOpenGL: useOpenGL,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
        if (_timer != null) {
          _timer.cancel();
          _timer = null;
        }
        Wakelock.disable();
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onVideoStreamingButtonPressed() {
    if (controller != null &&
        controller.value.isInitialized &&
        !controller.value.isStreamingVideoRtmp) {
      startVideoStreaming().then((String url) {
        if (mounted) setState(() {});
        if (url != null) showInSnackBar('Streaming video to $url');
        Wakelock.enable();
      });
    } else {
      onStopButtonPressed();
    }
  }

  void onStopButtonPressed() {
    if (this.controller.value.isStreamingVideoRtmp) {
      stopVideoStreaming().then((_) {
        if (mounted) setState(() {});
        showInSnackBar('Video streamed to: $url');
      });
    }
    Wakelock.disable();
  }

  Future<String> startVideoStreaming() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (controller.value.isStreamingVideoRtmp) {
      return null;
    }

    await sharedPreferenceHelper.init();
    streamKey = sharedPreferenceHelper.getStreamKey();
    print('Stream key: $streamKey');

    // Open up a dialog for the url
    //backupKey of chaitanya's FHBN3rhGu
    //String myUrl = 'rtmp://159.65.145.166:1935/live/FHBN3rhGu';
    String myUrl = 'rtmp://159.65.145.166:1935/live/$streamKey';

    try {
      if (_timer != null) {
        _timer.cancel();
        _timer = null;
      }
      SocketHelper.startSendingCoordinates(
          streamKey: streamKey, controller: controller);
      await controller.startVideoStreaming(myUrl);

      // _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      //   var stats = await controller.getStreamStatistics();
      //   print(stats);
      // });
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return url;
  }

  Future<void> stopVideoStreaming() async {
    if (!controller.value.isStreamingVideoRtmp) {
      return null;
    }

    try {
      await controller.stopVideoStreaming();
      if (_timer != null) {
        _timer.cancel();
        _timer = null;
      }
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

class LiveStream extends StatefulWidget {
  List<cam.CameraDescription> cameras;
  LiveStream({this.cameras});
  @override
  _LiveStreamState createState() => _LiveStreamState();
}

class _LiveStreamState extends State<LiveStream> {
  @override
  void initState() {
    super.initState();
    CameraLensDirection _cameraLens;
    switch (widget.cameras.first.lensDirection) {
      case cam.CameraLensDirection.back:
        {
          _cameraLens = CameraLensDirection.back;
          break;
        }
      case cam.CameraLensDirection.front:
        {
          _cameraLens = CameraLensDirection.front;
          break;
        }
      case cam.CameraLensDirection.external:
        {
          _cameraLens = CameraLensDirection.external;
          break;
        }
    }
    cameras = [];
    cameras.add(CameraDescription(
      name: widget.cameras.first.name,
      lensDirection: _cameraLens,
      // sensorOrientation: 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return CameraExampleHome();
  }
}

List<CameraDescription> cameras = [];
