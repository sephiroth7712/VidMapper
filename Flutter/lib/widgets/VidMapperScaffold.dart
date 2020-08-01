import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/styles.dart';

class VidMapperScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> trailing;
  final Widget floatingActionButton;

  VidMapperScaffold(
      {@required this.title,
      @required this.body,
      this.trailing,
      this.floatingActionButton});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Styles.backgroundColor,
        appBar: AppBar(
          backgroundColor: Styles.appBarColor,
          shape: RoundedRectangleBorder(
            // side: BorderSide(
            //   width: 2,
            //   color: Colors.black,
            // ),
            borderRadius: BorderRadius.circular(8),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            color: Styles.backButtonColor,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            title,
            style: GoogleFonts.cabin(
              color: Styles.textColor,
              fontWeight: FontWeight.w500,
              fontSize: 24,
            ),
          ),
          actions: trailing,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: body,
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
