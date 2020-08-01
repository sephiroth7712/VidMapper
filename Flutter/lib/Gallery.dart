import 'dart:io';

// import 'package:downloads_path_provider/downloads_path_provider.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:intent/action.dart';
// import 'package:intent/flag.dart';
// import 'package:intent/intent.dart' as android_intent;
// import 'package:intent/action.dart' as android_intent;
import 'package:flutter_share/flutter_share.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:intent/intent.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:vidmapper/models/mappedVideo.dart';
import 'package:vidmapper/utils/FileHelper.dart';
import 'package:vidmapper/utils/FilterHelper.dart';
import 'package:vidmapper/utils/LocationHelper.dart';
import 'package:vidmapper/utils/XMLHelper.dart';
import 'package:vidmapper/widgets/VidMapperScaffold.dart';
import 'package:xml/xml.dart';

import 'PlayScreen.dart';
import 'models/styles.dart';
import 'widgets/LabelledIcon.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_utils/utils.dart';

class Gallery extends StatefulWidget {
  @override
  _GalleryState createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  Future<List<MappedVideo>> futureFiles;
  LocationHelper locationHelper = new LocationHelper();

  Future<List<MappedVideo>> getListofFiles() async {
    List<MappedVideo> videoList = new List<MappedVideo>();

    final Directory root = await getExternalStorageDirectory();
    List<FileSystemEntity> files;
    try {
      files = await listFiles(root.path + "/Videos", extensions: ['mp4']);
    } catch (e) {
      return [];
    }
    String _location, _duration, _resolution, _fileSize, _distance, _creator;
    DateTime _timestamp;
    File _thumbnail, _video, _kml;
    LatLng _coordinate;

    for (FileSystemEntity file in files) {
      FileStat fileStat = await file.stat();
      XMLHelper xmlHelper = new XMLHelper(
          kmlFile: new File(
              '${root.path}/.kml/${basenameWithoutExtension(file.path)}.kml'));
      await xmlHelper.initializeDocument();
      FlutterFFprobe flutterFFprobe = new FlutterFFprobe();
      FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();
      Map<dynamic, dynamic> mediaInformation =
          await flutterFFprobe.getMediaInformation(file.path);
      try {
        _video = new File(file.path);
        _kml = new File(
            '${root.path}/.kml/${basenameWithoutExtension(file.path)}.kml');

        _timestamp = fileStat.changed;
        _fileSize = (fileStat.size / 1000000).toStringAsFixed(2) + " MiB";
        _duration = _printDuration(
            Duration(seconds: (mediaInformation['duration'] / 1000).round()));
        _thumbnail = await _getThumbnail(
            flutterFFmpeg: _flutterFFmpeg, file: file, root: root);
        _resolution = _getResolution(
            mediaInformation: mediaInformation, flutterFFmpeg: _flutterFFmpeg);
        _location = await _getLocation(kmlFile: _kml);
        _distance = await _getDistance(xmlHelper: xmlHelper);
        _coordinate = await _getCoordinate(xmlHelper: xmlHelper);
        _creator = await _getCreator(xmlHelper: xmlHelper);

        videoList.insert(
          0,
          MappedVideo(
            location: _location,
            duration: _duration,
            resolution: _resolution,
            fileSize: _fileSize,
            timeStamp: _timestamp,
            distance: _distance,
            thumbnail: _thumbnail,
            video: _video,
            kml: _kml,
            coordinate: _coordinate,
            creator: _creator,
          ),
        );
      } catch (e) {
        print(e);
        //throw (e);
      }
    }
    return videoList;
  }

  Future<String> _getCreator({XMLHelper xmlHelper}) async {
    return await xmlHelper.getCreator();
  }

  Future<LatLng> _getCoordinate({XMLHelper xmlHelper}) async {
    List<List<double>> coordinates = xmlHelper.getCoordinatesFromXML();
    return LatLng(coordinates.first[1], coordinates.first[0]);
  }

  Future<String> _getDistance({XMLHelper xmlHelper}) async {
    List<List<double>> coordinates = xmlHelper.getCoordinatesFromXML();
    //print('coordinates: $coordinates');
    double totalDistance = 0.0;
    for (var i = 0; i < coordinates.length - 1; i++) {
      totalDistance += await locationHelper.distanceBetween(
        coordinates[i][1],
        coordinates[i][0],
        coordinates[i + 1][1],
        coordinates[i + 1][0],
      );
    }
    return totalDistance < 1000
        ? (totalDistance).toStringAsFixed(2) + ' m'
        : (totalDistance / 1000).toStringAsFixed(2) + ' km';
  }

  Future<String> _getLocation({File kmlFile}) async {
    if (await kmlFile.exists()) {
      String kmlFileString = await kmlFile.readAsString();
      XmlDocument document = parse(kmlFileString);
      // document.descendants
      //     .where((node) => node is XmlText && !node.text.trim().isEmpty);
      return document
          .findAllElements('Placemark')
          .first
          .findAllElements('name')
          .first
          .text;
    }
    return "N/A";
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<File> _getThumbnail({
    FlutterFFmpeg flutterFFmpeg,
    FileSystemEntity file,
    Directory root,
  }) async {
    String thumbnailPath =
        "${root.path}/.thumbnails/${basenameWithoutExtension(file.path)}.png";

    //If thumbnail exists
    if (await File(thumbnailPath).exists()) {
      return new File(thumbnailPath);
    }
    //Thumbnail does not exit
    //Create a thumbnail
    int rc = await flutterFFmpeg
        .execute("-i ${file.path} -ss 00:00:01.000 -vframes 1 $thumbnailPath");
    //If FFMPEG failed to create thumbnail
    if (rc == -1) return null;
    //Finally return thumbnail
    return new File(thumbnailPath);
  }

  String _getResolution(
      {Map<dynamic, dynamic> mediaInformation, FlutterFFmpeg flutterFFmpeg}) {
    if (mediaInformation['streams'] != null) {
      for (var streamInformation in mediaInformation['streams']) {
        if (streamInformation['type'] == 'video' &&
            streamInformation['realFrameRate'] != null) {
          // if (streamInformation['metadata']['rotate'] != null &&
          //     streamInformation['metadata']['rotate'] == '180') {
          //   //print('CALDEN');
          //   rotateVideo(flutterFFmpeg, mediaInformation['path']);
          // }
          return streamInformation['height'].toString() +
              'p' +
              streamInformation['realFrameRate'];
          // return streamInformation['metadata']['rotate'] == null
          //     ? ''
          //     : streamInformation['metadata']['rotate'];
        }
      }
    }
    return 'N/A';
  }

  rotateVideo(FlutterFFmpeg _flutterFFmpeg, String videoPath) async {
    final String looselessConversion =
        '-i $videoPath -c copy -metadata:s:v:0 rotate=0 $videoPath.mp4';
    // final String looselessConversion =
    //     '-i $videoPath -vf "transpose=2,transpose=2" $videoPath.mp4';

    try {
      final int returnCode = await _flutterFFmpeg.execute(looselessConversion);

      if (returnCode == 0) {
        await File('$videoPath').delete();
        await File('$videoPath.mp4').rename(videoPath);
      } else {
        throw Exception('Could not rotate');
      }
    } catch (e) {
      print('video processing error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    print("Init Gallery");
    futureFiles = getListofFiles();
  }

  @override
  Widget build(Object context) {
    exportMappedVideo(MappedVideo video) async {
      String zmlPath = await FileHelper.createKMZ(video.video, video.kml);
      await FlutterShare.shareFile(
        title: 'VidMapper',
        text: 'Hey, Check out this amazing file I created using VidMapper',
        filePath: zmlPath,
      );

      // Directory downloadsDirectory = await DownloadsPathProvider.downloadsDirectory;
      // File abc = await video.kml.copy('${downloadsDirectory.path}/abc.kml');

      // android_intent.Intent()
      //   ..setAction(android_intent.Action.ACTION_EDIT)
      //   ..setData(Uri.file(video.kml.path))
      //..addFlag(Flag.FLAG_ACTIVITY_NEW_TASK)
      //..setType('application/vnd. google-earth.kml+xml')
      //..setPackage('com.google.earth')
      // ..startActivity().catchError((e) => print(e));
      // final AndroidIntent intent = AndroidIntent(
      //   action: 'action_view',
      //   data: Uri.file(video.kml.path).toString(),
      //   package: 'com.google.earth',

      // );
      // final AndroidIntent intent = AndroidIntent(
      //     action: 'action_view',
      //     data: Uri.encodeFull('google.streetview:cbll=46.414382,10.013988'),
      //     package: 'com.google.android.apps.maps');
      // intent.launch();
    }

    deleteMappedVideo(MappedVideo video, List<MappedVideo> snapshot) {
      File(video.video.path).delete();
      File(video.kml.path).delete();
      File(video.thumbnail.path).delete();
      setState(() {
        snapshot
            .removeWhere((element) => element.video.path == video.video.path);
      });
    }

    infoMappedVideo(MappedVideo video) {
      //TODO: Implement
    }

    goToPlayScreen(BuildContext context, MappedVideo currentVideo) {
      print("object");
      Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (context) => new PlayScreen(
            video: currentVideo,
          ),
        ),
      );
    }

    _floatingActionButtonPressed() async {
      await FileHelper.imporKMZLocal();
      print('done!');
      setState(() {
        futureFiles = getListofFiles();
      });
    }

    return VidMapperScaffold(
      title: "Gallery",
      trailing: <Widget>[
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: Styles.backgroundColor,
          ),
          onPressed: null,
        )
      ],
      body: FutureBuilder(
          future: futureFiles,
          builder: (context, AsyncSnapshot<List<MappedVideo>> snapshot) {
            if (snapshot.hasData) {
              List<MappedVideo> filteredList =
                  FilterHelper.applyFiltersAndSort(snapshot.data,
                      //coordinate: LatLng(0, 0),
                      coordinate: null,
                      byDateTime: false);
              return ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  MappedVideo currentVideo = filteredList.elementAt(index);

                  const int MENU_EXPORT = 1;
                  const int MENU_DELETE = 2;
                  const int MENU_MOREINFO = 3;

                  final double paddingAdjustment = 28;

                  final double iconSize = 18;
                  final TextStyle iconTextStyle = GoogleFonts.cabin(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Colors.white60,
                  );

                  final double menuIconSize = 16;
                  final TextStyle menuTextStyle = GoogleFonts.cabin(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  );

                  return Container(
                    margin: EdgeInsets.only(top: 20),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: <Widget>[
                        //THIS IS Card
                        Container(
                          margin: EdgeInsets.only(
                              left: 54, right: 0, top: 0, bottom: 0),
                          padding: EdgeInsets.only(left: 12, bottom: 18),
                          decoration: BoxDecoration(
                              color: Styles.cardColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 16,
                                  color: Colors.black26,
                                  spreadRadius: 0,
                                )
                              ]),
                          child: InkWell(
                            onTap: () => goToPlayScreen(context, currentVideo),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                ListTile(
                                  contentPadding: EdgeInsets.only(
                                      left: paddingAdjustment, right: 8),
                                  title: Text(
                                    currentVideo.location,
                                    style: GoogleFonts.cabin(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: <Widget>[
                                      Text(
                                        DateFormat.jm()
                                            .add_yMd()
                                            .format(currentVideo.timeStamp),
                                        style: GoogleFonts.cabin(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                      Spacer(),
                                      LabelledIcon(
                                        icon: Icon(
                                          Icons.location_on,
                                          color: Styles.accentColor,
                                          size: iconSize,
                                        ),
                                        label: Text(currentVideo.distance,
                                            style: iconTextStyle),
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Colors.white70,
                                    ),
                                    padding: EdgeInsets.all(0),
                                    color: Styles.backgroundColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Styles.accentColor,
                                          width: 1,
                                        )),
                                    onSelected: (value) {
                                      switch (value) {
                                        case MENU_EXPORT:
                                          exportMappedVideo(currentVideo);
                                          break;
                                        case MENU_DELETE:
                                          deleteMappedVideo(
                                              currentVideo, snapshot.data);
                                          break;
                                        case MENU_MOREINFO:
                                          infoMappedVideo(currentVideo);
                                          break;
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      PopupMenuItem(
                                        value: MENU_EXPORT,
                                        child: LabelledIcon(
                                          icon: Icon(
                                            Icons.share,
                                            size: menuIconSize,
                                            color: Colors.cyan,
                                          ),
                                          label: Text("Share/Export",
                                              style: menuTextStyle),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: MENU_DELETE,
                                        child: LabelledIcon(
                                          icon: Icon(
                                            Icons.delete,
                                            size: menuIconSize,
                                            color: Colors.blueGrey,
                                          ),
                                          label: Text("Delete",
                                              style: menuTextStyle),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        child: LabelledIcon(
                                          icon: Icon(
                                            Icons.info_outline,
                                            color: Colors.white,
                                            size: menuIconSize,
                                          ),
                                          label: Text(
                                            "More info",
                                            style: menuTextStyle,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 2,
                                  width: 64,
                                  margin:
                                      EdgeInsets.only(left: paddingAdjustment),
                                  color: Styles.accentColor,
                                ),
                                SizedBox(
                                  height: 12,
                                ),
                                Container(
                                  padding: EdgeInsets.only(
                                      left: paddingAdjustment,
                                      right: paddingAdjustment),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      LabelledIcon(
                                        icon: Icon(
                                          Icons.timer,
                                          size: iconSize,
                                          color: Colors.lightBlueAccent,
                                        ),
                                        label: Text(
                                          currentVideo.duration,
                                          style: iconTextStyle,
                                        ),
                                      ),
                                      LabelledIcon(
                                        icon: Icon(
                                          Icons.storage,
                                          size: iconSize,
                                          color: Colors.greenAccent,
                                        ),
                                        label: Text(
                                          currentVideo.fileSize,
                                          style: iconTextStyle,
                                        ),
                                      ),
                                      LabelledIcon(
                                        icon: Icon(
                                          Icons.image_aspect_ratio,
                                          color: Colors.yellowAccent,
                                          size: iconSize,
                                        ),
                                        label: Text(
                                          currentVideo.resolution,
                                          style: iconTextStyle,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                            onTap: () => goToPlayScreen(context, currentVideo),
                            child: Hero(
                              tag: currentVideo.thumbnail,
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: FileImage(currentVideo.thumbnail),
                                      fit: BoxFit.cover),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    width: 2,
                                    color: Styles.accentColor,
                                  ),
                                ),
                              ),
                            ))
                      ],
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              print(snapshot.error);
              throw (snapshot.error);
              //return Container();
            } else {
              return Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              );
            }
          }),
      floatingActionButton: FloatingActionButton(
          onPressed: _floatingActionButtonPressed, child: Icon(Icons.add)),
    );
  }
}
