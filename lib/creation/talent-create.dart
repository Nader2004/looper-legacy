import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/services/personality.dart';
import 'package:looper/services/storage.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:video_player/video_player.dart';

import '../models/talentModel.dart';
import '../services/database.dart';

class TalentCreation extends StatefulWidget {
  TalentCreation({Key key}) : super(key: key);

  @override
  _TalentCreationState createState() => _TalentCreationState();
}

class _TalentCreationState extends State<TalentCreation>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Widget _bottomBar;
  Timer _timer;
  String _talentName = 'Singing';
  String _videoPath = '';
  String _title = '';
  String _filterName = '';

  int _selectedCameraIndex;
  int _start = 3;
  int _minutes = 1;
  double _opacity = 1.0;
  bool _startRecording = false;
  bool _startedCounting = false;
  bool _timerChanged = false;
  bool _addSpeedPainting = false;
  bool _addSongTitle = false;
  bool _addDancingTitle = false;
  bool _addMagicTitle = false;
  bool _addTalentTitle = false;
  IconData _iconTalent = MdiIcons.microphoneVariant;
  CameraController _cameraController;
  List<CameraDescription> _cameras;
  Future<void> _initializeControllerFuture;
  AnimationController _animationController;
  MovieFilter _cameraFilter = MovieFilter(
    filterColors: [Colors.white, Colors.white],
    blendMode: BlendMode.dst,
  );
  List<MovieFilter> _movieFilters = <MovieFilter>[
    MovieFilter(
      filterColors: [Colors.white, Colors.white],
      blendMode: BlendMode.dst,
    ),
    MovieFilter(
      filterColors: [Colors.black, Colors.white],
      blendMode: BlendMode.hue,
    ),
    MovieFilter(
      filterColors: [Color(0xFF704214), Colors.brown],
      blendMode: BlendMode.color,
    ),
    MovieFilter(
      filterColors: [Colors.red, Colors.red[700]],
      blendMode: BlendMode.colorBurn,
    ),
    MovieFilter(
      filterColors: [
        Color(0xFFF8EFB6),
        Color(0xFFD09C8E),
        Color(0xFFD77067),
        Color(0xFF724559),
      ],
      blendMode: BlendMode.color,
    ),
    MovieFilter(
      filterColors: [
        Color(0xFF191a1b),
        Color(0xFFc8dde7),
        Color(0xFFa8d3e3),
        Color(0xFF394346),
        Color(0xFF293135),
      ],
      blendMode: BlendMode.difference,
    ),
    MovieFilter(
      filterColors: [Colors.yellow, Colors.red, Colors.greenAccent],
      blendMode: BlendMode.exclusion,
    ),
  ];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _songNameController = TextEditingController();
  final TextEditingController _talentNameController = TextEditingController();
  final TextEditingController _danceNameController = TextEditingController();
  final TextEditingController _magicTrickNameController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeAnimation();
    initializeCamera();
    _bottomBar = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 5),
            child: OutlineButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              borderSide: BorderSide(
                color: Colors.green,
              ),
              onPressed: () {
                _showTalentNameInputDialog(
                  _songNameController,
                  'song name',
                );
              },
              textColor: Colors.green,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    MdiIcons.musicNotePlus,
                    size: 22,
                    color: Colors.green,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Song name',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.length > 0) {
      setState(() {
        _selectedCameraIndex = 0;
      });
      _initCameraController(_cameras[_selectedCameraIndex]);
    } else {
      _showCameraException('There are no cameras in this device');
    }
  }

  void initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 90),
    );
    _animationController.addListener(
      () {
        if (_animationController.isCompleted) {
          onVideoStopButtonPressed();
          setState(() {
            _opacity = 1.0;
            _startRecording = false;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TalentViewPage(
                talent: _talentName,
                movieFilter: _filterName == 'normal' || _filterName == ''
                    ? ''
                    : _filterName,
                talentName: _title != '' ? _title : '',
                videoUrl: _videoPath,
              ),
            ),
          );
        }
        setState(() {});
      },
    );
  }

  void _initCameraController(
    CameraDescription cameraDescription,
  ) async {
    if (_cameraController != null) {
      await _cameraController.dispose();
    }
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
    );
    try {
      _initializeControllerFuture = _cameraController.initialize();
    } on CameraException catch (_) {
      _showCameraException('Can\'t connect to the Camera');
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onSwitchCamera() {
    _selectedCameraIndex = _selectedCameraIndex < _cameras.length - 1
        ? _selectedCameraIndex + 1
        : 0;
    CameraDescription selectedCamera = _cameras[_selectedCameraIndex];
    _initCameraController(selectedCamera);
  }

  void _showCameraException(String msg) {
    Fluttertoast.showToast(msg: msg);
  }

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(milliseconds: 850),
      ),
    );
  }

  Future<void> startVideoRecording() async {
    if (!_cameraController.value.isInitialized) {
      showInSnackBar('Open Camera first.');
      return null;
    }

    if (_cameraController.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      await _cameraController.startVideoRecording();
    } on CameraException catch (_) {
      _showCameraException('Can\'t record Video');
      return null;
    }
  }

  Future<void> stopVideoRecording() async {
    if (!_cameraController.value.isRecordingVideo) {
      return null;
    }
    try {
      await _cameraController.stopVideoRecording().then((XFile file) {
        _videoPath = file.path;
      });
    } on CameraException catch (_) {
      _showCameraException('Can\'t stop recording');
      return null;
    }
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((_) {
      if (mounted) setState(() {});
    });
  }

  void onVideoStopButtonPressed() {
    stopVideoRecording().then((_) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TalentViewPage(
            movieFilter:
                _filterName == 'normal' || _filterName == '' ? '' : _filterName,
            talent: _talentName,
            talentName: _title != '' ? _title : '',
            videoUrl: _videoPath,
          ),
        ),
      );
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    }
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    if (_timerChanged == true) {
      setState(() {
        _start = 10;
      });
    } else {
      setState(() {
        _start = 3;
      });
    }
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(
        () {
          if (_start < 1) {
            timer.cancel();
          } else {
            _start = _start - 1;
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _animationController?.dispose();
    _timer?.cancel();
    _songNameController.dispose();
    _danceNameController.dispose();
    _magicTrickNameController.dispose();
    _talentNameController.dispose();
    super.dispose();
  }

  void _showTalentNameInputDialog(
      TextEditingController controller, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        backgroundColor: Colors.grey[900],
        child: Container(
          height: 300.0,
          width: 300.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(15.0),
                child: Text(
                  'What\'s your $title ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(15.0),
                child: Container(
                  width: MediaQuery.of(context).size.width / 1.2,
                  height: 40,
                  child: TextField(
                    controller: controller,
                    onChanged: (txt) {
                      _title = txt;
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(15),
                    ],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    cursorRadius: Radius.circular(10),
                    decoration: InputDecoration(
                      labelText: 'Enter your $title',
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          const Radius.circular(10.0),
                        ),
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          const Radius.circular(10.0),
                        ),
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      contentPadding: EdgeInsets.only(left: 15),
                    ),
                  ),
                ),
              ),
              Padding(padding: EdgeInsets.only(top: 50.0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width / 3,
                    height: 30,
                    child: OutlineButton(
                      onPressed: () {
                        if (_magicTrickNameController.text.length != 0) {
                          _magicTrickNameController.clear();
                        }
                        Navigator.pop(context);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      borderSide: BorderSide(color: Colors.white),
                      textColor: Colors.white,
                      child: Text('DISCARD'),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width / 3,
                    height: 30,
                    child: OutlineButton(
                      onPressed: () {
                        if (controller.text.length != 0) {
                          setState(() {
                            if (title == 'talent name') {
                              _addTalentTitle = true;
                            } else if (title == 'trick name') {
                              _addMagicTitle = true;
                            } else if (title == 'dance name') {
                              _addDancingTitle = true;
                            } else if (title == 'song name') {
                              _addSongTitle = true;
                            }
                          });
                          Navigator.pop(context);
                        } else {
                          Fluttertoast.showToast(
                            msg: 'Enter your $title first',
                          );
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      borderSide: BorderSide(color: Colors.white),
                      textColor: Colors.white,
                      child: Text('DONE'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      body: StatefulBuilder(
        builder: (context, setState) => Stack(
          children: <Widget>[
            Positioned.fill(
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.black,
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    );
                  } else {
                    return AspectRatio(
                      aspectRatio: _cameraController != null
                          ? _cameraController?.value?.aspectRatio
                          : 0.1,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: _cameraFilter.filterColors,
                        ).createShader(bounds),
                        blendMode: _cameraFilter.blendMode,
                        child: _cameraController?.value == null
                            ? Container()
                            : CameraPreview(_cameraController),
                      ),
                    );
                  }
                },
              ),
            ),
            AnimatedOpacity(
              opacity: _opacity,
              duration: Duration(milliseconds: 200),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: _talentName == 'Acting'
                      ? MediaQuery.of(context).size.height / 4.3
                      : MediaQuery.of(context).size.height / 4.5,
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 3,
                          ),
                          FaIcon(
                            FontAwesomeIcons.star,
                            color: Colors.yellowAccent[700],
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              _talentName,
                              style: GoogleFonts.lobster(
                                textStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                          _addSpeedPainting == true
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      SizedBox(width: 75),
                                      Container(
                                        alignment: Alignment.center,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                4,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.grey[900].withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _minutes == 1
                                              ? '$_minutes  minute'
                                              : '$_minutes  minutes',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(4),
                                        onTap: () {
                                          if (_minutes == 30) {
                                            Fluttertoast.showToast(
                                              msg:
                                                  'You\'ve reached the maximum time',
                                            );
                                          } else {
                                            setState(() {
                                              _minutes++;
                                              _animationController.duration =
                                                  Duration(minutes: _minutes);
                                            });
                                          }
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[900]
                                                .withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Icon(
                                            Icons.keyboard_arrow_up,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(4),
                                        onTap: _minutes == 1
                                            ? null
                                            : () {
                                                setState(() {
                                                  _minutes--;
                                                });
                                              },
                                        child: Container(
                                          alignment: Alignment.center,
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[900]
                                                .withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      FlatButton(
                                        onPressed: () {
                                          setState(() {
                                            _addSpeedPainting = false;
                                            _animationController.duration =
                                                Duration(seconds: 90);
                                          });
                                        },
                                        textColor: Colors.red,
                                        child: Text('cancel'),
                                      ),
                                    ],
                                  ),
                                )
                              : _addMagicTitle == true
                                  ? Container(
                                      width:
                                          MediaQuery.of(context).size.width / 3,
                                      height: 35,
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '# ' +
                                                '${_magicTrickNameController.text}',
                                            style: GoogleFonts.abel(
                                              textStyle: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.deepPurple,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : _addTalentTitle == true
                                      ? Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              3,
                                          height: 35,
                                          child: Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '# ' +
                                                    '${_talentNameController.text}',
                                                style: GoogleFonts.abel(
                                                  textStyle: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.deepPurple,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : _addDancingTitle == true
                                          ? Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  3,
                                              height: 35,
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '# ' +
                                                        '${_danceNameController.text}',
                                                    style: GoogleFonts.abel(
                                                      textStyle: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Colors.deepPurple,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : _addSongTitle == true
                                              ? Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      3,
                                                  height: 35,
                                                  child: Card(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '# ' +
                                                            '${_songNameController.text}',
                                                        style: GoogleFonts.abel(
                                                          textStyle: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors
                                                                .deepPurple,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : AnimatedSwitcher(
                                                  duration: Duration(
                                                      milliseconds: 300),
                                                  transitionBuilder:
                                                      (child, animation) =>
                                                          ScaleTransition(
                                                    scale: animation,
                                                    child: child,
                                                  ),
                                                  child: _bottomBar,
                                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _startedCounting == true && _start != 0
                ? Center(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: Text(
                        '$_start',
                        key: ValueKey<String>(_start.toString()),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 100,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Container(),
            Align(
              alignment: Alignment(0.0, 0.75),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  AnimatedOpacity(
                    opacity: _opacity,
                    duration: Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: InkWell(
                        onTap: _startRecording == true
                            ? null
                            : () {
                                setState(() {
                                  if (_timerChanged == false) {
                                    _timerChanged = true;
                                  } else {
                                    _timerChanged = false;
                                  }
                                });
                              },
                        child: Container(
                          height: 25,
                          width: 60,
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.black.withOpacity(0.7),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              Icon(
                                Icons.timer,
                                size: 20,
                                color: Colors.yellow[800],
                              ),
                              Icon(
                                _timerChanged == true
                                    ? Icons.timer_10
                                    : Icons.timer_3,
                                size: 20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (!_cameraController.value.isRecordingVideo) {
                        setState(() {
                          _startedCounting = true;
                        });
                        startTimer();
                        Timer(
                          Duration(
                            milliseconds: _timerChanged == true ? 10500 : 3500,
                          ),
                          () {
                            setState(() {
                              _startRecording = true;
                              _opacity = 0.0;
                            });
                            onVideoRecordButtonPressed();
                            _animationController.forward();
                          },
                        );
                      } else {
                        setState(() {
                          _startRecording = false;
                          _opacity = 1.0;
                        });
                        _animationController.reset();
                        _animationController.stop();
                        onVideoStopButtonPressed();
                      }
                    },
                    customBorder: CircleBorder(),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Stack(
                        children: <Widget>[
                          Visibility(
                            child: SizedBox(
                              height: 70,
                              width: 70,
                              child: CircularProgressIndicator(
                                value: _animationController.value,
                                strokeWidth: 9,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.indigo[700],
                                ),
                              ),
                            ),
                            visible: _startRecording == true,
                          ),
                          _startRecording == true
                              ? Positioned(
                                  top: 1,
                                  left: 1,
                                  child: CircleAvatar(
                                    radius: 34,
                                    backgroundColor: Colors.white,
                                    child: Center(
                                      child: AnimatedSwitcher(
                                        duration: Duration(milliseconds: 300),
                                        transitionBuilder: (child, animation) =>
                                            ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        ),
                                        child: Icon(
                                          _iconTalent,
                                          key: ValueKey<String>(_talentName),
                                          size: 35,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 34,
                                  backgroundColor: Colors.white,
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: Duration(milliseconds: 300),
                                      transitionBuilder: (child, animation) =>
                                          ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      ),
                                      child: Icon(
                                        _iconTalent,
                                        key: ValueKey<String>(_talentName),
                                        size: 35,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _opacity,
                    duration: Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: IconButton(
                        icon: Icon(
                          Icons.repeat,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed:
                            _startRecording == true ? null : _onSwitchCamera,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: _opacity,
              duration: Duration(milliseconds: 200),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                  height: MediaQuery.of(context).size.height / 13,
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.only(left: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.only(
                                left: 40,
                              ),
                              width: MediaQuery.of(context).size.width - 5,
                              height: 29,
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: ListWheelScrollView(
                                  itemExtent: 100,
                                  perspective: 0.002,
                                  physics: _startRecording == true
                                      ? NeverScrollableScrollPhysics()
                                      : FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (int i) {
                                    if (i == 0) {
                                      _danceNameController.clear();
                                      _magicTrickNameController.clear();
                                      _talentNameController.clear();
                                      setState(() {
                                        _addSpeedPainting = false;
                                        _addTalentTitle = false;
                                        _addMagicTitle = false;
                                        _addDancingTitle = false;
                                        _cameraFilter = MovieFilter(
                                          blendMode: BlendMode.dst,
                                          filterColors: [
                                            Colors.white,
                                            Colors.white
                                          ],
                                        );
                                        _talentName = 'Singing';
                                        _iconTalent =
                                            MdiIcons.microphoneVariant;
                                        _bottomBar = Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: <Widget>[
                                            Expanded(
                                              child: Container(
                                                margin: EdgeInsets.symmetric(
                                                    horizontal: 5),
                                                child: OutlineButton(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  borderSide: BorderSide(
                                                    color: Colors.green,
                                                  ),
                                                  onPressed: () {
                                                    _showTalentNameInputDialog(
                                                      _songNameController,
                                                      'song name',
                                                    );
                                                  },
                                                  textColor: Colors.green,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Icon(
                                                        MdiIcons.musicNotePlus,
                                                        size: 22,
                                                        color: Colors.green,
                                                      ),
                                                      SizedBox(width: 5),
                                                      Text(
                                                        'Song name',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      });
                                    } else if (i == 1) {
                                      _songNameController.clear();
                                      _magicTrickNameController.clear();
                                      _talentNameController.clear();
                                      setState(() {
                                        _addSpeedPainting = false;
                                        _addTalentTitle = false;
                                        _addMagicTitle = false;
                                        _addSongTitle = false;
                                        _cameraFilter = MovieFilter(
                                          blendMode: BlendMode.dst,
                                          filterColors: [
                                            Colors.white,
                                            Colors.white
                                          ],
                                        );
                                        _talentName = 'Dancing';
                                        _iconTalent = FontAwesomeIcons.child;
                                        _bottomBar = Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: <Widget>[
                                            Expanded(
                                              child: Container(
                                                margin: EdgeInsets.symmetric(
                                                    horizontal: 5),
                                                child: OutlineButton(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  borderSide: BorderSide(
                                                    color: Colors.green,
                                                  ),
                                                  onPressed: () {
                                                    _showTalentNameInputDialog(
                                                      _danceNameController,
                                                      'dance name',
                                                    );
                                                  },
                                                  textColor: Colors.green,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Icon(
                                                        FontAwesomeIcons.child,
                                                        size: 18,
                                                        color: Colors.green,
                                                      ),
                                                      SizedBox(width: 5),
                                                      Text(
                                                        'Dance name',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      });
                                    } else if (i == 2) {
                                      _songNameController.clear();
                                      _danceNameController.clear();
                                      _magicTrickNameController.clear();
                                      _talentNameController.clear();
                                      setState(() {
                                        _addSpeedPainting = false;
                                        _addTalentTitle = false;
                                        _addMagicTitle = false;
                                        _addDancingTitle = false;
                                        _addSongTitle = false;
                                        _talentName = 'Acting';
                                        _iconTalent = Icons.movie_filter;
                                        _bottomBar = Container(
                                          key: ValueKey<int>(0),
                                          height: 50,
                                          margin: EdgeInsets.only(top: 5),
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: _movieFilters.length,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    if (index == 0) {
                                                      _filterName = 'normal';
                                                    } else if (index == 1) {
                                                      _filterName =
                                                          'black&white';
                                                    } else if (index == 2) {
                                                      _filterName =
                                                          'yellow&Brown';
                                                    } else if (index == 3) {
                                                      _filterName = 'red';
                                                    } else if (index == 4) {
                                                      _filterName = 'pinky';
                                                    } else if (index == 5) {
                                                      _filterName = 'x-ray';
                                                    } else if (index == 6) {
                                                      _filterName = 'rainbow';
                                                    }
                                                    setState(() {
                                                      _cameraFilter =
                                                          MovieFilter(
                                                        blendMode:
                                                            _movieFilters[index]
                                                                .blendMode,
                                                        filterColors:
                                                            _movieFilters[index]
                                                                .filterColors,
                                                      );
                                                    });
                                                  },
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    child: ShaderMask(
                                                      blendMode:
                                                          _movieFilters[index]
                                                              .blendMode,
                                                      shaderCallback:
                                                          (bounds) =>
                                                              LinearGradient(
                                                        colors:
                                                            _movieFilters[index]
                                                                .filterColors,
                                                      ).createShader(
                                                        bounds,
                                                      ),
                                                      child: Image.asset(
                                                        'assets/tiger.jpg',
                                                        fit: BoxFit.cover,
                                                        width: 50,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      });
                                    } else if (i == 3) {
                                      _songNameController.clear();
                                      _danceNameController.clear();
                                      _magicTrickNameController.clear();
                                      _talentNameController.clear();
                                      setState(() {
                                        _addMagicTitle = false;
                                        _addTalentTitle = false;
                                        _addDancingTitle = false;
                                        _addSongTitle = false;
                                        _cameraFilter = MovieFilter(
                                          blendMode: BlendMode.dst,
                                          filterColors: [
                                            Colors.white,
                                            Colors.white
                                          ],
                                        );
                                        _talentName = 'Painting';
                                        _iconTalent = Icons.brush;
                                        _bottomBar = Container(
                                          key: ValueKey<int>(1),
                                          margin: EdgeInsets.only(top: 10),
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              30,
                                          height: 35,
                                          child: OutlineButton(
                                            borderSide: BorderSide(
                                              color: Colors.blue,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _addSpeedPainting = true;
                                                _animationController.duration =
                                                    Duration(minutes: 1);
                                              });
                                            },
                                            textColor: Colors.blue,
                                            child: Text('Add speed painting'),
                                          ),
                                        );
                                      });
                                    } else if (i == 4) {
                                      _songNameController.clear();
                                      _danceNameController.clear();
                                      _talentNameController.clear();
                                      setState(() {
                                        _addSpeedPainting = false;
                                        _addTalentTitle = false;
                                        _addDancingTitle = false;
                                        _addSongTitle = false;
                                        _cameraFilter = MovieFilter(
                                          blendMode: BlendMode.dst,
                                          filterColors: [
                                            Colors.white,
                                            Colors.white
                                          ],
                                        );
                                        _talentName = 'Magic';
                                        _iconTalent = MdiIcons.autoFix;
                                        _bottomBar = Container(
                                          margin: EdgeInsets.only(top: 10),
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              30,
                                          height: 35,
                                          child: OutlineButton(
                                            borderSide: BorderSide(
                                              color: Colors.white,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            onPressed: () {
                                              _showTalentNameInputDialog(
                                                _magicTrickNameController,
                                                'trick name',
                                              );
                                            },
                                            textColor: Colors.white,
                                            child: Text(
                                              'Add your trick name',
                                            ),
                                          ),
                                        );
                                      });
                                    } else {
                                      _showTalentNameInputDialog(
                                        _talentNameController,
                                        'talent name',
                                      );
                                      _songNameController.clear();
                                      _danceNameController.clear();
                                      _magicTrickNameController.clear();
                                      setState(() {
                                        _addSpeedPainting = false;
                                        _addMagicTitle = false;
                                        _addDancingTitle = false;
                                        _addSongTitle = false;
                                        _talentName = 'Special';
                                        _iconTalent = Icons.star;
                                        _bottomBar = Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              3,
                                          height: 35,
                                          child: Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '#',
                                                style: GoogleFonts.abel(
                                                  textStyle: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.deepPurple,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      });
                                    }
                                  },
                                  children: [
                                    RotatedBox(
                                      quarterTurns: 1,
                                      child: Text(
                                        'Singing',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 22),
                                      ),
                                    ),
                                    RotatedBox(
                                      quarterTurns: 1,
                                      child: Text(
                                        'Dancing',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 22),
                                      ),
                                    ),
                                    RotatedBox(
                                      quarterTurns: 1,
                                      child: Text(
                                        'Acting',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 22),
                                      ),
                                    ),
                                    RotatedBox(
                                      quarterTurns: 1,
                                      child: Text(
                                        'Painting',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 22),
                                      ),
                                    ),
                                    RotatedBox(
                                      quarterTurns: 1,
                                      child: Text(
                                        'Magic',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 22),
                                      ),
                                    ),
                                    RotatedBox(
                                      quarterTurns: 1,
                                      child: Text(
                                        'Special',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width / 2.15,
                              ),
                              child: Icon(
                                Icons.arrow_drop_up,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
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
    );
  }
}

class TalentViewPage extends StatefulWidget {
  final String talent;
  final String talentName;
  final String videoUrl;
  final String movieFilter;

  const TalentViewPage({
    Key key,
    this.talent,
    this.talentName,
    this.videoUrl,
    this.movieFilter,
  }) : super(key: key);

  @override
  _TalentViewPageState createState() => _TalentViewPageState();
}

class _TalentViewPageState extends State<TalentViewPage> {
  bool _showSpinner = false;
  String _userId = '';
  String _userName = '';
  String _userImage = '';
  Map<String, dynamic> _personalityType;
  VideoPlayerController _controller;
  final TextEditingController _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserData();
    _controller = VideoPlayerController.file(
      File(widget.videoUrl),
    );
    _controller.initialize().then((_) => setState(() {}));
    _controller.setLooping(true);
    _controller.play();
  }

  void getUserData() async {
    setPrefs();
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final DocumentSnapshot _snapshot =
        await _firestore.collection('users').doc(_prefs.get('id')).get();

    _userName = _snapshot?.data()['username'];
    _userImage = _snapshot?.data()['profilePictureUrl'];
    _personalityType = _snapshot?.data()['personality-type'];
    _userId = _prefs.get('id');
  }

  Future<void> sendTalent() async {
    setState(() => _showSpinner = true);
    final List<String> _videos = await StorageService.uploadMediaFile(
      [File(widget.videoUrl)],
      'talents-media',
    );
    final Talent _newTalent = Talent(
      creatorId: _userId,
      creatorName: _userName,
      creatorProfileImage: _userImage,
      caption: _captionController.text,
      category: widget.talent,
      talentName: widget.talentName,
      videoUrl: _videos.first,
      movieFilter: widget.movieFilter,
      creatorPersonality: _personalityType,
      timestamp: DateTime.now().toUtc().toString(),
    );
    await PersonalityService.setVideoInput(
      _newTalent.videoUrl,
    );
    DatabaseService.addTalent(_newTalent);
    NotificationsService.sendNotificationToFollowers(
      'New Talent',
      '$_userName uploaded a new talent',
      _userId,
      'talent-creation',
      DateTime.now().toUtc().toString(),
    );
    Fluttertoast.showToast(msg: 'Talent Created');
    setState(() => _showSpinner = false);
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.white,
        onPressed: sendTalent,
        icon: Icon(Icons.add, color: Colors.black),
        label: Text(
          'Add',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.talent),
      ),
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
          _showSpinner == true
              ? Center(
                  child: Container(
                    height: MediaQuery.of(context).size.height / 5,
                    width: MediaQuery.of(context).size.width / 3,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey[800].withOpacity(0.5),
                    ),
                    child: CircularProgressIndicator(
                      strokeWidth: 1.2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}

class MovieFilter {
  List<Color> filterColors;
  BlendMode blendMode;
  MovieFilter({this.filterColors, this.blendMode});
}
