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
    String password, {
    Function enableLoading,
    Function disableLoading,
  }) async {
    enableLoading();
    try {
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      final UserCredential _result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User _user = _result.user;

      if (_user != null) {
        _prefs.setString('id', _user.uid);
        _firestore.collection('users').doc(_user.uid).set({
          'username': username,
          'email': email,
          'searchKey': username.substring(0, 1),
        });
      }

      Fluttertoast.showToast(msg: 'You are registered');
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'ERROR_INVALID_EMAIL':
          _showErrorDialog(
            context,
            'incorrect Email',
            'Please check your Email! Maybe you wrote it wrong.',
            disableLoading: disableLoading,
          );
          break;
        case 'ERROR_EMAIL_ALREADY_IN_USE':
          _showErrorDialog(
            context,
            'Email already exist',
            'This Email exists already. You can login instead',
            disableLoading: disableLoading,
            addButton: true,
          );
          break;
        case 'ERROR_WEAK_PASSWORD':
          _showErrorDialog(
            context,
            'The Password is weak',
            'Please write a stronger Password. Try to use numbers or symbols.',
            disableLoading: disableLoading,
          );
          break;
        case 'ERROR_NETWORK_ERROR':
          _showErrorDialog(
            context,
            'poor Connection',
            'Please check your Internet Connection',
            disableLoading: disableLoading,
          );
          break;
        default:
          _showErrorDialog(
            context,
            'Something went wrong',
            'Could not sign up',
            disableLoading: disableLoading,
          );
      }
    }
  }

  static Future<void> logInUser(
      BuildContext context, String email, String password) async {
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
    } on PlatformException catch (e) {
      print(e.code);
      switch (e.code) {
        case 'ERROR_INVALID_EMAIL':
          _showErrorDialog(
            context,
            'incorrect Email',
            'Please check your Email! Maybe you wrote it wrong.',
          );
          break;
        case 'ERROR_USER_NOT_FOUND':
          _showErrorDialog(
            context,
            'Account not found',
            'The Email and Password you\'ve written were not found',
          );
          break;
        case 'ERROR_WRONG_PASSWORD':
          _showErrorDialog(
            context,
            'invalid Password',
            'Please enter a correct Password',
          );
          break;
        case 'ERROR_NETWORK_ERROR':
          _showErrorDialog(
            context,
            'Poor Connection',
            'Please check your Internet Connection',
          );
          break;
        default:
          _showErrorDialog(
            context,
            'Something went wrong',
            'Could not sign in',
          );
      }
    }
  }

  static Future<void> logOut(BuildContext context) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      await _auth.signOut();
      Fluttertoast.showToast(msg: 'You are logged out');
      Navigator.popUntil(context, (route) => route.isFirst);
    } on PlatformException catch (e) {
      if (e.code == 'ERROR_NETWORK_ERROR') {
        _showErrorDialog(
          context,
          'Poor Connection',
          'Please check your Internet Connection',
        );
      }
    }
  }
}
