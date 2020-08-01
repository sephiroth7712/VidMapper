import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

//Video Settings
enum VideoResolution { V1080p, V720p, V480p }
enum VideoFramerate { V30fps, V60fps }
enum VideoSound { Mute, Record }

//Location Settings
enum LocationSampleRate { R100ms, R500ms, R1000ms, R2000ms, R5000ms, R10000ms }

//App Settings
enum VmAppTheme { MilkyWay, Planet, Night }

class Preference<T> {
  T defaultValue;
  final String title;
  final String description;
  final String hint;
  final List<T> options;

  Preference(
      {this.defaultValue,
      @required this.title,
      @required this.description,
      this.hint,
      @required this.options});

  get valueType => T;

  int _load() {
    //Returns the index INTEGER
    if (Preferences.sharedPreferences.containsKey(title)) {
      return Preferences.sharedPreferences.get(title);
    }
    save(defaultValue);
    return options.indexOf(defaultValue);
  }

  save(T value) {
    Preferences.sharedPreferences.setInt(title, options.indexOf(value));
  }

  T currentValue() {
    //Returns ENUM
    int currentIndex = _load();
    return options[currentIndex];
  }

  // @override
  // // String toString() => Preferences.name[value];
}

abstract class Preferences {
  static SharedPreferences sharedPreferences;

  static initializeSharedPreference() async {
    sharedPreferences = await SharedPreferences.getInstance();
    // sharedPreferences.clear();
  }

  static const Map<dynamic, String> name = {
    //Framerate
    VideoFramerate.V30fps: "30fps",
    VideoFramerate.V60fps: "60fps",

    //Resolution
    VideoResolution.V1080p: "Full HD, 1920×1080p",
    VideoResolution.V720p: "HD, 1280×720p",
    VideoResolution.V480p: "SD, 854×480p",

    //Video Sound
    VideoSound.Record: "Record",
    VideoSound.Mute: "Mute",

    //Location Sample Rate
    LocationSampleRate.R100ms: "100ms",
    LocationSampleRate.R500ms: "500ms",
    LocationSampleRate.R1000ms: "1000ms",
    LocationSampleRate.R2000ms: "2000ms",
    LocationSampleRate.R5000ms: "5000ms",
    LocationSampleRate.R10000ms: "10000ms",

    //App Theme
    VmAppTheme.Night: "Night",
    VmAppTheme.Planet: "Planet",
    VmAppTheme.MilkyWay: "Milky Way",
  };

  // static const Map<dynamic, int> value = {
  //   //Framerate
  //   VideoFramerate.V30fps: 0,
  //   VideoFramerate.V60fps: 1,

  //   //Resolution
  //   VideoResolution.V480p: 0,
  //   VideoResolution.V720p: 1,
  //   VideoResolution.V1080p: 2,

  //   //Video Sound
  //   VideoSound.Mute: 0,
  //   VideoSound.Record: 1,

  //   //App Theme
  //   VmAppTheme.Planet: 0,
  //   VmAppTheme.Night: 1,
  // };

  static Preference videoResolution = Preference<VideoResolution>(
      defaultValue: VideoResolution.V720p,
      title: "Resolution",
      description: "Choose the resolution the video will be recorded at.",
      hint: "Higher the resolution, higher the file size.",
      options: VideoResolution.values);

  static Preference videoFramerate = Preference<VideoFramerate>(
      defaultValue: VideoFramerate.V30fps,
      title: "Framerate",
      description: "Choose the framerate the video will be recorded at.",
      hint: "Higher the framerate, higher the file size.",
      options: VideoFramerate.values);

  static Preference videoSound = Preference<VideoSound>(
      defaultValue: VideoSound.Record,
      title: "Record Sound",
      description: "Toggle to enable or disable recording audio",
      options: VideoSound.values);

  static Preference locationSampleRate = Preference<LocationSampleRate>(
    defaultValue: LocationSampleRate.R1000ms,
    title: "Location Sample Rate",
    description: "Frequency at which your GPS coordinates are stored.",
    hint: "Increasing the sample rate will increase playback accuracy.",
    options: LocationSampleRate.values,
  );

  static Preference appTheme = Preference<VmAppTheme>(
      defaultValue: VmAppTheme.Planet,
      title: "Theme",
      description: "Choose the look which suits you the best.",
      hint: "On OLED and AMOLED screens, Night will preserve battery.",
      options: VmAppTheme.values);
}
