import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vidmapper/models/preferences.dart';

class SharedPreferenceHelper {
  SharedPreferences preferences;

  Future<void> init() async {
    preferences = await SharedPreferences.getInstance();
  }

  ResolutionPreset getResolution() {
    switch (Preferences.videoResolution.currentValue()) {
      case VideoResolution.V480p:
        return ResolutionPreset.medium;
      case VideoResolution.V720p:
        return ResolutionPreset.high;
      case VideoResolution.V1080p:
        return ResolutionPreset.veryHigh;
    }
    return ResolutionPreset.medium;
  }

  bool getRecordSound() {
    return Preferences.videoSound.currentValue() ==
        Preferences.videoSound.options[1];
    // return true;
  }

  int getDurationInMilliseconds() {
    switch (Preferences.locationSampleRate.currentValue()) {
      case LocationSampleRate.R100ms:
        return 100;
      case LocationSampleRate.R500ms:
        return 500;
      case LocationSampleRate.R1000ms:
        return 1000;
      case LocationSampleRate.R2000ms:
        return 2000;
      case LocationSampleRate.R5000ms:
        return 5000;
      case LocationSampleRate.R10000ms:
        return 10000;
    }
    return 1000;
  }

  //////////////////////////////////////////////////////////////////////////////////////////////
  //Signin Helpers
  Future<void> setUsernameAndToken(String username, String token) async {
    await preferences.setString('username', username);
    // await preferences.remove('toke');
    await preferences.setString('toke', token);
  }

  Future<void> setStreamKey(String streamKey) async {
    await preferences.setString('streamKey', streamKey);
  }

  String getStreamKey() {
    return preferences.getString('streamKey');
  }

  String getUsername() {
    return preferences.getString('username');
  }
}
