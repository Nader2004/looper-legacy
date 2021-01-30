import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:intro_slider/slide_object.dart';
import 'package:looper/Pages/home.dart';
import 'package:looper/services/auth.dart';
import 'package:looper/services/personality.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/storage.dart';
import '../Pages/profile_picture_setUp.dart';

class PersonalPage extends StatefulWidget {
  static const String id = 'personalPage';
  final String username;
  final String email;
  final String password;
  const PersonalPage({
    Key key,
    this.username,
    this.email,
    this.password,
  }) : super(key: key);
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
  static String _state = 'UNKNOWN AUTHENTICATION';
  static String gender = _isFemalePressed == true ? 'Female' : 'Male';
  static File profileImage;
  static Map<String, dynamic> birthdate = {
    'day': null,
    'month': null,
    'year': null,
  };

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
      AuthService.registerUser(
        context,
        widget.username,
        widget.email,
        widget.password,
        gender,
        imageUrl.first,
        birthdate,
        disableLoading: () {
          setState(() {
            _state = 'NOT AUTHENTICATED';
          });
        },
        enableLoading: () {
          setState(() {
            _state = 'AUTHENTICATED';
          });
        },
      );
      if (_state == 'NOT AUTHENTICATED') {
        setState(() {
          _isLoading = false;
          _done = false;
        });
      } else if (_state == 'AUTHENTICATED') {
        setState(() {
          _isLoading = true;
          _buttonWidth = 55;
        });
      }
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
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => BioPage(
                    username: widget.username,
                    deviceWidth: MediaQuery.of(context).size.width,
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      return;
    }
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
                                    color: _isMalePressed == true
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

class BioPage extends StatefulWidget {
  final String username;
  final double deviceWidth;
  BioPage({Key key, this.username, this.deviceWidth}) : super(key: key);

  @override
  _BioPageState createState() => _BioPageState();
}

class _BioPageState extends State<BioPage> {
  String bio = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.height / 2.5,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Text(
                  'Add your bio',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 30,
                  ),
                ),
              ),
              SizedBox(height: 25),
              Center(
                child: FaIcon(
                  FontAwesomeIcons.userEdit,
                  color: Colors.black,
                  size: 45,
                ),
              ),
              SizedBox(height: 25),
              Center(
                child: Container(
                  margin: EdgeInsets.only(bottom: 20),
                  width: widget.deviceWidth / 1.2,
                  child: TextFormField(
                    autocorrect: true,
                    maxLength: 150,
                    decoration: InputDecoration(
                      labelText: 'your bio',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.black,
                      ),
                    ),
                    onChanged: (String value) {
                      bio = value;
                    },
                    validator: (String value) {
                      if (value.isEmpty || value.length <= 5) {
                        return 'your bio is too short';
                      } else {
                        return null;
                      }
                    },
                    onEditingComplete: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                    },
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 7,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RaisedButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    color: Colors.white,
                    textColor: Colors.black,
                    child: Text('S K I P'),
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => RelationshipStatus(
                          username: widget.username,
                          deviceWidth: MediaQuery.of(context).size.width,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      color: Colors.black,
                      textColor: Colors.white,
                      child: Text('N E X T'),
                      onPressed: () async {
                        if (bio.isNotEmpty) {
                          PersonalityService.setTextInput(bio);
                          SharedPreferences _prefs =
                              await SharedPreferences.getInstance();
                          String _id = _prefs.getString('id');
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(_id)
                              .set(
                            {'bio': bio},
                            SetOptions(merge: true),
                          );
                          
                          Fluttertoast.showToast(msg: 'Bio saved');
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => RelationshipStatus(
                                username: widget.username,
                                deviceWidth: MediaQuery.of(context).size.width,
                              ),
                            ),
                          );
                        } else {
                          Fluttertoast.showToast(msg: 'Add your bio first');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RelationshipStatus extends StatefulWidget {
  final String username;
  final double deviceWidth;
  RelationshipStatus({Key key, this.username, this.deviceWidth})
      : super(key: key);

  @override
  _RelationshipStatusState createState() => _RelationshipStatusState();
}

class _RelationshipStatusState extends State<RelationshipStatus> {
  String status = '';
  bool _isSinglePressed = false;
  bool _isNotSinglePressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.height / 3.5,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Text(
                  'Add your Relationship status',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 25,
                  ),
                ),
              ),
              SizedBox(height: 25),
              Center(
                child: Icon(
                  MdiIcons.heartMultipleOutline,
                  color: Colors.black,
                  size: 45,
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300],
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
                            color: _isSinglePressed == true
                                ? Colors.black
                                : Colors.grey[50],
                            onPressed: () {
                              setState(() {
                                _isSinglePressed = true;
                                _isNotSinglePressed = false;
                                status = 'single';
                              });
                            },
                            child: Column(
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(bottom: 25),
                                  child: Icon(
                                    MdiIcons.account,
                                    color: _isSinglePressed == true
                                        ? Colors.white
                                        : Colors.black,
                                    size: 50,
                                  ),
                                ),
                                Text(
                                  'SINGLE',
                                  style: TextStyle(
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w400,
                                    color: _isSinglePressed == true
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
                            color: Colors.grey[300],
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
                            color: _isNotSinglePressed == true
                                ? Colors.black
                                : Colors.white,
                            onPressed: () {
                              setState(() {
                                _isNotSinglePressed = true;
                                _isSinglePressed = false;
                                status = 'couple';
                              });
                            },
                            child: Column(
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(bottom: 25),
                                  child: Icon(
                                    MdiIcons.accountMultiple,
                                    color: _isNotSinglePressed == true
                                        ? Colors.white
                                        : Colors.black,
                                    size: 50,
                                  ),
                                ),
                                Text(
                                  'COUPLE',
                                  style: TextStyle(
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w400,
                                    color: _isNotSinglePressed == true
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
              SizedBox(
                height: MediaQuery.of(context).size.height / 7,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RaisedButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    color: Colors.white,
                    textColor: Colors.black,
                    child: Text('S K I P'),
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => IntroPage(
                          username: widget.username,
                          deviceWidth: MediaQuery.of(context).size.width,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      color: Colors.black,
                      textColor: Colors.white,
                      child: Text('N E X T'),
                      onPressed: () async {
                        if (status.isNotEmpty) {
                          SharedPreferences _prefs =
                              await SharedPreferences.getInstance();
                          String _id = _prefs.getString('id');
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(_id)
                              .set(
                            {'status': status},
                            SetOptions(merge: true),
                          );
                          Fluttertoast.showToast(msg: 'your status is saved');
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => IntroPage(
                                username: widget.username,
                                deviceWidth: MediaQuery.of(context).size.width,
                              ),
                            ),
                          );
                        } else {
                          Fluttertoast.showToast(msg: 'Add your status first');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IntroPage extends StatefulWidget {
  final String username;
  final double deviceWidth;
  IntroPage({Key key, this.username, this.deviceWidth}) : super(key: key);

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  List<Slide> _slides = [];

  @override
  void initState() {
    super.initState();
    _slides.add(
      Slide(
        title: 'Hello ${widget.username}',
        styleTitle: GoogleFonts.aBeeZee(
          color: Colors.black,
          fontSize: 40,
          fontWeight: FontWeight.w600,
        ),
        pathImage: 'assets/network.png',
        heightImage: widget.deviceWidth / 2,
        widthImage: widget.deviceWidth / 2,
        description:
            'Looper keeps you connected with the compatible ones. Create long term friendships and relationships',
        styleDescription: GoogleFonts.aBeeZee(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.white,
      ),
    );
    _slides.add(
      Slide(
        title: 'Global rooms',
        styleTitle: GoogleFonts.aBeeZee(
          color: Colors.black,
          fontSize: 40,
          fontWeight: FontWeight.w600,
        ),
        description:
            'Global rooms are content categories, where you can create and interact with',
        centerWidget: Column(
          children: [
            Icon(
              FontAwesomeIcons.globe,
              size: widget.deviceWidth / 3,
              color: Colors.black,
            ),
            SizedBox(height: widget.deviceWidth / 8),
            Wrap(
              children: [
                Container(
                  height: widget.deviceWidth / 5.2,
                  width: widget.deviceWidth / 5.2,
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.favorite,
                        size: 24,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: widget.deviceWidth / 5.2,
                  width: widget.deviceWidth / 5.2,
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Icon(
                        MdiIcons.dramaMasks,
                        size: 26,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: widget.deviceWidth / 5.2,
                  width: widget.deviceWidth / 5.2,
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Icon(
                        MdiIcons.flagCheckered,
                        size: 24,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: widget.deviceWidth / 5.2,
                  width: widget.deviceWidth / 5.2,
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Icon(
                        MdiIcons.star,
                        size: 24,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: widget.deviceWidth / 5.2,
                  width: widget.deviceWidth / 5.2,
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Icon(
                        MdiIcons.baseball,
                        size: 24,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        styleDescription: GoogleFonts.aBeeZee(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.white,
      ),
    );
    _slides.add(
      Slide(
        title: 'L O V E',
        backgroundColor: Colors.redAccent,
        centerWidget: Padding(
          padding: EdgeInsets.only(top: widget.deviceWidth / 8),
          child: Icon(
            MdiIcons.heartMultiple,
            size: widget.deviceWidth / 2.5,
            color: Colors.white,
          ),
        ),
        description:
            'In this room, you can create love cards and you can wish how your partner character or look will be like',
        styleDescription: GoogleFonts.aBeeZee(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    _slides.add(
      Slide(
        title: 'T A L E N T S',
        backgroundColor: Colors.deepPurple,
        centerWidget: Padding(
          padding: EdgeInsets.only(top: widget.deviceWidth / 8),
          child: FaIcon(
            FontAwesomeIcons.star,
            size: widget.deviceWidth / 2.5,
            color: Colors.white,
          ),
        ),
        description:
            'Here you can upload short video clips showing your talents like : singing, dancing, acting, painting and other ones too',
        styleDescription: GoogleFonts.aBeeZee(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    _slides.add(
      Slide(
        title: 'S P O R T S',
        backgroundColor: Colors.blue[700],
        centerWidget: Padding(
          padding: EdgeInsets.only(top: widget.deviceWidth / 8),
          child: FaIcon(
            FontAwesomeIcons.basketballBall,
            size: widget.deviceWidth / 2.5,
            color: Colors.white,
          ),
        ),
        description:
            'Here you can upload short video clips about different types of sports like : swimming, basketball, football, soccer and even more',
        styleDescription: GoogleFonts.aBeeZee(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    _slides.add(
      Slide(
        title: 'C O M E D Y',
        backgroundColor: Colors.yellow[700],
        centerWidget: Padding(
          padding: EdgeInsets.only(top: widget.deviceWidth / 8),
          child: Icon(
            MdiIcons.dramaMasks,
            size: widget.deviceWidth / 2.5,
            color: Colors.white,
          ),
        ),
        description:
            'Here you can upload jokes, images and videos . You can even create your own comedy shows where other people could join the show and comment on it',
        styleDescription: GoogleFonts.aBeeZee(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    _slides.add(
      Slide(
        title: 'C H A L L E N G E S',
        backgroundColor: Colors.indigo,
        centerWidget: Padding(
          padding: EdgeInsets.only(top: widget.deviceWidth / 8),
          child: Icon(
            MdiIcons.flagCheckered,
            size: widget.deviceWidth / 2.5,
            color: Colors.white,
          ),
        ),
        description:
            'Have some challeging ideas ? Then this is the place. Upload short videos showing your challenges to the world',
        styleDescription: GoogleFonts.aBeeZee(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      slides: _slides,
      colorDoneBtn: Colors.black,
      isShowSkipBtn: false,
      onDonePress: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(firstTime: true),
        ),
      ),
    );
  }
}
