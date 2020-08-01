import 'dart:core';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vidmapper/models/preferences.dart';
import 'package:vidmapper/widgets/VidMapperScaffold.dart';

import 'models/styles.dart';

// ignore: must_be_immutable
class Settings extends StatefulWidget {
  // final Color videoColor = Colors.yellow;
  @override
  _SettingsState createState() => _SettingsState();
}

TextStyle settingTitleStyle = GoogleFonts.cabin(
    fontSize: 18, fontWeight: FontWeight.w400, color: Styles.textColor);

TextStyle settingSubtitleStyle = GoogleFonts.cabin(
    fontSize: 14, fontWeight: FontWeight.w300, color: Styles.subtitleColor);

TextStyle settingHeaderStyle = GoogleFonts.cabin(
    fontSize: 22, fontWeight: FontWeight.w600, color: Styles.textColor);

class _SettingsState extends State<Settings> {
  final Color videoHighlight = Colors.yellowAccent;

  final Color storageHighlight = Colors.greenAccent;

  @override
  Widget build(Object context) {
    return VidMapperScaffold(
      title: "Settings",
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: kToolbarHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              //THIS IS Video Settings
              SettingsSection(
                heading: "Video Settings",
                children: [
                  SettingsItem(
                    setting: Preferences.videoResolution,
                    icon: Icon(
                      Icons.image_aspect_ratio,
                      color: videoHighlight,
                    ),
                  ),
                  SettingsItem(
                    setting: Preferences.videoFramerate,
                    icon: Icon(
                      Icons.fiber_smart_record,
                      color: videoHighlight,
                    ),
                  ),
                  SettingsToggle(
                    icon: Icon(Icons.mic, color: videoHighlight),
                    setting: Preferences.videoSound,
                    color: videoHighlight,
                  ),
                ],
              ),
              SettingsSection(
                heading: "Location Settings",
                children: [
                  SettingsItem(
                    icon: Icon(
                      Icons.location_on,
                      color: Styles.accentColor,
                    ),
                    setting: Preferences.locationSampleRate,
                  ),
                ],
              ),

              //THIS IS App Settings
              SettingsSection(
                heading: "App Settings",
                children: [
                  SettingsItem(
                      setting: Preferences.appTheme,
                      icon: Icon(
                        Icons.image_aspect_ratio,
                        color: storageHighlight,
                      ),
                      callBack: () {
                        setState(() {
                          settingTitleStyle = settingTitleStyle
                              .merge(TextStyle(color: Styles.textColor));
                          settingSubtitleStyle = settingSubtitleStyle
                              .merge(TextStyle(color: Styles.subtitleColor));
                          settingHeaderStyle = settingHeaderStyle
                              .merge(TextStyle(color: Styles.textColor));
                        });
                      }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSection extends StatefulWidget {
  final String heading;
  final List<Widget> children;

  SettingsSection({@required this.heading, @required this.children});

  @override
  _SettingsSectionState createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 48),
        Text(widget.heading, style: settingHeaderStyle),
        SizedBox(
          height: 12,
        ),
        Container(
          height: 2,
          width: 169,
          color: Styles.accentColor,
          margin: EdgeInsets.only(bottom: 12),
        ),
        Column(
          children: widget.children,
        )
      ],
    );
  }
}

class SettingsItem extends StatefulWidget {
  final Icon icon;
  final Preference setting;
  final VoidCallback callBack;

  SettingsItem({@required this.icon, @required this.setting, this.callBack});

  @override
  _SettingsItemState createState() => _SettingsItemState();
}

class _SettingsItemState extends State<SettingsItem> {
  passToSettingsPicker(BuildContext context, Preference setting) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingPicker(setting: setting),
      ),
    );
    //To reflect change in setting value
    setState(() {});
    //To reflect change in theme, etc.
    if (widget.callBack != null) widget.callBack();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => passToSettingsPicker(context, widget.setting),
      child: ListTile(
        leading: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Styles.cardColor,
              // shape: BoxShape.circle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.icon),
        title: Text(widget.setting.title, style: settingTitleStyle),
        subtitle: Text(Preferences.name[widget.setting.currentValue()],
            style: settingSubtitleStyle),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }
}

class SettingsToggle extends StatefulWidget {
  final Icon icon;
  final Preference setting;
  final Color color;

  SettingsToggle({this.icon, this.color, this.setting});

  @override
  _SettingsToggleState createState() => _SettingsToggleState();
}

class _SettingsToggleState extends State<SettingsToggle> {
  bool _isEnabled;

  @override
  void initState() {
    _isEnabled = widget.setting.currentValue() == widget.setting.options[1];
    super.initState();
  }

  _toggleSwitch() {
    print("Bruh, textColor: " + Styles.textColor.toString());
    setState(() {
      _isEnabled = !_isEnabled;
      widget.setting.save(widget.setting.options[_isEnabled ? 1 : 0]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _toggleSwitch(),
      child: ListTile(
        leading: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Styles.cardColor,
              // shape: BoxShape.circle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.icon),
        title: Text(widget.setting.title, style: settingTitleStyle),
        subtitle: Text(Preferences.name[widget.setting.currentValue()],
            style: settingSubtitleStyle),
        trailing: Switch(
          activeColor: widget.color,
          value: _isEnabled,
          onChanged: (bool value) => _toggleSwitch(),
        ),
      ),
    );
  }
}

class SettingPicker extends StatefulWidget {
  final Preference setting;

  SettingPicker({this.setting});

  @override
  _SettingPickerState createState() => _SettingPickerState();
}

class _SettingPickerState extends State<SettingPicker> {
  var _currentPref;
  @override
  void initState() {
    super.initState();
    _currentPref = widget.setting.currentValue(); //Enum
  }

  @override
  Widget build(BuildContext context) {
    return VidMapperScaffold(
      title: widget.setting.title,
      body: Padding(
        padding: const EdgeInsets.only(top: kToolbarHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 30),
            Text(
              widget.setting.description,
              style: GoogleFonts.cabin(fontSize: 20, color: Styles.textColor),
            ),
            SizedBox(height: 10),
            Text(
              widget.setting.hint,
              style: GoogleFonts.cabin(fontSize: 12, color: Styles.textColor),
            ),
            SizedBox(height: 50),
            Column(
              children: widget.setting.options
                  .map(
                    (option) => RadioListTile(
                        activeColor: Styles.accentColor,
                        title: Text(
                          Preferences.name[option],
                          style: GoogleFonts.cabin(color: Styles.textColor),
                        ),
                        value: option,
                        groupValue: _currentPref,
                        onChanged: (value) {
                          setState(() {
                            widget.setting.save(value);
                            _currentPref = value;
                            // print("Bruh, type: " + widget.setting.valueType.toString());
                            if (widget.setting.valueType == VmAppTheme)
                              Styles.updateTheme(value);
                          });
                        }),
                  )
                  .toList(),
            ),
            Spacer(),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 200,
                height: 50,
                child: RaisedButton(
                  color: Styles.brightIndigo,
                  onPressed: () => Navigator.pop(context, _currentPref),
                  child: Text(
                    "Done",
                    style: GoogleFonts.cabin(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: kBottomNavigationBarHeight),
          ],
        ),
      ),
    );
  }
}
