import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../Pages/home.dart';
import '../services/database.dart';
import '../services/storage.dart';
import '../Pages/profile_picture_setUp.dart';

class PersonalPage extends StatefulWidget {
  static const String id = 'personalPage';
  const PersonalPage({Key key}) : super(key: key);
  @override
  _PersonalPageState createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  static double _buttonWidth = 300;
  static bool _done = false;
  static bool _isLoading = false;
  static bool _continuePressed = false;
  static bool _isFemalePressed = false;
  static bool _isMalePressed = false;
  static String _userId;
  static String gender = _isFemalePressed == true ? 'Female' : 'Male';
  static File profileImage;
  static Map<String, dynamic> birthdate = {
    'day': null,
    'month': null,
    'year': null,
  };

  void _initPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    String _id = _prefs.getString('id');
    _userId = _id;
  }

  void _showBirthdateDialog() {
    DatePicker.showDatePicker(
      context,
      currentTime: DateTime(1998, 10, 5),
      maxTime: DateTime(2013, 12, 31),
      minTime: DateTime(1925, 1, 1),
      onConfirm: (DateTime time) {
        setState(
          () {
            birthdate['year'] = time.year;
            birthdate['month'] = time.month;
            birthdate['day'] = time.day;
          },
        );
      },
      onChanged: (DateTime time) {
        setState(
          () {
            birthdate['year'] = time.year;
            birthdate['month'] = time.month;
            birthdate['day'] = time.day;
          },
        );
      },
    );
  }

  bool validateGender() {
    if (_continuePressed == true) {
      if (_isFemalePressed == false && _isMalePressed == false) {
        return false;
      } else {
        return true;
      }
    } else {
      return null;
    }
  }

  bool validateBirthdate() {
    if (_continuePressed == true) {
      if (birthdate['day'] == null &&
          birthdate['month'] == null &&
          birthdate['year'] == null) {
        return false;
      } else {
        return true;
      }
    } else {
      return null;
    }
  }

  bool validateProfileImage() {
    if (_continuePressed == true) {
      if (profileImage == null) {
        return false;
      } else {
        return true;
      }
    } else {
      return null;
    }
  }

  void _submit() async {
    validateGender();
    validateBirthdate();
    validateProfileImage();
    if (validateGender() == true &&
        validateBirthdate() == true &&
        validateProfileImage() == true) {
      final List<String> imageUrl = await StorageService.uploadMediaFile(
        [profileImage],
        'profileImage',
      );
      DatabaseService.setPersonalData(
        context: context,
        callback: () {
          setState(() {
            _isLoading = false;
            _done = false;
          });
        },
        userId: _userId,
        gender: gender,
        birthdate: birthdate,
        profilePictureUrl: imageUrl.first,
      );
      setState(() {
        _isLoading = true;
        _buttonWidth = 55;
      });
      Timer(
        Duration(seconds: 3),
        () {
          setState(() {
            _isLoading = false;
            _done = true;
          });
          Timer(
            Duration(milliseconds: 800),
            () {
              Navigator.of(context).pushNamed(HomePage.id);
            },
          );
        },
      );
    } else {
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Scaffold(
          body: Column(
            children: <Widget>[
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 100),
                  child: Text(
                    'Personal Information',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: validateGender() == false
                                ? Colors.red
                                : Colors.grey[300],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ButtonTheme(
                          height: 140,
                          minWidth: 140,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: FlatButton(
                            color: _isFemalePressed == true
                                ? Colors.black
                                : Colors.grey[50],
                            onPressed: () {
                              setState(() {
                                _isFemalePressed = true;
                                _isMalePressed = false;
                              });
                            },
                            child: Column(
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(bottom: 25),
                                  child: Icon(
                                    MdiIcons.genderFemale,
                                    color: _isFemalePressed == true
                                        ? Colors.white
                                        : Colors.black,
                                    size: 50,
                                  ),
                                ),
                                Text(
                                  'FEMALE',
                                  style: TextStyle(
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w400,
                                    color: _isFemalePressed == true
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: validateGender() == false
                                ? Colors.red
                                : Colors.grey[300],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ButtonTheme(
                          height: 140,
                          minWidth: 140,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: FlatButton(
                            color: _isMalePressed == true
                                ? Colors.black
                                : Colors.white,
                            onPressed: () {
                              setState(() {
                                _isMalePressed = true;
                                _isFemalePressed = false;
                              });
                              validateGender();
                            },
                            child: Column(
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(bottom: 25),
                                  child: Icon(
                                    MdiIcons.genderMale,
                                    color: _isFemalePressed == true
                                        ? Colors.white
                                        : Colors.black,
                                    size: 50,
                                  ),
                                ),
                                Text(
                                  'MALE',
                                  style: TextStyle(
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w400,
                                    color: _isMalePressed == true
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              validateGender() == false ? SizedBox(height: 25) : Container(),
              validateGender() == false
                  ? Text(
                      'Choose you gender please',
                      style: TextStyle(color: Colors.red),
                    )
                  : Container(),
              SizedBox(
                height: validateGender() == false ? 25 : 50,
              ),
              Center(
                child: ButtonTheme(
                  minWidth: 300,
                  height: 50,
                  child: OutlineButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                    borderSide: BorderSide(
                      width: 1,
                      color: validateBirthdate() == false
                          ? Colors.red
                          : Colors.black,
                    ),
                    onPressed: birthdate['day'] != null &&
                            birthdate['month'] != null &&
                            birthdate['year'] != null
                        ? null
                        : () {
                            _showBirthdateDialog();
                            validateBirthdate();
                          },
                    child: Container(
                      width: birthdate.values != null ? 270 : 250,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          validateBirthdate() == false
                              ? Container(
                                  margin: EdgeInsets.only(left: 20),
                                  child: Icon(
                                    Icons.report,
                                    color: Colors.red,
                                  ),
                                )
                              : Container(),
                          Container(
                            margin: EdgeInsets.only(
                              right: birthdate == null ? 40 : 20,
                              left: validateBirthdate() == false ? 40 : 50,
                            ),
                            child: Text(
                              birthdate['day'] == null &&
                                      birthdate['month'] == null &&
                                      birthdate['year'] == null
                                  ? 'Select your Birthdate'
                                  : 'Birthdate is  ' +
                                      birthdate['year'].toString() +
                                      '/' +
                                      birthdate['month'].toString() +
                                      '/' +
                                      birthdate['day'].toString(),
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          birthdate['day'] != null &&
                                  birthdate['month'] != null &&
                                  birthdate['year'] != null
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Center(
                child: ButtonTheme(
                  minWidth: 300,
                  height: 50,
                  child: OutlineButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                    borderSide: BorderSide(
                      width: 1,
                      color: validateProfileImage() == false
                          ? Colors.red
                          : Colors.black,
                    ),
                    onPressed: profileImage != null
                        ? null
                        : () {
                            Navigator.push<File>(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    ProfilePictureSetup(),
                              ),
                            ).then((File result) {
                              if (result != null) {
                                setState(() {
                                  profileImage = result;
                                });
                              }
                            });
                            validateProfileImage();
                          },
                    child: Container(
                      width: 265,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          validateProfileImage() == false
                              ? Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Icon(
                                    Icons.report,
                                    color: Colors.red,
                                  ),
                                )
                              : Container(),
                          Container(
                            margin: EdgeInsets.only(
                              right: 17,
                              left: validateProfileImage() == false ? 40 : 50,
                            ),
                            child: Text(
                              profileImage != null
                                  ? 'Profile Picture added'
                                  : 'Add your Profile Picture',
                              style: TextStyle(fontSize: 16, wordSpacing: 1.2),
                            ),
                          ),
                          profileImage != null
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : Icon(Icons.account_circle),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              AnimatedContainer(
                width: _buttonWidth,
                height: _isLoading == true || _done == true ? 55 : 45,
                duration: Duration(milliseconds: 400),
                child: FlatButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _isLoading == true || _done == true ? 30 : 5,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _continuePressed = true;
                    });
                    _submit();
                  },
                  color: Colors.black,
                  child: _isLoading == true
                      ? SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : _done == true
                          ? Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 16,
                            )
                          : Text(
                              'continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
