import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
//import 'package:flutter_archive/flutter_archive.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  static void printDebug(String text) {
    if (true) print(text);
  }

  static Future<String> createKMZ(File video, File kml) async {
    final Directory extDir = await getExternalStorageDirectory();
    final String dirPath = '${extDir.path}/.kmz';
    await Directory(dirPath).create(recursive: true);
    final String kmzPath =
        '$dirPath/${basenameWithoutExtension(video.path)}.kmz';

    //Creating temp directory
    Directory files =
        await Directory('${extDir.path}/files').create(recursive: true);
    await video
        .copy('${files.path}/${basenameWithoutExtension(video.path)}.mp4');

    ZipFileEncoder encoder = ZipFileEncoder();
    encoder.create(kmzPath);
    //encoder.addFile(video);
    encoder.addDirectory(files);
    encoder.addFile(kml);
    encoder.close();

    //Delete that temp directory
    files.delete(recursive: true);

    return kmzPath;
  }

  static Future<void> imporKMZLocal() async {
    printDebug('FUnction: imporKMZLocal');
    //Get the kmz file
    File originalFile = await FilePicker.getFile(
        type: FileType.custom, allowedExtensions: ['kmz']);
    printDebug(originalFile.path);
    //Get the path to where the file has to be copied
    String copiedFilePath = await getKMZPath(originalFile.path);
    printDebug(copiedFilePath);
    //Copy the file
    File copiedFile = await originalFile.copy(copiedFilePath);
    printDebug(copiedFile.path);
    //Convert that file to mp4 & kml
    await importKMZ(copiedFile);
    return;
  }

  static Future<void> importKMZ(File kmzFile) async {
    printDebug('FUnction: imporKMZLocal');
    final String videoPath = await getVideoPath(kmzFile.path);
    printDebug(videoPath);
    final String kmlPath = await getKmlPath(kmzFile.path);
    printDebug(kmlPath);
    //Read the Zip file from disk.
    final bytes = await kmzFile.readAsBytes();
    //Decode the Zip file
    final archive = ZipDecoder().decodeBytes(bytes);
    // Extract the contents of the Zip archive to disk.
    for (final file in archive) {
      printDebug(file.name);
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        if (extension(filename) == '.mp4') {
          printDebug('is mp4');
          File(videoPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
        if (extension(filename) == '.kml') {
          printDebug('is kml');
          File(kmlPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }
    }
  }

  static Future<String> getKMZPath(String filePath) async {
    final Directory extDir = await getExternalStorageDirectory();
    await Directory('${extDir.path}/.kmz').create(recursive: true);
    return '${extDir.path}/.kmz/${basenameWithoutExtension(filePath)}.kmz';
  }

  static Future<String> getVideoPath(String filePath) async {
    final Directory extDir = await getExternalStorageDirectory();
    await Directory('${extDir.path}/Videos').create(recursive: true);
    return '${extDir.path}/Videos/${basenameWithoutExtension(filePath)}.mp4';
  }

  static Future<String> getKmlPath(String filePath) async {
    final Directory extDir = await getExternalStorageDirectory();
    await Directory('${extDir.path}/.kml').create(recursive: true);
    return '${extDir.path}/.kml/${basenameWithoutExtension(filePath)}.kml';
  }

  // static Future<String> createKMZ(File video, File kml) async {
  //   final Directory extDir = await getExternalStorageDirectory();
  //   final String dirPath = '${extDir.path}/.kmz';
  //   await Directory(dirPath).create(recursive: true);
  //   final String filePath =
  //       '$dirPath/${basenameWithoutExtension(video.path)}.kmz';
  //   final files = [video, kml];
  //   final zipFile = File(filePath);
  //   try {
  //     await ZipFile.createFromFiles(
  //         includeBaseDirectory: false,
  //         sourceDir: extDir,
  //         files: files,
  //         zipFile: zipFile);
  //     return filePath;
  //   } catch (e) {
  //     print(e);
  //   }
  //   return "";
  // }
}
