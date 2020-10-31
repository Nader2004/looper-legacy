import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:looper/services/personality.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shifting_tabbar/shifting_tabbar.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/loveCardModel.dart';
import '../models/loverCardModel.dart';
import '../services/database.dart';
import '../services/storage.dart';

class LoveCreation extends StatefulWidget {
  LoveCreation({Key key}) : super(key: key);

  @override
  _LoveCreationState createState() => _LoveCreationState();
}

class _LoveCreationState extends State<LoveCreation>
    with SingleTickerProviderStateMixin {
  static RangeValues _ageRange = RangeValues(18, 40);
  static String _hairColor = '';
  static String _faceShape = '';
  static String _eyeColor = '';
  static List<String> traits = [];
  static List<String> qualities = [];
  static Map<String, int> selectedAgeRange = {
    'min': _ageRange.start.toInt(),
    'max': _ageRange.end.toInt(),
  };
  static Map<String, String> look = {
    'hairColor': _hairColor,
    'faceShape': _faceShape,
    'eyeColor': _eyeColor,
  };

  bool _showLoading = false;
  String _userId = '';
  String _userName = '';
  String _userImage = '';
  String _userGender = '';
  String _userLocation = '';
  int _userAge = 0;
  Location location = Location();
  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  LocationData _locationData;
  String _datingPhoto = '';
  Map<String, dynamic> _personalityType;
  double _redWidth = 0.0;
  double _redHeight = 0.0;
  double _yellowWidth = 0.0;
  double _yellowHeight = 0.0;
  double _brownWidth = 0.0;
  double _brownHeight = 0.0;
  double _blackWidth = 0.0;
  double _blackHeight = 0.0;

  @override
  void initState() {
    super.initState();
    setUPCurrentUserLocationName();
    getUserData();
  }

  void getUserData() async {
    setPrefs();
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final DocumentSnapshot _snapshot =
        await _firestore.collection('users').doc(_prefs.get('id')).get();
    final _userBirthDate = _snapshot?.data()['birthdate'];
    final int _month = DateTime(1, _userBirthDate['month']).month;
    final int _numberofMonthDays = DateTime(1, _userBirthDate['month']).day;
    final DateTime _userCalculatedAge = DateTime.now().subtract(
      Duration(
        days: (_userBirthDate['day'] +
            (_month * _numberofMonthDays) +
            (_userBirthDate['year'] * 365)),
      ),
    );
    _userName = _snapshot?.data()['username'];
    _userAge = _userCalculatedAge.year;
    _userImage = _snapshot?.data()['profilePictureUrl'];
    _personalityType = _snapshot?.data()['personality-type'];
    _userGender = _snapshot?.data()['gender'];
    _userId = _prefs.get('id');
  }

  void setUPCurrentUserLocationName() async {
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
        _userLocation = '${_address.countryName} , ${_address.adminArea}';
      }
    }
  }

  Future<void> sendLoveCard() async {
    if (_datingPhoto == '') {
      Fluttertoast.showToast(msg: 'Fill the data first');
    } else {
      setState(() => _showLoading = true);
      final List<String> _datingPictureUrl =
          await StorageService.uploadMediaFile(
        [File(_datingPhoto)],
        'love-cards-media',
      );
      final LoveCard _newLoveCard = LoveCard(
        authorId: _userId,
        authorName: _userName,
        authorAge: _userAge,
        authorImage: _userImage,
        imageUrl: _datingPictureUrl.first,
        qualities: qualities,
        location: _userLocation,
        authorPersonality: _personalityType,
        timestamp: DateTime.now().toUtc().toString(),
      );
      await PersonalityService.setImageInput(
        _newLoveCard.imageUrl,
      );
      DatabaseService.addLoveCard(_newLoveCard);
      setState(() => _showLoading = false);
      Fluttertoast.showToast(msg: 'Love card created');
      Navigator.pop(context);
    }
  }

  void sendLoverCard() async {
    if (traits.isEmpty ||
        _hairColor.isEmpty ||
        _eyeColor.isEmpty ||
        _faceShape.isEmpty) {
      Fluttertoast.showToast(msg: 'Fill the data first');
    } else {
      final LoverCard _newLoverCard = LoverCard(
        authorId: _userId,
        authorName: _userName,
        authorAge: _userAge,
        gender: _userGender,
        authorImage: _userImage,
        lookQualities: look,
        qualities: traits,
        ageRange: selectedAgeRange,
        timestamp: DateTime.now().toUtc().toString(),
      );
      await PersonalityService.setTextInput(
        'I would like a Person who is ${_newLoverCard.qualities} and might have a ${_newLoverCard.lookQualities['hairColor']} hair and ${_newLoverCard.lookQualities['eyeColor']} eyes and and a ${_newLoverCard.lookQualities['faceShape']} face shape too.',
      );
      DatabaseService.addLoverCard(_newLoverCard);
      Fluttertoast.showToast(msg: 'Lover card created');
      Navigator.pop(context);
    }
  }

  Widget _loveSendButton({int index}) {
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          sendLoveCard();
        } else if (index == 1) {
          sendLoverCard();
        } else {
          return;
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width / 2.4,
        height: MediaQuery.of(context).size.height / 13,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            List: [
              Colors.red[300],
              Colors.red[900],
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[500],
              offset: Offset(4.0, 4.0),
              blurRadius: 15.0,
              spreadRadius: 1.0,
            ),
            BoxShadow(
              color: Colors.white,
              offset: Offset(-4.0, -4.0),
              blurRadius: 15.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Send',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            SizedBox(width: 3),
            Icon(
              Icons.favorite,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLookPart() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Text(
            'Look',
            style: GoogleFonts.quicksand(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Divider(),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Hair color',
            style: GoogleFonts.quicksand(
              fontSize: 28,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _hairColor = 'Black';
                        _yellowHeight = 0.0;
                        _yellowWidth = 0.0;
                        _redHeight = 0.0;
                        _redWidth = 0.0;
                        _brownHeight = 0.0;
                        _brownWidth = 0.0;
                        _blackHeight = 10.0;
                        _blackWidth = 10.0;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      width: 45,
                      height: 45,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    width: _blackWidth,
                    height: _blackHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _hairColor = 'Brown';
                        _yellowHeight = 0.0;
                        _yellowWidth = 0.0;
                        _redHeight = 0.0;
                        _redWidth = 0.0;
                        _brownHeight = 10.0;
                        _brownWidth = 10.0;
                        _blackHeight = 0.0;
                        _blackWidth = 0.0;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      width: 45,
                      height: 45,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: Colors.brown,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    width: _brownWidth,
                    height: _brownHeight,
                    decoration: BoxDecoration(
                      color: Colors.brown,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _hairColor = 'Yellow';
                        _yellowHeight = 10.0;
                        _yellowWidth = 10.0;
                        _redHeight = 0.0;
                        _redWidth = 0.0;
                        _brownHeight = 0.0;
                        _brownWidth = 0.0;
                        _blackHeight = 0.0;
                        _blackWidth = 0.0;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      width: 45,
                      height: 45,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: Colors.yellow,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    width: _yellowWidth,
                    height: _yellowHeight,
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _hairColor = 'Red';
                        _redWidth = 10;
                        _redHeight = 10;
                        _yellowHeight = 0.0;
                        _yellowWidth = 0.0;
                        _brownHeight = 0.0;
                        _brownWidth = 0.0;
                        _blackHeight = 0.0;
                        _blackWidth = 0.0;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      width: 45,
                      height: 45,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: Colors.red,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    width: _redWidth,
                    height: _redHeight,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            'Face shape',
            style: GoogleFonts.quicksand(
              fontSize: 28,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 15),
          child: Row(
            children: <Widget>[
              _buildFaceShapeWidget(
                ClipOval(
                  child: Container(
                    color: Colors.grey[300],
                    height: 40.0,
                    width: 30.0,
                  ),
                ),
                'Oval',
                onPressed: () => setState(() => _faceShape = 'Oval'),
                condition: _faceShape == 'Oval',
              ),
              _buildFaceShapeWidget(
                Container(
                  height: 40.0,
                  width: 40.0,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                'Round',
                onPressed: () => setState(() => _faceShape = 'Round'),
                condition: _faceShape == 'Round',
              ),
              _buildFaceShapeWidget(
                Container(
                  height: 40.0,
                  width: 40.0,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                'Square',
                onPressed: () => setState(() => _faceShape = 'Square'),
                condition: _faceShape == 'Square',
              ),
            ],
          ),
        ),
        Divider(),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Text(
            'Eye Color',
            style: GoogleFonts.quicksand(
              fontSize: 28,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            children: <Widget>[
              _buildEyeColorWidget(
                Colors.black,
                'Black',
                onPressed: () => setState(() => _eyeColor = 'Black'),
                condition: _eyeColor == 'Black',
              ),
              _buildEyeColorWidget(
                Colors.brown,
                'Brown',
                onPressed: () => setState(() => _eyeColor = 'Brown'),
                condition: _eyeColor == 'Brown',
              ),
              _buildEyeColorWidget(
                Colors.blue,
                'Blue',
                onPressed: () => setState(() => _eyeColor = 'Blue'),
                condition: _eyeColor == 'Blue',
              ),
              _buildEyeColorWidget(
                Colors.green,
                'Green',
                onPressed: () => setState(() => _eyeColor = 'Green'),
                condition: _eyeColor == 'Green',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaceShapeWidget(Widget primary, String describtion,
      {VoidCallback onPressed, bool condition}) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: condition ? Colors.blue : Colors.transparent,
            ),
          ),
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 7),
              primary,
              SizedBox(height: 7),
              Text(
                describtion,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEyeColorWidget(Color color, String describtion,
      {VoidCallback onPressed, bool condition}) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: condition ? color : Colors.transparent,
            ),
          ),
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 7),
              Image.asset(
                'assets/eye.png',
                height: 35,
                width: 35,
                color: color,
              ),
              SizedBox(height: 7),
              Text(
                describtion,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalityTraitsPart() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 10,
            ),
            child: Text(
              'Choose Traits',
              style: GoogleFonts.quicksand(
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _buildCharTrait('funny', Colors.yellow[700]),
              _buildCharTrait('serious', Colors.brown),
              _buildCharTrait('social', Colors.green),
              _buildCharTrait('wise', Colors.grey),
              _buildCharTrait('honest', Colors.indigo),
              _buildCharTrait('nice', Colors.purple),
              _buildCharTrait('friendly', Colors.amber),
              _buildCharTrait('smart', Colors.blue),
              _buildCharTrait('hard worker', Colors.black),
              _buildCharTrait('active', Colors.deepOrange),
              _buildCharTrait('thinker', Colors.cyan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharTrait(String label, Color color) {
    return ChoiceChip(
      selected: traits.contains(label),
      onSelected: (bool selected) {
        setState(() {
          if (traits.contains(label)) {
            traits.remove(label);
          } else {
            traits.add(label);
          }
        });
      },
      labelPadding: EdgeInsets.all(5.0),
      avatar: CircleAvatar(
        backgroundColor: Colors.grey.shade600,
        child: Text(label[0].toUpperCase()),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      elevation: 6.0,
      shadowColor: Colors.grey[60],
      padding: EdgeInsets.all(6.0),
    );
  }

  Widget _buildAgeRangePart() {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 10),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 10,
            ),
            child: Text(
              'Age Range',
              style: GoogleFonts.quicksand(
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: RangeSlider(
              activeColor: Colors.deepPurple,
              min: 0,
              max: 120,
              divisions: 120,
              labels: RangeLabels(
                '${_ageRange.start.toInt()}',
                '${_ageRange.end.toInt()}',
              ),
              values: _ageRange,
              onChanged: (RangeValues values) {
                setState(() {
                  _ageRange = values;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMediaPicker() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: 116,
          child: Column(
            children: <Widget>[
              ListTile(
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker _picker = ImagePicker();

                  final PickedFile _file =
                      await _picker.getImage(source: ImageSource.camera);
                  if (_file != null) {
                    setState(() {
                      _datingPhoto = _file.path;
                    });
                  }
                },
                title: Text('Take a Photo'),
              ),
              ListTile(
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker _picker = ImagePicker();

                  final PickedFile _file =
                      await _picker.getImage(source: ImageSource.gallery);
                  setState(() {
                    _datingPhoto = _file.path;
                  });
                },
                title: Text('Get from Gallery'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) => Scaffold(
          floatingActionButton: _loveSendButton(
            index: DefaultTabController.of(context).index,
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          appBar: ShiftingTabBar(
            color: Colors.white,
            tabs: [
              ShiftingTab(
                icon: Icon(MdiIcons.cardsHeart),
                text: 'Your Card',
              ),
              ShiftingTab(
                icon: Icon(MdiIcons.accountHeart),
                text: 'Lover Card',
              ),
            ],
          ),
          body: TabBarView(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _showLoading == true
                      ? LinearProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.black),
                          backgroundColor: Colors.black.withOpacity(0.3),
                        )
                      : Container(),
                  Container(
                    height: MediaQuery.of(context).size.height / 2.4,
                    width: MediaQuery.of(context).size.width - 80,
                    child: GestureDetector(
                      onTap: _showMediaPicker,
                      child: Card(
                        shape: SuperellipseShape(
                          borderRadius: BorderRadius.circular(56),
                        ),
                        color: Colors.grey[100],
                        child: _datingPhoto.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.file(
                                  File(_datingPhoto),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: FaIcon(
                                  FontAwesomeIcons.plus,
                                  size: 45,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Column(
                    children: <Widget>[
                      Text(
                        'Add just a photo',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'We\'ll take care of the rest 😉',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ],
              ),
              SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _buildLookPart(),
                    Divider(),
                    _buildPersonalityTraitsPart(),
                    Divider(),
                    _buildAgeRangePart(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
