import 'dart:io';

import 'package:vidmapper/utils/SharedPreferenceHelper.dart';
import 'package:xml/xml.dart';

class XMLHelper {
  XmlDocument document;
  File kmlFile;

  XMLHelper({this.kmlFile});

  Future<void> initializeDocument() async {
    if (await kmlFile.exists()) {
      document = parse(await kmlFile.readAsString());
    }
  }

  List<List<double>> getCoordinatesFromXML() {
    if (document != null) {
      return document
          .findAllElements('Placemark')
          .first
          .findAllElements('LineString')
          .first
          .findAllElements('coordinates')
          .first
          .text
          .trim()
          .replaceAll('\n', '')
          .split(' ')
          .map((e) => e.split(',').map((e) => double.parse(e)).toList())
          .toList();
    }
    return [];
  }

  int getSampleDuration() {
    if (document != null) {
      return int.parse(document.findAllElements('SampleDuration').first.text);
    }
    return 1;
  }

  Future<String> getCreator() async {
    if (document != null) {
      try {
        print('Function: getCreator');
        SharedPreferenceHelper preferenceHelper = SharedPreferenceHelper();
        await preferenceHelper.init();
        String username = preferenceHelper.getUsername();
        String creator = document.findAllElements('Creator').first.text;
        if (username == creator) return 'you';
        return creator;
      } catch (e) {
        return 'N/A';
      }
    }
    return 'N/A';
  }
}
