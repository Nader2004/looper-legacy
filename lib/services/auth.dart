import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Pages/log_in.dart';

import 'package:fluttertoast/fluttertoast.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static void _showErrorDialog(
    BuildContext context,
    String title,
    String content, {
    Function disableLoading,
    bool addButton = false,
  }) {
    disableLoading();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Center(child: Text(title)),
          content: Container(
            height: 30,
            child: Text(
              content,
              textAlign: TextAlign.center,
            ),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Okay'),
            ),
            addButton == true
                ? FlatButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, LogInPage.id);
                    },
                    child: Text('login'),
                  )
                : Container(),
          ],
        );
      },
    );
  }

  static Future<void> registerUser(
    BuildContext context,
    String username,
    String email,
    String password,
    String gender,
    String profilePictureUrl,
    Map<String, dynamic> birthdate, {
    Function enableLoading,
    Function disableLoading,
  }) async {
    try {
      enableLoading();
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      final UserCredential _result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User _user = _result.user;

      if (_user != null) {
        _prefs.setString('id', _user.uid);
        _firestore.collection('users').doc(_user.uid).set({
          'id': _user.uid,
          'gender': gender,
          'birthdate': birthdate,
          'interested-people': [],
          'personality-type': {},
          'profilePictureUrl': profilePictureUrl,
          'username': username,
          'email': email,
          'searchKey': username.substring(0, 1),
          'isTyping': false,
        });
      }

      Fluttertoast.showToast(msg: 'You are registered');
    } on PlatformException catch (e) {
      Fluttertoast.showToast(msg: e.message);
    }
  }

  static Future<void> logInUser(
    BuildContext context,
    String email,
    String password,
    Function callBack,
  ) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      final UserCredential _result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User _user = _result.user;
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      _prefs.remove('id');
      _prefs.setString('id', _user.uid);
      Fluttertoast.showToast(msg: 'You are logged in');
      callBack();
    } catch (_) {
      Fluttertoast.showToast(msg: 'incorrect email or password');
    }
  }

  static Future<void> logOut(BuildContext context) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      await _auth.signOut();
      Fluttertoast.showToast(msg: 'You are logged out');
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (_) {
      _showErrorDialog(
        context,
        'Poor Connection',
        'Please check your Internet Connection',
      );
    }
  }
}
