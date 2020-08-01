import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vidmapper/models/styles.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final int splashDuration = 2;

  Future<bool> getUsername() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.containsKey('username') &&
        preferences.containsKey('streamKey');
  }

  routeUser() async {
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (await getUsername()) {
        print('pushing home');
        Navigator.of(context).pushReplacementNamed('/Home');
      } else {
        print('pushing signin');
        Navigator.of(context).pushReplacementNamed('/Signin');
      }
    });
  }

  @override
  void initState() {
    routeUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    // var drawer = Drawer();

    return Scaffold(
      // drawer: drawer,
      backgroundColor: Color(0xFF262645),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
          ),
          Spacer(),
          SizedBox(
            height: 150,
            child: Image.asset("assets/icon/icon.png"),
          ),
          Spacer(),
          Container(
            margin: EdgeInsets.only(bottom: 100),
            child: Text(
              "VidMapper",
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  .merge(TextStyle(fontSize: 50)),
            ),
          ),
        ],
      ),
      // body: Container(
      //   child: Column(
      //     children: <Widget>[
      //       Expanded(
      //         child: Container(
      //           alignment: FractionalOffset(0.5, 0.3),
      //           child: Text(
      //             "VidMapper",
      //             style: Theme.of(context)
      //                 .textTheme
      //                 .headline1
      //                 .merge(TextStyle(color: Theme.of(context).primaryColor)),
      //           ),
      //         ),
      //       ),
      //       Container(
      //         margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 30.0),
      //         child: Text(
      //           "© Copyright Statement 2019",
      //           style: Theme.of(context).textTheme.caption,
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
