import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:vidmapper/utils/SharedPreferenceHelper.dart';
import 'package:vidmapper/widgets/VidMapperScaffold.dart';
import './models/globals.dart' as globals;
import 'dart:async';
import 'dart:convert';

import 'models/styles.dart';

class Signin extends StatefulWidget {
  @override
  _SigninState createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  TextEditingController _username = new TextEditingController(),
      _email = new TextEditingController();
  SharedPreferenceHelper sharedPreferenceHelper = new SharedPreferenceHelper();

  onSubmit() async {
    await sharedPreferenceHelper.init();
    String password = 'bapu dede thoda cash';
    String usernameText = _username.text;
    String emailText = _email.text;
    print('Login');
    print('email: $emailText, username: $usernameText, password: $password,');
    final responseLogin = await http.post(
      '${globals.ip}/login',
      body: {
        'email': emailText,
        'password': password,
      },
    );
    if (responseLogin.statusCode == 200) {
      final responseJson = json.decode(responseLogin.body);
      await sharedPreferenceHelper.setUsernameAndToken(
        responseJson['username'],
        responseJson['token'],
      );
      if (await getStreamKey(responseJson['username'], sharedPreferenceHelper,
          responseJson['token'])) Navigator.of(context).pushNamed('/Home');
    } else if (responseLogin.statusCode == 403) {
      print('register');
      print('email: $emailText, username: $usernameText, password: $password,');
      final responseRegister = await http.post(
        '${globals.ip}/register',
        body: {
          'email': emailText,
          'username': usernameText,
          'password': password,
        },
      );
      if (responseRegister.statusCode == 200) {
        final responseJson = json.decode(responseRegister.body);
        await sharedPreferenceHelper.setUsernameAndToken(
          usernameText,
          responseJson['token'],
        );
        if (await getStreamKey(
            usernameText, sharedPreferenceHelper, responseJson['token']))
          Navigator.of(context).pushNamed('/Home');
      } else {
        throw Exception('Register Failed');
      }
    } else {
      throw Exception('Login Failed');
    }
  }

  Future<bool> getStreamKey(String username,
      SharedPreferenceHelper sharedPreferenceHelper, String token) async {
    final response = await http.post(
      '${globals.ip}/user',
      headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
      body: {
        'username': username,
      },
    );
    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      await sharedPreferenceHelper.setStreamKey(responseJson['stream_key']);
      return true;
    } else {
      throw Exception('Failed to get Stream Key');
    }
  }

  // bool _canSeePassword = false;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: VidMapperScaffold(
        title: "Sign In",
        body: Padding(
          padding:
              EdgeInsets.symmetric(vertical: kToolbarHeight, horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Spacer(),
              TextField(
                controller: _username,
                decoration: InputDecoration(
                  labelText: "Username",
                  labelStyle:
                      GoogleFonts.cabin(fontSize: 16, color: Colors.white),
                  suffixIcon: Icon(Icons.person_outline, color: Colors.white70),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.greenAccent,
                          style: BorderStyle.solid,
                          width: 1.0)),
                  focusColor: Colors.yellow,
                ),
              ),
              SizedBox(height: 80),
              TextField(
                controller: _email,
                // obscureText: _canSeePassword,
                decoration: InputDecoration(
                  suffixIcon: Icon(
                    Icons.alternate_email,
                    color: Colors.white70,
                  ),
                  labelText: "Email",
                  labelStyle:
                      GoogleFonts.cabin(fontSize: 16, color: Colors.white),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.greenAccent,
                          style: BorderStyle.solid,
                          width: 1.0)),
                  focusColor: Colors.yellow,
                ),
              ),
              Spacer(),
              SizedBox(
                height: 50,
                width: 200,
                child: RaisedButton(
                  onPressed: onSubmit,
                  color: Styles.brightIndigo,
                  child: Text('Submit', style: GoogleFonts.cabin()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
