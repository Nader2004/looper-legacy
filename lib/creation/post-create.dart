import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bounce/flutter_bounce.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoder/geocoder.dart';
import 'package:location/location.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/services/personality.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:giphy_picker/giphy_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:superellipse_shape/superellipse_shape.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/questionModel.dart';
import '../models/postModel.dart';
import '../services/database.dart';
import '../services/storage.dart';
import '../camera/camera.dart';
import '../audio-picker.dart';

/// TYPE 1 : TEXT
/// TYPE 2 : QUESTION
/// TYPE 3 : MEDIA
/// TYPE 4 : GIF
/// TYPE 5 : AUDIO

enum PlayerState { stopped, playing, paused }

class PostCreationPage extends StatefulWidget {
  static const pageId = 'post-creation';
  PostCreationPage({Key key}) : super(key: key);

  @override
  _PostCreationPageState createState() => _PostCreationPageState();
}

class _PostCreationPageState extends State<PostCreationPage> {
  bool _isPressed = false;
  bool _isPressed2 = false;
  bool _isPressed3 = false;
  bool _isPressed4 = false;
  bool _isPressed5 = false;
  bool _isPressed6 = false;
  bool _showLoading = false;
  bool _showCursor = false;
  String _userId;
  String _userName;
  String _userImage;
  Map<String, dynamic> _personalityType;
  String _userLocation;
  GiphyGif _gif;
  List<MediaUrl> _mediaUrl = [];
  List<MediaUrl> _questionMedia = [];
  String _audioUrl = '';
  String _audioImage = '';
  Location location = Location();
  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  LocationData _locationData;
  final PageController _pageController = PageController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _giphyCaptionController = TextEditingController();
  final TextEditingController _describtionController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _option1Controller = TextEditingController();
  final TextEditingController _option2Controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    getUserData();
    _isPressed = true;
    _isPressed2 = false;
    _isPressed3 = false;
    _isPressed4 = false;
    _isPressed5 = false;
    _isPressed6 = false;
  }

  void getUserData() async {
    setPrefs();
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final DocumentSnapshot _snapshot =
        await _firestore.collection('users').doc(_prefs.get('id')).get();

    setState(() {
      _userId = _prefs.get('id');
      _userName = _snapshot?.data()['username'];
      _userImage = _snapshot?.data()['profilePictureUrl'];
      _personalityType = _snapshot?.data()['personality-type'];
    });
  }

  void getUserLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    _locationData = await location.getLocation();
    if (_locationData != null) {
      final Coordinates _coordinates = Coordinates(
        _locationData.latitude,
        _locationData.longitude,
      );
      final List<Address> _addresses =
          await Geocoder.local.findAddressesFromCoordinates(_coordinates);
      if (_addresses != null) {
        final Address _address = _addresses.first;
        setState(
          () =>
              _userLocation = '${_address.countryName} , ${_address.adminArea}',
        );
      }
    }
  }

  Widget _buildTopButton(
    IconData iconData,
    String text,
    double distance,
    Function action,
  ) {
    return Container(
      width: 90,
      height: 35,
      margin: EdgeInsets.only(
        top: 35,
        bottom: 10,
        left: distance == null ? 0 : distance,
        right: distance == null ? 0 : distance,
      ),
      child: OutlineButton(
        borderSide: BorderSide(color: Colors.black),
        onPressed: action,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Icon(
              iconData,
              size: 20,
            ),
            Text(
              text,
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildSqaureOption({
    Widget child,
    Color backgroundColor,
    Color borderColor,
    VoidCallback callback,
  }) {
    return GestureDetector(
      onTap: callback,
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: borderColor),
          ),
          color: backgroundColor,
        ),
        child: child,
      ),
    );
  }

  Widget _buildOptionsBar() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width / 5,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _buildSqaureOption(
              child: Icon(
                Icons.text_fields,
                color: _isPressed == true ? Colors.blue : Colors.white,
              ),
              backgroundColor:
                  _isPressed == true ? Colors.grey[200] : Colors.blue,
              borderColor:
                  _isPressed == true ? Colors.blue : Colors.transparent,
              callback: () {
                setState(() {
                  _isPressed = true;
                  _isPressed2 = false;
                  _isPressed3 = false;
                  _isPressed4 = false;
                  _isPressed5 = false;
                  _isPressed6 = false;
                });
                _pageController.animateToPage(
                  0,
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOutSine,
                );
                if (_mediaUrl != null ||
                    _audioUrl != null ||
                    _questionMedia != null ||
                    _gif != null) {
                  setState(() {
                    _mediaUrl = [];
                    _audioUrl = '';
                    _questionMedia = [];
                    _gif = null;
                  });
                }
                _captionController.clear();
                _giphyCaptionController.clear();
                _describtionController.clear();
                _questionController.clear();
                _option1Controller.clear();
                _option2Controller.clear();
                FocusScope.of(context).requestFocus(_focusNode);
              },
            ),
            _buildSqaureOption(
              child: Icon(
                MdiIcons.commentQuestion,
                color: _isPressed2 == true ? Colors.red[700] : Colors.white,
              ),
              backgroundColor:
                  _isPressed2 == true ? Colors.grey[200] : Colors.red[700],
              borderColor:
                  _isPressed2 == true ? Colors.red[700] : Colors.transparent,
              callback: () {
                setState(() {
                  _isPressed = false;
                  _isPressed2 = true;
                  _isPressed3 = false;
                  _isPressed4 = false;
                  _isPressed5 = false;
                  _isPressed6 = false;
                });
                _captionController.clear();
                _giphyCaptionController.clear();
                _describtionController.clear();
                _textController.clear();
                FocusScope.of(context).unfocus();
                if (_mediaUrl != null || _audioUrl != null || _gif != null) {
                  setState(() {
                    _mediaUrl = [];
                    _audioUrl = '';
                    _gif = null;
                  });
                }
                _pageController.animateToPage(
                  1,
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOutSine,
                );
              },
            ),
            _buildSqaureOption(
              child: Icon(
                MdiIcons.image,
                color: _isPressed3 == true ? Colors.green : Colors.white,
              ),
              backgroundColor:
                  _isPressed3 == true ? Colors.grey[200] : Colors.green,
              borderColor:
                  _isPressed3 == true ? Colors.green : Colors.transparent,
              callback: _mediaUrl.length == 15
                  ? null
                  : () {
                      setState(() {
                        _isPressed = false;
                        _isPressed2 = false;
                        _isPressed3 = true;
                        _isPressed4 = false;
                        _isPressed5 = false;
                        _isPressed6 = false;
                      });
                      _questionController.clear();
                      _giphyCaptionController.clear();
                      _describtionController.clear();
                      _option1Controller.clear();
                      _option2Controller.clear();
                      _textController.clear();
                      FocusScope.of(context).unfocus();
                      FilePicker.platform.pickFiles().then((value) {
                        if (value == null) {
                          if (_mediaUrl.length == 0) {
                            _pageController.animateToPage(
                              0,
                              duration: Duration(milliseconds: 100),
                              curve: Curves.easeInOutSine,
                            );
                            setState(() {
                              _isPressed = false;
                              _isPressed2 = false;
                              _isPressed3 = false;
                              _isPressed4 = false;
                              _isPressed5 = false;
                              _isPressed6 = false;
                            });
                          } else {
                            _pageController.animateToPage(
                              2,
                              duration: Duration(milliseconds: 100),
                              curve: Curves.easeInOutSine,
                            );
                            setState(() {
                              _isPressed = false;
                              _isPressed2 = false;
                              _isPressed3 = false;
                              _isPressed4 = false;
                              _isPressed5 = false;
                              _isPressed6 = false;
                            });
                          }
                        } else {
                          setState(() {
                            _isPressed = false;
                            _isPressed2 = false;
                            _isPressed3 = false;
                            _isPressed4 = false;
                            _isPressed5 = false;
                            _isPressed6 = false;
                          });
                          _pageController.animateToPage(
                            2,
                            duration: Duration(milliseconds: 100),
                            curve: Curves.easeInOutSine,
                          );
                          setState(() {
                            _isPressed = false;
                            _isPressed2 = false;
                            _isPressed3 = false;
                            _isPressed4 = false;
                            _isPressed5 = false;
                            _isPressed6 = false;
                          });
                          List<MediaUrl> _newValue = List.generate(
                            value.files.length == 15 || value.files.length < 15
                                ? value.files.length
                                : 15,
                            (index) => MediaUrl(
                              mediaUrl: value.files.toList()[index].path,
                              type: value.files
                                      .toList()[index]
                                      .path
                                      .endsWith('.mp4')
                                  ? '1'
                                  : '0',
                            ),
                          );
                          setState(() {
                            _mediaUrl.addAll(_newValue);
                            if (_audioUrl != null ||
                                _questionMedia != null ||
                                _gif != null) {
                              _audioUrl = '';
                              _questionMedia = [];
                              _gif = null;
                            }
                          });
                        }
                      });
                    },
            ),
            _buildSqaureOption(
              child: Icon(
                MdiIcons.gif,
                color: _isPressed4 == true ? Colors.purple[800] : Colors.white,
              ),
              backgroundColor:
                  _isPressed4 == true ? Colors.grey[200] : Colors.purple[800],
              borderColor:
                  _isPressed4 == true ? Colors.purple[800] : Colors.transparent,
              callback: () async {
                setState(() {
                  _isPressed = false;
                  _isPressed2 = false;
                  _isPressed3 = false;
                  _isPressed4 = true;
                  _isPressed5 = false;
                  _isPressed6 = false;
                  if (_mediaUrl != null ||
                      _audioUrl != null ||
                      _questionMedia != null) {
                    _mediaUrl = [];
                    _audioUrl = '';
                    _questionMedia = [];
                  }
                });
                _questionController.clear();
                _captionController.clear();
                _describtionController.clear();
                _option1Controller.clear();
                _option2Controller.clear();
                _textController.clear();
                FocusScope.of(context).unfocus();
                _pageController.animateToPage(
                  3,
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
                final _newGif = await GiphyPicker.pickGif(
                  context: context,
                  searchText: 'Search for any gif',
                  apiKey: 'UhvOlgZPcbRwN490PThaYgBlNy7N5rIx',
                );
                setState(() {
                  _gif = _newGif;
                  _isPressed = false;
                  _isPressed2 = false;
                  _isPressed3 = false;
                  _isPressed4 = false;
                  _isPressed5 = false;
                  _isPressed6 = false;
                });
              },
            ),
            _buildSqaureOption(
              child: Icon(
                Icons.camera_alt,
                color: _isPressed5 == true ? Colors.pink : Colors.white,
              ),
              backgroundColor:
                  _isPressed5 == true ? Colors.grey[200] : Colors.pink,
              borderColor:
                  _isPressed5 == true ? Colors.pink : Colors.transparent,
              callback: _mediaUrl.length == 15
                  ? null
                  : () {
                      setState(() {
                        _isPressed = false;
                        _isPressed2 = false;
                        _isPressed3 = false;
                        _isPressed4 = false;
                        _isPressed5 = true;
                        _isPressed6 = false;
                      });
                      _questionController.clear();
                      _giphyCaptionController.clear();
                      _describtionController.clear();
                      _option1Controller.clear();
                      _option2Controller.clear();
                      _textController.clear();
                      FocusScope.of(context).unfocus();
                      Navigator.of(context)
                          .push<String>(
                        MaterialPageRoute(
                          builder: (context) => Camera(),
                        ),
                      )
                          .then((String media) {
                        if (media == null) {
                          if (_mediaUrl.length == 0) {
                            _pageController.animateToPage(
                              0,
                              duration: Duration(milliseconds: 100),
                              curve: Curves.easeInOutSine,
                            );
                            setState(() {
                              _isPressed = false;
                              _isPressed2 = false;
                              _isPressed3 = false;
                              _isPressed4 = false;
                              _isPressed5 = false;
                              _isPressed6 = false;
                            });
                          } else {
                            _pageController.animateToPage(
                              2,
                              duration: Duration(milliseconds: 100),
                              curve: Curves.easeInOutSine,
                            );
                            setState(() {
                              _isPressed = false;
                              _isPressed2 = false;
                              _isPressed3 = false;
                              _isPressed4 = false;
                              _isPressed5 = false;
                              _isPressed6 = false;
                            });
                          }
                        } else {
                          setState(() {
                            _isPressed = false;
                            _isPressed2 = false;
                            _isPressed3 = false;
                            _isPressed4 = false;
                            _isPressed5 = false;
                            _isPressed6 = false;
                          });
                          _pageController.animateToPage(
                            2,
                            duration: Duration(milliseconds: 100),
                            curve: Curves.easeInOutSine,
                          );
                          setState(() {
                            _isPressed = false;
                            _isPressed2 = false;
                            _isPressed3 = false;
                            _isPressed4 = false;
                            _isPressed5 = false;
                            _isPressed6 = false;
                          });
                          final _newValue = MediaUrl(
                            mediaUrl: media,
                            type: media.endsWith('.mp4') ? '1' : '0',
                          );
                          setState(() {
                            _mediaUrl.add(_newValue);
                            if (_audioUrl != null ||
                                _questionMedia != null ||
                                _gif != null) {
                              _audioUrl = '';
                              _questionMedia = [];
                              _gif = null;
                            }
                          });
                        }
                      });
                    },
            ),
            _buildSqaureOption(
              child: Icon(
                Icons.keyboard_voice,
                color: _isPressed6 == true ? Colors.deepOrange : Colors.white,
              ),
              backgroundColor:
                  _isPressed6 == true ? Colors.grey[200] : Colors.deepOrange,
              borderColor:
                  _isPressed6 == true ? Colors.deepOrange : Colors.transparent,
              callback: () {
                setState(() {
                  _isPressed = false;
                  _isPressed2 = false;
                  _isPressed3 = false;
                  _isPressed4 = false;
                  _isPressed5 = false;
                  _isPressed6 = true;
                });
                _captionController.clear();
                _giphyCaptionController.clear();
                _questionController.clear();
                _option1Controller.clear();
                _option2Controller.clear();
                _textController.clear();
                FocusScope.of(context).unfocus();
                if (_mediaUrl != null ||
                    _questionMedia != null ||
                    _gif != null) {
                  setState(() {
                    _mediaUrl = [];
                    _questionMedia = [];
                    _gif = null;
                  });
                }
                _pageController.animateToPage(
                  4,
                  duration: Duration(milliseconds: 100),
                  curve: Curves.easeInOutSine,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextPostContent() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(
            height: 135,
            margin: EdgeInsets.only(left: 20, right: 15),
            child: TextField(
              textInputAction: TextInputAction.done,
              controller: _textController,
              focusNode: _focusNode,
              inputFormatters: [
                LengthLimitingTextInputFormatter(200),
              ],
              onTap: () {
                setState(() {
                  _isPressed = true;
                  _isPressed2 = false;
                  _isPressed3 = false;
                  _isPressed4 = false;
                  _isPressed5 = false;
                  _isPressed6 = false;
                  if (_mediaUrl != null || _audioUrl != null || _gif != null) {
                    _mediaUrl = [];
                    _audioUrl = '';
                    _gif = null;
                  }
                });
              },
              maxLines: 20,
              style: TextStyle(
                fontSize: 20,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 20),
                hintText: 'What do you think ?',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width - 40,
        height: _questionMedia.isEmpty
            ? MediaQuery.of(context).size.height / 2.7
            : MediaQuery.of(context).size.height / 1.6,
        child: Card(
          elevation: 20,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(
                    top: _questionMedia.isNotEmpty ? 13 : 25,
                    bottom: _questionMedia.isNotEmpty ? 0 : 15,
                  ),
                  child: TextField(
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    showCursor: _showCursor,
                    onTap: () {
                      if (_mediaUrl != null ||
                          _audioUrl != null ||
                          _gif != null) {
                        setState(() {
                          _isPressed = false;
                          _isPressed2 = true;
                          _isPressed3 = false;
                          _isPressed4 = false;
                          _isPressed5 = false;
                          _isPressed6 = false;
                          _mediaUrl = [];
                          _audioUrl = '';
                          _gif = null;
                        });
                      }
                    },
                    onChanged: (String txt) {
                      setState(() {
                        if (txt.isNotEmpty) {
                          _showCursor = true;
                        } else {
                          _showCursor = false;
                        }
                      });
                    },
                    controller: _questionController,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                    ],
                    style: GoogleFonts.abel(
                      fontSize: 35,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.abel(
                        fontSize: 35,
                      ),
                      hintText: 'Your Question',
                    ),
                  ),
                ),
                _questionMedia.isNotEmpty
                    ? Container(
                        margin: EdgeInsets.only(
                          bottom: 20,
                        ),
                        height: 1,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.grey[400],
                      )
                    : Container(),
                _questionMedia.isNotEmpty
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          !_questionMedia.contains(_questionMedia.first)
                              ? _buildAddQuestionMediaPlaceholder()
                              : _questionMedia[0] == null
                                  ? null
                                  : _questionMedia[0].mediaUrl.endsWith('.mp4')
                                      ? VideoQuestionThumbWidget(
                                          videoUrl: _questionMedia[0].mediaUrl,
                                          onRemove: () {
                                            setState(() {
                                              _questionMedia.removeAt(0);
                                            });
                                          },
                                        )
                                      : _buildQuestionMedia(
                                          _questionMedia[0].mediaUrl,
                                          edgeInsetsGeometry:
                                              EdgeInsets.only(left: 10),
                                          index: 0,
                                        ),
                          Text(
                            'vs',
                            style: GoogleFonts.amiri(
                              fontSize: 33,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _questionMedia.length == 1
                              ? _buildAddQuestionMediaPlaceholder()
                              : _questionMedia[1] == null
                                  ? null
                                  : _questionMedia[1].mediaUrl.endsWith('.mp4')
                                      ? VideoQuestionThumbWidget(
                                          videoUrl: _questionMedia[1].mediaUrl,
                                          onRemove: () {
                                            setState(() {
                                              _questionMedia.removeAt(1);
                                            });
                                          },
                                        )
                                      : _buildQuestionMedia(
                                          _questionMedia[1].mediaUrl,
                                          edgeInsetsGeometry:
                                              EdgeInsets.only(right: 10),
                                          index: 1,
                                        ),
                        ],
                      )
                    : Container(
                        width: MediaQuery.of(context).size.width - 100,
                        height: 30,
                        child: OutlineButton(
                          onPressed: () {
                            _showMediaPickerDialog(maximum: 2);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          borderSide: BorderSide(color: Colors.black),
                          textColor: Colors.black,
                          child: Text(
                            'Compare Photos or Videos',
                            style: GoogleFonts.abel(
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                Container(
                  margin: EdgeInsets.only(
                    top: _questionMedia.isNotEmpty ? 20 : 30,
                  ),
                  height: 1,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.grey[400],
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(left: 5, top: 5),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            textAlign: TextAlign.center,
                            onTap: () {
                              if (_mediaUrl != null ||
                                  _audioUrl != null ||
                                  _gif != null) {
                                setState(() {
                                  _isPressed = false;
                                  _isPressed2 = true;
                                  _isPressed3 = false;
                                  _isPressed4 = false;
                                  _isPressed5 = false;
                                  _isPressed6 = false;
                                  _mediaUrl = [];
                                  _audioUrl = '';
                                  _gif = null;
                                });
                              }
                            },
                            controller: _option1Controller,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: GoogleFonts.abel(
                              fontSize: 30,
                              textStyle: TextStyle(
                                color: Colors.blue.withOpacity(0.7),
                              ),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintStyle: GoogleFonts.abel(
                                fontSize: 30,
                                textStyle: TextStyle(
                                  color: Colors.blue.withOpacity(0.7),
                                ),
                              ),
                              hintText: 'YES',
                            ),
                          ),
                        ),
                        Container(
                          height: 54,
                          width: 1,
                          color: Colors.grey[400],
                        ),
                        Expanded(
                          child: TextField(
                            textAlign: TextAlign.center,
                            onTap: () {
                              if (_mediaUrl != null ||
                                  _audioUrl != null ||
                                  _gif != null) {
                                setState(() {
                                  _isPressed = false;
                                  _isPressed2 = true;
                                  _isPressed3 = false;
                                  _isPressed4 = false;
                                  _isPressed5 = false;
                                  _isPressed6 = false;
                                  _mediaUrl = [];
                                  _audioUrl = '';
                                  _gif = null;
                                });
                              }
                            },
                            controller: _option2Controller,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: GoogleFonts.abel(
                              fontSize: 30,
                              textStyle: TextStyle(
                                color: Colors.blue.withOpacity(0.7),
                              ),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintStyle: GoogleFonts.abel(
                                fontSize: 30,
                                textStyle: TextStyle(
                                  color: Colors.blue.withOpacity(0.7),
                                ),
                              ),
                              hintText: 'NO',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (_mediaUrl.length != 0) {
      return SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _captionController.text.length != 0
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        _captionController.text,
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(width: 5),
                      Bounce(
                        onPressed: () => _showCaptionDialog(),
                        duration: Duration(milliseconds: 100),
                        child: Icon(
                          Icons.edit,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  )
                : Container(
                    width: MediaQuery.of(context).size.width - 20,
                    child: OutlineButton(
                      onPressed: () {
                        _showCaptionDialog();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      borderSide: BorderSide(color: Colors.blue),
                      textColor: Colors.blue,
                      child: Text('Add Caption'),
                    ),
                  ),
            Divider(),
            SizedBox(height: 10),
            CarouselSlider(
              options: CarouselOptions(
                height: 340,
                enableInfiniteScroll: false,
                enlargeCenterPage: true,
              ),
              items: List.generate(_mediaUrl == null ? 0 : _mediaUrl.length,
                  (index) {
                if (_mediaUrl[index].type == '1') {
                  return VideoThumbWidget(
                    videoUrl: _mediaUrl[index].mediaUrl,
                    onRemove: () {
                      setState(() {
                        _mediaUrl.removeAt(index);
                      });
                      if (_mediaUrl.length == 0) {
                        _pageController.animateToPage(
                          0,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.decelerate,
                        );
                      }
                    },
                  );
                }
                return Card(
                  elevation: 2.2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: Image.file(
                            File(_mediaUrl[index].mediaUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _mediaUrl.removeAt(index);
                              });
                              if (_mediaUrl.length == 0) {
                                _pageController.animateToPage(
                                  0,
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.decelerate,
                                );
                              }
                            },
                            child: Container(
                              height: 30,
                              width: 30,
                              margin: EdgeInsets.only(right: 10, top: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildGifContent() {
    if (_gif != null) {
      return Center(
        child: Container(
          height: MediaQuery.of(context).size.height / 2,
          width: MediaQuery.of(context).size.width - 50,
          child: Card(
            elevation: 5.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GiphyImage.original(
                        gif: _gif,
                        height: MediaQuery.of(context).size.height / 2,
                        width: MediaQuery.of(context).size.width - 50,
                        placeholder: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _gif = null;
                          _isPressed = true;
                          _isPressed2 = false;
                          _isPressed3 = false;
                          _isPressed4 = false;
                          _isPressed5 = false;
                          _isPressed6 = false;
                        });
                        _giphyCaptionController.clear();
                        _pageController.animateToPage(
                          0,
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeIn,
                        );
                      },
                      child: Container(
                        height: 30,
                        width: 30,
                        margin: EdgeInsets.only(right: 10, top: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 40,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: _giphyCaptionController.text.length == 0
                          ? TextField(
                              textAlign: TextAlign.center,
                              controller: _giphyCaptionController,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 18,
                              ),
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(40)
                              ],
                              decoration: InputDecoration.collapsed(
                                hintText: 'Add Caption...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 18,
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                left: 15,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Text(
                                    _giphyCaptionController.text,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(width: 7),
                                  Bounce(
                                    onPressed: () {
                                      setState(
                                        () => _giphyCaptionController.text = '',
                                      );
                                    },
                                    duration: Duration(milliseconds: 100),
                                    child: Icon(
                                      Icons.cancel,
                                      size: 16,
                                      color: Colors.grey[400],
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
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildAudioContent() {
    if (_audioUrl.isEmpty) {
      return Center(
        child: Card(
          elevation: 20,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: IntrinsicHeight(
            child: Column(
              children: <Widget>[
                SizedBox(height: 15),
                Icon(
                  MdiIcons.headphones,
                  size: 80,
                  color: Colors.deepOrangeAccent,
                ),
                SizedBox(height: 20),
                Text(
                  'Now you can upload audio files',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 5),
                Text(
                  'or record your own one',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  width: MediaQuery.of(context).size.width - 100,
                  child: FlatButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    color: Colors.deepOrange,
                    textColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _isPressed = false;
                        _isPressed2 = false;
                        _isPressed3 = false;
                        _isPressed4 = false;
                        _isPressed5 = false;
                        _isPressed6 = true;
                        if (_mediaUrl != null ||
                            _questionMedia != null ||
                            _gif != null) {
                          _mediaUrl = [];
                          _questionMedia = [];
                          _gif = null;
                        }
                      });
                      Navigator.of(context)
                          .push<String>(
                        MaterialPageRoute(
                          builder: (context) => AudioRecorderPage(),
                        ),
                      )
                          .then((String value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _audioUrl = value;
                        });
                      });
                    },
                    child: Text('Record Audio'),
                  ),
                ),
                SizedBox(height: 3),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  width: MediaQuery.of(context).size.width - 100,
                  child: OutlineButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    borderSide: BorderSide(color: Colors.deepOrange),
                    onPressed: () {
                      setState(() {
                        _isPressed = false;
                        _isPressed2 = false;
                        _isPressed3 = false;
                        _isPressed4 = false;
                        _isPressed5 = false;
                        _isPressed6 = true;
                        if (_mediaUrl != null ||
                            _questionMedia != null ||
                            _gif != null) {
                          _mediaUrl = [];
                          _questionMedia = [];
                          _gif = null;
                        }
                      });
                      Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPicker(),
                        ),
                      ).then((value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _audioUrl = value;
                        });
                      });
                    },
                    textColor: Colors.deepOrange,
                    child: Text('Pick Audio File'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return AudioPlayerWidget(
        audioUrl: _audioUrl,
        coverImage: _audioImage,
        onImageClose: () {
          setState(() {
            _audioImage = '';
          });
        },
        describtionController: _describtionController,
        getDescibtionDialog: _showDescribtionDialog,
        showImagePicker: () => _showImagePicker(),
      );
    }
  }

  Widget _contentBuilder() {
    return Expanded(
      child: PageView(
        controller: _pageController,
        children: <Widget>[
          _buildTextPostContent(),
          _buildQuestionContent(),
          _buildMediaContent(),
          _buildGifContent(),
          _buildAudioContent(),
        ],
      ),
    );
  }

  Widget _buildQuestionMedia(
    String path, {
    EdgeInsetsGeometry edgeInsetsGeometry,
    int index,
  }) {
    return Padding(
      padding: edgeInsetsGeometry,
      child: Stack(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              height: MediaQuery.of(context).size.height / 3,
              width: MediaQuery.of(context).size.width / 3,
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _questionMedia.remove(_questionMedia[index]);
                });
              },
              child: Container(
                height: 27,
                width: 27,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.close,
                    size: 17,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 5,
            left: 5,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 27,
                width: 27,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.edit,
                    size: 17,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddQuestionMediaPlaceholder() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        _showMediaPickerDialog(maximum: 1);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        height: MediaQuery.of(context).size.height / 3,
        width: MediaQuery.of(context).size.width / 3,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.add,
              size: 25,
              color: Colors.grey,
            ),
            SizedBox(height: 5),
            Text(
              ' Add the second ',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Media',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker() {
    showDialog(
      context: context,
      builder: (context) => Container(
        child: SimpleDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          children: <Widget>[
            ListTile(
              leading: Icon(MdiIcons.cameraBurst),
              title: Text('Pick from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker _picker = ImagePicker();

                PickedFile _file =
                    await _picker.getImage(source: ImageSource.gallery);
                setState(() {
                  _audioImage = _file.path;
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Pick from Camera'),
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker _picker = ImagePicker();
                final PickedFile _file =
                    await _picker.getImage(source: ImageSource.gallery);
                setState(() {
                  _audioImage = _file.path;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaPickerDialog({int maximum}) {
    showDialog(
      context: context,
      builder: (context) => Container(
        child: SimpleDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          children: <Widget>[
            ListTile(
              leading: Icon(MdiIcons.cameraBurst),
              title: Text('Pick from Gallery'),
              onTap: () {
                Navigator.pop(context);
                FilePicker.platform.pickFiles().then((value) {
                  List<MediaUrl> _newValue = List.generate(
                    value.files.length == maximum ||
                            value.files.length < maximum
                        ? value.files.length
                        : maximum,
                    (index) => MediaUrl(
                      mediaUrl: value.files.toList()[index].path,
                      type: value.files.toList()[index].path.endsWith('.mp4')
                          ? '1'
                          : '0',
                    ),
                  );
                  setState(() {
                    _questionMedia.addAll(_newValue);
                    if (_audioUrl != null || _mediaUrl != null) {
                      _isPressed = false;
                      _isPressed2 = true;
                      _isPressed3 = false;
                      _isPressed4 = false;
                      _isPressed5 = false;
                      _isPressed6 = false;
                      _audioUrl = '';
                      _mediaUrl = [];
                    }
                  });
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Pick from Camera'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Camera(),
                  ),
                ).then((value) {
                  MediaUrl _newValue = MediaUrl(
                    mediaUrl: value,
                    type: value.endsWith('.mp4') ? '1' : '0',
                  );
                  setState(() {
                    _questionMedia.add(_newValue);
                    if (_audioUrl != null || _mediaUrl != null) {
                      _audioUrl = '';
                      _mediaUrl = [];
                    }
                  });
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDescribtionDialog() {
    showDialog(
      context: context,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          content: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _describtionController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Your describtion',
                  ),
                  maxLength: 40,
                ),
              )
            ],
          ),
          actions: <Widget>[
            FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  _describtionController.clear();
                  Navigator.pop(context);
                }),
            FlatButton(
                child: const Text('DONE'),
                onPressed: () {
                  if (_describtionController.text.length != 0) {
                    Navigator.pop(context);
                  } else {
                    Fluttertoast.showToast(msg: 'Add your describtion first');
                  }
                })
          ],
        ),
      ),
    );
  }

  void _showCaptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          content: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _captionController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Your caption',
                  ),
                  maxLength: 40,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  _captionController.clear();
                  Navigator.pop(context);
                }),
            FlatButton(
                child: const Text('DONE'),
                onPressed: () {
                  if (_captionController.text.length != 0) {
                    Navigator.pop(context);
                  } else {
                    Fluttertoast.showToast(msg: 'Add your cation first');
                  }
                })
          ],
        ),
      ),
    );
  }

  void onCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure to quit'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('NO'),
          ),
          FlatButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('YES'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    _questionController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _captionController.dispose();
    _giphyCaptionController.dispose();
    super.dispose();
  }

  int getPostType() {
    if (_textController.text.length != 0) {
      return 1;
    } else if (_questionController.text.length != 0 ||
        _questionMedia.length != 0) {
      return 2;
    } else if (_mediaUrl.length != 0) {
      return 3;
    } else if (_gif != null) {
      return 4;
    } else {
      return 5;
    }
  }

  Future<void> validateAndPostContent() async {
    if (_textController.text.length == 0 &&
        _questionController.text.length == 0 &&
        _mediaUrl.length == 0 &&
        _gif == null &&
        _audioUrl == '') {
      Fluttertoast.showToast(msg: 'Create something first');
    } else {
      Question _newQuestion = Question();
      String _newAudioUrl = '';
      String _newAudioImage = '';
      List<MediaUrl> _media = [];
      setState(() => _showLoading = true);
      if (_textController.text.isNotEmpty) {
        await PersonalityService.setTextInput(_textController.text);
      }
      if (_questionMedia.isNotEmpty || _questionMedia.isNotEmpty) {
        await PersonalityService.setImageInput(_questionMedia[0].mediaUrl);
        await PersonalityService.setImageInput(_questionMedia[1].mediaUrl);
        final List<String> _questionFiles =
            await StorageService.uploadMediaFile(
          [File(_questionMedia[0].mediaUrl), File(_questionMedia[1].mediaUrl)],
          'question-media',
        );
        _newQuestion = Question(
          question: _questionController.text,
          option1:
              _option1Controller.text == '' ? 'Yes' : _option1Controller.text,
          option2:
              _option2Controller.text == '' ? 'No' : _option2Controller.text,
          media1: _questionFiles[0],
          media2: _questionFiles[1],
        );
        await PersonalityService.setTextInput(
          '${_newQuestion.question}? ${_newQuestion.option1} or ${_newQuestion.option2}',
        );
      } else {
        _newQuestion = Question(
          question: _questionController.text,
          option1:
              _option1Controller.text == '' ? 'Yes' : _option1Controller.text,
          option2:
              _option2Controller.text == '' ? 'No' : _option2Controller.text,
        );
        if (_newQuestion.question.isNotEmpty) {
          await PersonalityService.setTextInput(
            '${_newQuestion.question}? ${_newQuestion.option1} or ${_newQuestion.option2}',
          );
        }
      }

      if (_audioUrl.isNotEmpty) {
        await PersonalityService.setAudioInput(_audioUrl);
        final List<String> audioUrl = await StorageService.uploadMediaFile(
          [File(_audioUrl)],
          'post-media',
        );
        _newAudioUrl = audioUrl.first;
      } else {
        _newAudioUrl = '';
      }

      if (_audioImage != '') {
        await PersonalityService.setImageInput(_audioImage);
        final List<String> audioImage = await StorageService.uploadMediaFile(
          [File(_audioImage)],
          'post-media/audios/media',
        );
        _newAudioImage = audioImage.first;
      } else {
        _newAudioImage = '';
      }

      if (_mediaUrl.isNotEmpty) {
        for (MediaUrl media in _mediaUrl) {
          if (media.type == '0') {
            await PersonalityService.setImageInput(media.mediaUrl);
          } else {
            await PersonalityService.setVideoInput(media.mediaUrl);
          }
        }
        final List<String> uploadedmedia = await StorageService.uploadMediaFile(
            _mediaUrl
                .map(
                  (e) => File(e.mediaUrl),
                )
                .toList(),
            'post-media');
        _media = uploadedmedia
            .map((e) => MediaUrl(
                  mediaUrl: e,
                  type: e.contains('.jpg') ? '0' : '1',
                ))
            .toList();
      } else {
        _media = [];
      }
      if (_giphyCaptionController.text.isNotEmpty) {
        await PersonalityService.setTextInput(_giphyCaptionController.text);
      }

      final Post _newPost = Post(
        authorId: _userId,
        authorName: _userName,
        authorImage: _userImage,
        text: _textController.text,
        question: {
          'question': _newQuestion.question,
          'option1': _newQuestion.option1,
          'option2': _newQuestion.option2,
          'media1': _newQuestion.media1,
          'media2': _newQuestion.media2,
        },
        mediaUrl: _media
            .map((v) => {
                  'media': v.mediaUrl,
                  'type': v.type,
                })
            .toList(),
        caption: _captionController.text,
        audioUrl: _newAudioUrl,
        audioImage: _newAudioImage,
        audioDescribtion: _describtionController.text,
        gif: {
          'gif': _gif == null ? '' : _gif?.images?.original?.url,
          'caption': _giphyCaptionController.text,
        },
        timestamp: DateTime.now().toUtc().toString(),
        authorPersonality: _personalityType,
        location: _userLocation,
        type: getPostType(),
      );
      DatabaseService.addPost(_newPost, false, '', 'created');
      NotificationsService.sendNotificationToFollowers(
        'New Post',
        '$_userName uploaded a new post',
        _userId,
      );
      Navigator.pop(context);
      setState(() => _showLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _showLoading == true
              ? Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                    backgroundColor: Colors.black45,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _buildTopButton(
                      Icons.close,
                      'close',
                      7,
                      () {
                        if (_audioUrl != null &&
                            _questionController.text.length == 0 &&
                            _option1Controller.text.length == 0 &&
                            _option2Controller.text.length == 0 &&
                            _questionMedia.length == 0 &&
                            _textController.text.length == 0 &&
                            _mediaUrl.length == 0 &&
                            _gif == null) {
                          Navigator.pop(context);
                        } else {
                          onCancelDialog();
                        }
                      },
                    ),
                    _buildTopButton(
                      Icons.check,
                      'done',
                      7,
                      () {
                        validateAndPostContent();
                      },
                    ),
                  ],
                ),
          Divider(),
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  _userImage == null
                      ? Container(
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          child: CircleAvatar(
                            backgroundColor: Colors.grey[400],
                            child: Icon(
                              Icons.person,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: CachedNetworkImage(
                              imageUrl: _userImage,
                              fit: BoxFit.cover,
                              height: 45,
                              width: 45,
                            ),
                          ),
                        ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName == null ? 'Loading...' : _userName,
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'now',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 17, left: 5),
                    child: Text(
                      '.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  _userLocation != null
                      ? Container(
                          margin: EdgeInsets.only(
                            bottom: 10,
                            left: 3,
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.location_on,
                                color: Colors.grey[600],
                                size: 13,
                              ),
                              SizedBox(width: 3),
                              Text(
                                _userLocation,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          height: 20,
                          margin: EdgeInsets.only(bottom: 12, left: 7),
                          child: OutlineButton(
                            borderSide: BorderSide(color: Colors.black),
                            onPressed: () {
                              getUserLocation();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Icon(
                                  Icons.location_on,
                                  size: 12,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'add current Location',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                ],
              ),
              Divider(),
            ],
          ),
          _contentBuilder(),
          _buildOptionsBar(),
        ],
      ),
    );
  }
}

class VideoThumbWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onRemove;
  VideoThumbWidget({this.videoUrl, this.onRemove});

  @override
  State<StatefulWidget> createState() {
    return _VideoThumbWidgetState();
  }
}

class _VideoThumbWidgetState extends State<VideoThumbWidget> {
  String _path;

  @override
  void initState() {
    super.initState();
    getThumb();
  }

  void getThumb() async {
    var status = await perm.Permission.storage.request();
    if (status.isGranted) {
      String _retrievedFilePath = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl == null ? '' : widget.videoUrl,
      );
      if (mounted)
        setState(() {
          _path = _retrievedFilePath;
        });
    } else {
      perm.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Card(
        elevation: 2.2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: <Widget>[
            _path == null
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_path),
                        height: 400,
                        width: 400,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  height: 30,
                  width: 30,
                  margin: EdgeInsets.only(right: 10, top: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 65,
                height: 65,
                child: FlatButton(
                  shape: CircleBorder(
                    side: BorderSide(
                      color: Colors.white,
                      width: 2.5,
                    ),
                  ),
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            VideoWidget(videoPath: widget.videoUrl),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  height: 30,
                  width: 30,
                  margin: EdgeInsets.only(left: 10, bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.edit,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoQuestionThumbWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onRemove;
  VideoQuestionThumbWidget({this.videoUrl, this.onRemove});

  @override
  State<StatefulWidget> createState() {
    return _VideoQuestionThumbWidgetState();
  }
}

class _VideoQuestionThumbWidgetState extends State<VideoQuestionThumbWidget> {
  String _path;

  @override
  void initState() {
    super.initState();
    getThumb();
  }

  void getThumb() async {
    var status = await perm.Permission.storage.request();
    if (status.isGranted) {
      String _retrievedFilePath = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl == null ? '' : widget.videoUrl,
      );
      setState(() {
        _path = _retrievedFilePath;
      });
    } else {
      perm.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _path == null
        ? Container()
        : Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_path),
                    height: MediaQuery.of(context).size.height / 3,
                    width: MediaQuery.of(context).size.width / 3,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: widget.onRemove,
                    child: Container(
                      height: 25,
                      width: 25,
                      margin: EdgeInsets.only(right: 15, top: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 35,
                    height: 35,
                    child: FlatButton(
                      padding: EdgeInsets.all(0),
                      shape: CircleBorder(
                        side: BorderSide(
                          color: Colors.white,
                          width: 2.5,
                        ),
                      ),
                      color: Colors.blue,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                VideoWidget(videoPath: widget.videoUrl),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}

class VideoWidget extends StatefulWidget {
  final String videoPath;
  VideoWidget({Key key, this.videoPath}) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  VideoPlayerController _controller;
  double _opacity = 1.0;

  String get _duration =>
      _controller.value.duration?.toString()?.substring(2)?.split('.')?.first ??
      '';
  String get _position =>
      _controller.value.position?.toString()?.substring(2)?.split('.')?.first ??
      '';

  void _listener() {
    setState(() {
      if (_position == _duration) {
        _opacity = 1.0;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(
      widget.videoPath,
    );
    initFuture();
    _controller.addListener(_listener);
    print(widget.videoPath);
    _controller.initialize().then((_) => setState(() {}));
    _controller.play();
  }

  void initFuture() async {
    await Future.delayed(Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _controller.dispose();
    _controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_opacity == 1.0) {
            _opacity = 0.0;
          } else {
            _opacity = 1.0;
          }
        });
      },
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size?.width ?? 0,
                  height: _controller.value.size?.height ?? 0,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 25,
                  horizontal: 10,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  iconSize: 35,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            Center(
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: Duration(milliseconds: 350),
                curve: Curves.easeIn,
                child: FlatButton(
                  shape: CircleBorder(),
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                        print(widget.videoPath);
                      } else if (!_controller.value.isPlaying &&
                          _position != _duration) {
                        _controller.play();
                        _opacity = 0.0;
                      } else if (_position == _duration) {
                        _controller.seekTo(Duration.zero);
                        _controller.play();
                        _opacity = 0.0;
                      } else {
                        return;
                      }
                    });
                  },
                  child: FaIcon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : _position == _duration
                            ? Icons.replay
                            : Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AudioRecorderPage extends StatefulWidget {
  AudioRecorderPage({Key key}) : super(key: key);

  @override
  _AudioRecorderPageState createState() => _AudioRecorderPageState();
}

class _AudioRecorderPageState extends State<AudioRecorderPage>
    with SingleTickerProviderStateMixin {
  double _recordOpacity = 1.0;
  String _audioUrl;
  String _conditiontxt = 'Tap to record';
  AnimationController _controller;
  Animation<double> _fadeAnimation;
  FlutterSoundRecorder _recorder;
  StopWatchTimer _stopWatchTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.decelerate,
      ),
    );
    _recorder = FlutterSoundRecorder();
    _stopWatchTimer = StopWatchTimer();
    initRecorder();
  }

  Future<void> initRecorder() async {
    await _recorder.openAudioSession(
      focus: AudioFocus.requestFocusAndStopOthers,
      category: SessionCategory.playAndRecord,
      mode: SessionMode.modeDefault,
      device: AudioDevice.speaker,
    );
  }

  Future<void> releaseFlauto() async {
    try {
      await _recorder.closeAudioSession();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to close recorder');
    }
  }

  void _startRecording() async {
    try {
      final filePath = await getFilePath();
      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.mp3,
        numChannels: 1,
        sampleRate: 8000,
      );
      _stopWatchTimer.onExecute.add(StopWatchExecute.start);
      setState(() {
        _conditiontxt = 'Recording...';
      });
    } catch (_) {
      Fluttertoast.showToast(msg: 'Failed to record');
    }
  }

  Future<String> getFilePath() async {
    Directory appDirectory = await getApplicationDocumentsDirectory();
    String appPath = appDirectory.path + "/record";
    var d = Directory(appPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return appPath + "/audio.mp3";
  }

  void _stopRecording() async {
    await _recorder.stopRecorder();
    _stopWatchTimer.onExecute.add(StopWatchExecute.stop);
    final _filePath = await getFilePath();
    _audioUrl = _filePath;
    setState(() {
      _conditiontxt = 'Done';
    });
    Timer(
      Duration(milliseconds: 500),
      () => Navigator.pop(context, _audioUrl),
    );
  }

  @override
  void dispose() {
    _stopWatchTimer.dispose();
    releaseFlauto();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder(
                stream: _stopWatchTimer.secondTime,
                builder: (context, AsyncSnapshot<int> snapshot) {
                  return Text(
                    snapshot.data == 0 ? '00.00' : snapshot.data.toString(),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 24,
                    ),
                  );
                }),
            SizedBox(height: 20),
            Container(
              width: 120,
              height: 120,
              child: RaisedButton(
                color: Colors.redAccent,
                shape: CircleBorder(),
                onPressed: () {
                  if (_recordOpacity == 1.0) {
                    _startRecording();
                    setState(() {
                      _recordOpacity = 0.0;
                    });
                    _controller.repeat();
                  } else {
                    _stopRecording();
                    _controller.reverse();
                    setState(() {
                      _recordOpacity = 1.0;
                    });
                  }
                },
                child: _recordOpacity == 0.0
                    ? FadeTransition(
                        opacity: _fadeAnimation,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                        ),
                      )
                    : AnimatedOpacity(
                        duration: Duration(milliseconds: 100),
                        curve: Curves.fastLinearToSlowEaseIn,
                        opacity: _recordOpacity,
                        child: Icon(
                          MdiIcons.microphone,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 15),
            Text(
              _conditiontxt,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 22,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final VoidCallback showImagePicker;
  final VoidCallback onImageClose;
  final VoidCallback getDescibtionDialog;
  final TextEditingController describtionController;
  final String audioUrl;
  final String coverImage;
  AudioPlayerWidget({
    Key key,
    this.showImagePicker,
    this.onImageClose,
    this.getDescibtionDialog,
    this.describtionController,
    this.audioUrl,
    this.coverImage,
  }) : super(key: key);

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  Duration _audioPosition;
  Duration _audioDuration;
  PlayerState _playerState;
  StreamSubscription<Duration> _durationStream;
  StreamSubscription<Duration> _positionStream;
  StreamSubscription<void> _onCompleteStream;
  AudioPlayer _audioPlayer;
  bool get _isPlaying => _playerState == PlayerState.playing;
  bool get _isPaused => _playerState == PlayerState.paused;
  bool get _isStopped => _playerState == PlayerState.stopped;
  String get _durationText =>
      _audioDuration?.toString()?.substring(2)?.split('.')?.first ?? '';
  String get _positionText =>
      _audioPosition?.toString()?.substring(2)?.split('.')?.first ?? '';

  @override
  void initState() {
    super.initState();
    _prepareAudioStreaming();
  }

  void _prepareAudioStreaming() {
    _audioPlayer = AudioPlayer();
    _durationStream = _audioPlayer.onDurationChanged.listen(
      (Duration duration) => setState(() {
        _audioDuration = duration;
      }),
    );
    _positionStream = _audioPlayer.onAudioPositionChanged.listen(
      (Duration duration) => setState(() {
        _audioPosition = duration;
      }),
    );
    _onCompleteStream = _audioPlayer.onPlayerCompletion.listen(
      (_) => setState(() {
        _playerState = PlayerState.stopped;
      }),
    );
  }

  Future<int> _play() async {
    final playPosition = (_audioPosition != null &&
            _audioPosition != null &&
            _audioPosition.inSeconds > 0 &&
            _audioPosition.inSeconds < _audioPosition.inSeconds)
        ? _audioPosition
        : null;
    final result = await _audioPlayer.play(
      widget.audioUrl,
      isLocal: true,
      position: playPosition,
    );
    if (result == 1) setState(() => _playerState = PlayerState.playing);

    // default playback rate is 1.0
    // this should be called after _audioPlayer.play() or _audioPlayer.resume()
    // this can also be called everytime the user wants to change playback rate in the UI
    _audioPlayer.setPlaybackRate(playbackRate: 1.0);

    return result;
  }

  Future<int> _pause() async {
    final result = await _audioPlayer.pause();
    if (result == 1) setState(() => _playerState = PlayerState.paused);
    return result;
  }

  void _seekToSecond(int second) {
    final Duration _newDuration = Duration(seconds: second);
    _audioPlayer.seek(_newDuration);
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _durationStream?.cancel();
    _positionStream?.cancel();
    _onCompleteStream?.cancel();
    super.dispose();
  }

  IconData _getButtonIcon() {
    if (_isPlaying) {
      return Icons.pause;
    } else if (_isPaused) {
      return Icons.play_arrow;
    } else if (_isStopped) {
      return Icons.replay;
    } else {
      return Icons.play_arrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width - 50,
        height: MediaQuery.of(context).size.height / 2,
        child: Card(
          elevation: 20,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: <Widget>[
              Visibility(
                child: Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(widget.coverImage == '' ? '' : widget.coverImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                visible: widget.coverImage != '',
              ),
              Visibility(
                child: Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 2,
                        sigmaY: 2,
                      ),
                      child: Container(
                        color: Colors.grey.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                visible: widget.coverImage != '',
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Icon(
                    MdiIcons.headphones,
                    size: 80,
                    color: Colors.deepOrangeAccent,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: widget.coverImage == ''
                    ? Container(
                        width: 131,
                        height: 30,
                        margin: EdgeInsets.only(top: 5, right: 5),
                        child: FlatButton(
                          color: Colors.black.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onPressed: () => widget.showImagePicker(),
                          child: Row(
                            children: <Widget>[
                              SizedBox(width: 5),
                              Icon(
                                Icons.add_photo_alternate,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'cover Image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => widget.onImageClose(),
                        child: Container(
                          height: 35,
                          width: 35,
                          margin: EdgeInsets.only(right: 10, top: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
              Align(
                alignment: Alignment(0.0, 0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Text(
                      _audioPosition != null ? '${_positionText ?? ''}' : '',
                      style: TextStyle(fontSize: 15.0),
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                      ),
                      child: Slider(
                        onChanged: (value) {
                          setState(() {
                            _seekToSecond(value.toInt());
                            value = value;
                          });
                        },
                        min: 0.0,
                        max: (_audioDuration != null &&
                                _audioPosition != null &&
                                _audioPosition.inSeconds > 0 &&
                                _audioPosition.inSeconds <
                                    _audioDuration.inSeconds)
                            ? _audioDuration.inSeconds.toDouble()
                            : 1.0,
                        value: (_audioPosition != null &&
                                _audioDuration != null &&
                                _audioPosition.inSeconds > 0 &&
                                _audioPosition.inSeconds <
                                    _audioDuration.inSeconds)
                            ? _audioPosition.inSeconds.toDouble()
                            : 0.0,
                        activeColor: Colors.deepOrange,
                        inactiveColor: Colors.deepOrange.withOpacity(0.3),
                      ),
                    ),
                    Text(
                      _audioDuration != null ? '${_durationText ?? ''}' : '',
                      style: TextStyle(fontSize: 15.0),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment(0.0, 0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Container(
                      height: 50,
                      width: 50,
                      child: widget.coverImage != ''
                          ? RaisedButton(
                              shape: CircleBorder(),
                              color: Colors.deepOrange,
                              onPressed: () {
                                _seekToSecond(
                                  _audioPosition.inSeconds < 10
                                      ? 0
                                      : _audioPosition.inSeconds - 10,
                                );
                              },
                              child: Icon(
                                MdiIcons.rewind10,
                                color: Colors.white,
                              ),
                            )
                          : FlatButton(
                              shape: CircleBorder(),
                              onPressed: () {
                                _seekToSecond(
                                  _audioPosition.inSeconds < 10
                                      ? 0
                                      : _audioPosition.inSeconds - 10,
                                );
                              },
                              child: Icon(MdiIcons.rewind10),
                            ),
                    ),
                    Container(
                      height: 60,
                      width: 60,
                      child: widget.coverImage != ''
                          ? RaisedButton(
                              shape: CircleBorder(),
                              color: Colors.deepOrange,
                              onPressed: () {
                                if (_isPlaying) {
                                  _pause();
                                } else {
                                  _play();
                                }
                              },
                              child: Icon(
                                _getButtonIcon(),
                                color: Colors.white,
                              ),
                            )
                          : OutlineButton(
                              shape: CircleBorder(),
                              borderSide: BorderSide(color: Colors.black),
                              onPressed: () {
                                if (_isPlaying) {
                                  _pause();
                                } else {
                                  _play();
                                }
                              },
                              child: Icon(
                                _getButtonIcon(),
                              ),
                            ),
                    ),
                    Container(
                      height: 50,
                      width: 50,
                      child: widget.coverImage != ''
                          ? RaisedButton(
                              shape: CircleBorder(),
                              color: Colors.deepOrange,
                              onPressed: () {
                                if (_audioPosition.inSeconds <
                                    _audioDuration.inSeconds) {
                                  _seekToSecond(
                                    _audioPosition.inSeconds >
                                            _audioDuration.inSeconds - 10
                                        ? _audioPosition.inSeconds +
                                            (_audioDuration.inSeconds -
                                                _audioPosition.inSeconds)
                                        : _audioPosition.inSeconds + 10,
                                  );
                                }
                              },
                              child: Icon(
                                MdiIcons.fastForward10,
                                color: Colors.white,
                              ),
                            )
                          : FlatButton(
                              shape: CircleBorder(),
                              onPressed: () {
                                if (_audioPosition.inSeconds <
                                    _audioDuration.inSeconds) {
                                  _seekToSecond(
                                    _audioPosition.inSeconds >
                                            _audioDuration.inSeconds - 10
                                        ? _audioPosition.inSeconds +
                                            (_audioDuration.inSeconds -
                                                _audioPosition.inSeconds)
                                        : _audioPosition.inSeconds + 10,
                                  );
                                }
                              },
                              child: Icon(MdiIcons.fastForward10),
                            ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    color: widget.coverImage != null
                        ? Colors.black.withOpacity(0.5)
                        : Colors.deepOrange.withOpacity(0.8),
                  ),
                  child: widget.describtionController.text.length != 0
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Center(
                            child: Row(
                              children: <Widget>[
                                Text(
                                  widget.describtionController.text,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Bounce(
                                  onPressed: widget.getDescibtionDialog,
                                  duration: Duration(milliseconds: 100),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              width: 200,
                              height: 30,
                              child: OutlineButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                borderSide: BorderSide(color: Colors.white),
                                onPressed: widget.getDescibtionDialog,
                                color: widget.coverImage == null
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.transparent,
                                textColor: Colors.white,
                                child: Text('Add Description'),
                              ),
                            ),
                          ],
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

class MediaUrl {
  String mediaUrl;
  String type;
  MediaUrl({this.mediaUrl, this.type});
}
