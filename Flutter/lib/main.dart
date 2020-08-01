import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission/permission.dart';
import 'package:vidmapper/Signin.dart';
import 'package:vidmapper/livestream.dart';
import 'package:vidmapper/splashscreen.dart';
import 'package:vidmapper/utils/LocationHelper.dart';
import 'package:vidmapper/utils/SharedPreferenceHelper.dart';
import 'package:vidmapper/widgets/LabelledIcon.dart';
import 'package:xml/xml.dart';

import 'Gallery.dart';
import 'Settings.dart';
import 'map.dart';
import 'models/preferences.dart';
import 'models/styles.dart';

class CameraHome extends StatefulWidget {
  @override
  _CameraHomeState createState() {
    return _CameraHomeState();
  }
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class _CameraHomeState extends State<CameraHome> with WidgetsBindingObserver {
  CameraController controller;
  String imagePath;
  String videoPath;
  //VideoPlayerController videoController;
  VoidCallback videoPlayerListener;
  bool enableAudio = true;
  Alignment _mapAlignment;
  bool isRecording;
  LocationHelper locationHelper = new LocationHelper();
  SharedPreferenceHelper sharedPreferenceHelper = new SharedPreferenceHelper();
  Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    //Stopwatch for recording video
    _stopwatch = Stopwatch();
    _isRecording = false;
    _recordButtonBorderRadius = 24;
    _recordButtonMargin = 4;
    //For rotation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _mapAlignment = Alignment.topLeft;
    onNewCameraSelected(cameras.first);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _isRecording = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _isRecording = false;
      _recordButtonBorderRadius = 24;
      _recordButtonMargin = 4;
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      print(AppLifecycleState.resumed);
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  goToSettings(BuildContext context) async {
    await controller?.dispose();
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => new Settings(),
      ),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        onNewCameraSelected(cameras.first);
      });
    });
  }

  // goToDebug(BuildContext context) {
  //   print("object");
  //   Navigator.push(
  //     context,
  //     new MaterialPageRoute(
  //       builder: (context) => new SettingsDebug(),
  //     ),
  //   );
  // }

  goToGallery(BuildContext context) async {
    await controller?.dispose();
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => new Gallery(),
      ),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        onNewCameraSelected(cameras.first);
      });
    });
  }

  changePositionOfMap(Alignment _alignment) {
    setState(() {
      _mapAlignment = _alignment;
    });
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  double _recordButtonBorderRadius = 24;
  double _recordButtonMargin = 4;

  @override
  Widget build(BuildContext context) {
    //For fullscreen
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);

    double _iconSize = 36;

    print("Building main.dart");
    print(controller);
    // if(controller == null){
    //   onNewCameraSelected(controller.description);
    // }

    return Scaffold(
      backgroundColor: Colors.black,
      key: _scaffoldKey,
      body: Stack(
        children: <Widget>[
          Align(alignment: Alignment.topCenter, child: _cameraPreviewWidget()),
          Positioned(
              right: 0,
              top: MediaQuery.of(context).size.height / 2 - 60,
              child: controller.value.isRecordingVideo
                  ? Transform.rotate(
                      angle: pi / 2,
                      child: LabelledIcon(
                          icon: Icon(
                            Icons.fiber_manual_record,
                            color: Colors.red,
                          ),
                          label: Text(
                              _printDuration(Duration(
                                  milliseconds:
                                      _stopwatch.elapsedMilliseconds)),
                              style: GoogleFonts.cabin(
                                  fontSize: 15, color: Colors.white))),
                    )
                  : Container()),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: controller.value.isRecordingVideo
                  ? Colors.transparent
                  : Colors.black38,
              height: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                      height: 2,
                      width: double.infinity,
                      color: controller.value.isRecordingVideo
                          ? Colors.transparent
                          : Colors.white),
                  Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.bottomLeft,
                        child: controller.value.isRecordingVideo
                            ? Container(width: 0, height: 0)
                            : IconButton(
                                iconSize: _iconSize,
                                icon: Icon(Icons.photo),
                                onPressed: () => goToGallery(context),
                              ),
                      ),
                      Container(
                        alignment: Alignment.bottomCenter,
                        margin: EdgeInsets.only(top: 10),
                        child: GestureDetector(
                          onTap: () {
                            _isRecording = !_isRecording;

                            setState(() {
                              _recordButtonBorderRadius = _isRecording ? 0 : 24;
                              _recordButtonMargin = _isRecording ? 16 : 4;
                            });
                            onVideoRecordButtonPressed();
                          },
                          onLongPress: () async {
                            await Navigator.push(
                              context,
                              new MaterialPageRoute(
                                builder: (context) => new LiveStream(
                                  cameras: cameras,
                                ),
                              ),
                            );
                            // .then((_) {
                            //   Future.delayed(
                            //       const Duration(milliseconds: 500), () {
                            //     onNewCameraSelected(cameras.first);
                            //   });
                            // });
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
                                color: Colors.red,
                              ),
                            )),
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.bottomRight,
                        child: controller.value.isRecordingVideo
                            ? Container(width: 0, height: 0)
                            : IconButton(
                                iconSize: _iconSize,
                                icon: Icon(Icons.settings),
                                onPressed: () => goToSettings(context),
                              ),
                      ),
                    ],
                  ),
                  Spacer(),
                ],
              ),
            ),
          ),
          Align(
            alignment: _mapAlignment,
            child: GoogleMapWidget(
              updateAlignment: changePositionOfMap,
            ),
          )
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Could not initialize Camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        //aspectRatio: controller.value.aspectRatio,
        aspectRatio: 9 / 16,
        child: CameraPreview(controller),
      );
    }
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    //_scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    print("Function: onNewCameraSelected");
    await sharedPreferenceHelper.init();

    if (controller != null) {
      print("controller is not null");
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      sharedPreferenceHelper.getResolution(),
      enableAudio: sharedPreferenceHelper.getRecordSound(),
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      print("Hello");
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
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

  void onVideoRecordButtonPressed() {
    if (controller != null &&
        controller.value.isInitialized &&
        !controller.value.isRecordingVideo) {
      startVideoRecording().then((String filePath) {
        if (mounted) setState(() {});
        if (filePath != null) showInSnackBar('Saving video to $filePath');
      });
    } else {
      onStopButtonPressed();
    }
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recorded to: $videoPath');
    });
    //Wakelock.disable();
  }

  Future<String> startVideoRecording() async {
    startStopwatch();
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    final Directory extDir = await getExternalStorageDirectory();
    final String dirPath = '${extDir.path}/Videos';
    await Directory(dirPath).create(recursive: true);
    await Directory('${extDir.path}/.thumbnails').create(recursive: true);
    await Directory('${extDir.path}/.kml').create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';

    if (controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    String kmlFilePath =
        '${extDir.path}/.kml/${basenameWithoutExtension(filePath)}.kml';

    try {
      videoPath = filePath;
      await controller.startVideoRecording(filePath);
      await startSavingCoordinates(kmlFilePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  startStopwatch() {
    _stopwatch.start();
    new Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        // _elapsedTime = _stopwatch.elapsedMilliseconds;
      });
    });
  }

  startSavingCoordinates(String kmlFilePath) async {
    final file = File(kmlFilePath);
    int intDuration = sharedPreferenceHelper.getDurationInMilliseconds();
    String username = sharedPreferenceHelper.getUsername();
    Duration duration = Duration(milliseconds: intDuration);
    List<String> coordinates = List<String>();
    String location = (await locationHelper.getCurrentPosition(
        withLocationString: true))['location'];

    new Timer.periodic(duration, (timer) async {
      Map<String, dynamic> currentPosition =
          await locationHelper.getCurrentPosition(withLocationString: false);

      coordinates.add([
        currentPosition['longitude'],
        currentPosition['latitude'],
        currentPosition['altitude']
      ].join(','));

      //Stop grabing location and write to file, since recording stopped.
      if (!controller.value.isRecordingVideo) {
        timer.cancel();
        String kmlFilString = createKMLFileString(
          basenameWithoutExtension(kmlFilePath),
          coordinates.join(' '),
          location,
          intDuration,
          username,
        );
        return file.writeAsStringSync(kmlFilString, flush: true);
      }
    });
  }

  String createKMLFileString(String title, String coordinates, String location,
      int sampleDuration, String username) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('kml', attributes: {
      'xmlns': 'http://www.opengis.net/kml/2.2,',
      'xmlns:gx': 'http://www.google.com/kml/ext/2.2',
      'xmlns:kml': 'http://www.opengis.net/kml/2.2',
      'xmlns:atom': 'http://www.w3.org/2005/Atom'
    }, nest: () {
      builder.element('Document', nest: () {
        builder.element('name', nest: () {
          builder.text(title);
        });
        builder.element('SampleDuration', nest: () {
          builder.text(sampleDuration.toString());
        });
        builder.element('Creator', nest: () {
          builder.text(username);
        });
        builder.element('Placemark', nest: () {
          builder.element('name', nest: () {
            builder.text(location);
          });
          builder.element('LineString', nest: () {
            builder.element('coordinates', nest: () {
              builder.text(coordinates);
            });
          });
        });
      });
    });

    return builder.build().toXmlString(pretty: true, indent: '\t');
  }

  Future<void> stopVideoRecording() async {
    _stopwatch.stop();
    _stopwatch.reset();
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }

    //await _startVideoPlayer();
  }

  Future<void> resumeVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.resumeVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

List<CameraDescription> cameras = [];

checkPermissions() async {
  List<PermissionName> permissionNames = [
    PermissionName.Location,
    PermissionName.Camera,
    PermissionName.Storage,
    PermissionName.Internet,
    PermissionName.Microphone,
  ];
  await Permission.requestPermissions(permissionNames);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preferences.initializeSharedPreference();
  await checkPermissions();

  //Initialize Theme
  await Styles.updateTheme(Preferences.appTheme.currentValue());
  // Fetch the available cameras before initializing the app.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }

  runApp(
    MaterialApp(
      title: 'VidMapper',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        primaryColor: Color(0xFF42446E),
        backgroundColor: Color(0xFF262645),
        accentColor: Color(0xFFeb4034),
        // cardColor: Color(0xFF383a5e),
        cardColor: Color(0xFF2f3152),
        // dividerColor: Color(0xFF262645),

        // disabledColor: Color(0),
        buttonColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white, opacity: 1),
      ),
      home: SplashScreen(),
      routes: <String, WidgetBuilder>{
        "/Signin": (BuildContext context) => Signin(),
        "/Home": (BuildContext context) => CameraHome()
      },
    ),
  );
}
