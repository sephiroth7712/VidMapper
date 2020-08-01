import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        Navigator.of(context).pushNamed('/Home');
      } else {
        print('pushing signin');
        Navigator.of(context).pushNamed('/Signin');
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
    var drawer = Drawer();

    return Scaffold(
      drawer: drawer,
      body: Container(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                alignment: FractionalOffset(0.5, 0.3),
                child: Text(
                  "VidMapper",
                  style: Theme.of(context)
                      .textTheme
                      .headline1
                      .merge(TextStyle(color: Theme.of(context).primaryColor)),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 30.0),
              child: Text(
                "© Copyright Statement 2019",
                style: Theme.of(context).textTheme.caption,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).backgroundColor,
    );
  }
}
