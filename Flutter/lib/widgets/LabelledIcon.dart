import 'package:flutter/material.dart';

class LabelledIcon extends StatelessWidget {
  final Icon icon;
  final Text label;

  LabelledIcon({@required this.icon, @required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        icon,
        SizedBox(width: 4),
        label,
      ],
    );
  }
}
