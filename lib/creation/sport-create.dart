import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'package:looper/models/sportModel.dart';
import 'package:looper/services/database.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/services/personality.dart';
import 'package:looper/services/storage.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:video_player/video_player.dart';

import 'package:fluttertoast/fluttertoast.dart';

class SportCreation extends StatefulWidget {
  SportCreation({Key key}) : super(key: key);

  @override
  _SportCreationState createState() => _SportCreationState();
}

class _SportCreationState extends State<SportCreation>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  AnimationController _animationController;
  List<CameraDescription> _cameras;
  CameraController _cameraController;
  IconData _iconData;
  int _selectedCameraIndex = 0;
  int _currentIndex = 0;
  int _iconIndex = 0;
  Future<void> _initializeControllerFuture;
  String _videoPath;
  bool _startRecording = false;
  List<String> _sportCatogeries = [
    'soccer',
    'american football',
    'basketball',
    'swimming',
    'volley',
    'baseball',
    'tennis',
    'table tennis',
    'running',
    'gym',
  ];
  List<IconData> _icons = [
    MdiIcons.soccer,
    MdiIcons.football,
    MdiIcons.basketball,
    MdiIcons.swim,
    MdiIcons.volleyball,
    MdiIcons.baseballBat,
    MdiIcons.tennis,
    MdiIcons.tableTennis,
    MdiIcons.run,
    MdiIcons.armFlex,
  ];
  String _categoryItem;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _categoryItem = _sportCatogeries[_currentIndex];
    _iconData = _icons[_iconIndex];
    initializeAnimation();
    initializeCamera();
  }

  void initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 90),
    );

    _animationController.addListener(
      () {
        if (_animationController.isCompleted) {
          onVideoStopButtonPressed(context);
          _animationController.reset();
          _animationController.stop();
          setState(() {
            _startRecording = false;
          });
        }
        setState(() {});
      },
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

  Future<String> startVideoRecording() async {
    if (!_cameraController.value.isInitialized) {
      showInSnackBar('Open Camera first.');
      return null;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String _timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String dirPath = '${extDir.path}/Sports';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/$_timestamp.mp4';

    if (_cameraController.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      _videoPath = filePath;
      await _cameraController.startVideoRecording(filePath);
    } on CameraException catch (_) {
      _showCameraException('Can\'t record Video');
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!_cameraController.value.isRecordingVideo) {
      return null;
    }

    try {
      await _cameraController.stopVideoRecording();
    } on CameraException catch (_) {
      _showCameraException('Can\'t stop recording');
      return null;
    }
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((String filePath) {
      if (mounted) setState(() {});
    });
  }

  void onVideoStopButtonPressed(BuildContext context) {
    stopVideoRecording().then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SportVideoShowPage(
            sportCategory: _categoryItem,
            videoPath: _videoPath,
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  Widget _buildBottomControlBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              if (!_cameraController.value.isRecordingVideo) {
                setState(() {
                  _startRecording = true;
                });
                onVideoRecordButtonPressed();
                _animationController.forward();
              } else {
                setState(() {
                  _startRecording = false;
                });
                _animationController.reset();
                _animationController.stop();
                onVideoStopButtonPressed(context);
              }
            },
            child: Container(
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height / 18,
                left: MediaQuery.of(context).size.width / 3,
                right: MediaQuery.of(context).size.width / 5,
              ),
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
                                child: Icon(_iconData),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.white,
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) =>
                                    RotationTransition(
                                  turns: animation,
                                  child: child,
                                ),
                                child: Icon(
                                  _iconData,
                                  size: 30,
                                  key: ValueKey<String>(_categoryItem),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.repeat,
              color: Colors.white,
              size: 30,
            ),
            onPressed: _onSwitchCamera,
          )
        ],
      ),
    );
  }

  Widget _buildTopControlBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              onPressed: _currentIndex == 0
                  ? null
                  : () {
                      setState(() {
                        _currentIndex--;
                        _iconIndex--;
                        _iconData = _icons[_iconIndex];
                        _categoryItem = _sportCatogeries[_currentIndex];
                      });
                    },
              icon: Icon(
                Icons.keyboard_arrow_left,
                color: _currentIndex == 0 ? Colors.grey : Colors.white,
                size: 28,
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 2.5,
              height: 35,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(30),
                color: Colors.white.withOpacity(0.5),
              ),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 150),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Text(
                  _categoryItem,
                  key: ValueKey<String>(
                    _categoryItem,
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _currentIndex == 9
                  ? null
                  : () {
                      setState(() {
                        _currentIndex++;
                        _iconIndex++;
                        _iconData = _icons[_iconIndex];
                        _categoryItem = _sportCatogeries[_currentIndex];
                      });
                    },
              icon: Icon(
                Icons.keyboard_arrow_right,
                color: _currentIndex == 9 ? Colors.grey : Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
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
                    child: _cameraController?.value == null
                        ? Container()
                        : CameraPreview(_cameraController),
                  );
                }
              },
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(top: 30, left: 10),
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                color: Colors.black.withOpacity(0.5),
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
          _startRecording == true ? Container() : _buildTopControlBar(),
          _buildBottomControlBar(),
        ],
      ),
    );
  }
}

class SportVideoShowPage extends StatefulWidget {
  final String sportCategory;
  final String videoPath;
  SportVideoShowPage({
    Key key,
    this.sportCategory,
    this.videoPath,
  }) : super(key: key);

  @override
  _SportVideoShowPageState createState() => _SportVideoShowPageState();
}

class _SportVideoShowPageState extends State<SportVideoShowPage> {
  VideoPlayerController _controller;
  String _userId = '';
  String _userName = '';
  String _userImage = '';
  Map<String, dynamic> _personalityType = {};
  bool _showSpinner = false;

  @override
  void initState() {
    super.initState();
    getUserData();
    _controller = VideoPlayerController.file(
      File(widget.videoPath),
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

  Future<void> sendSport() async {
    setState(() => _showSpinner = true);
    final List<String> _video = await StorageService.uploadMediaFile(
        [File(widget.videoPath)], 'Sport-media');
    final Sport _newSport = Sport(
      creatorId: _userId,
      creatorName: _userName,
      creatorProfileImage: _userImage,
      creatorPersonality: _personalityType,
      sportCategory: widget.sportCategory,
      videoUrl: _video.first,
      timestamp: DateTime.now().toUtc().toString(),
    );
    await PersonalityService.setVideoInput(
      _newSport.videoUrl,
    );
    DatabaseService.addSport(_newSport);
    NotificationsService.sendNotificationToFollowers(
      'New Sport',
      '$_userName uploaded a new sport',
      _userId,
      'sport-creation',
      DateTime.now().toUtc().toString(),
    );
    Fluttertoast.showToast(msg: 'Sport Created');
    setState(() => _showSpinner = false);
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  Widget _buildTopBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 25),
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              color: Colors.black.withOpacity(0.5),
              icon: Icon(
                Icons.close,
                color: Colors.white,
                size: 30,
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width / 6),
            Container(
              width: MediaQuery.of(context).size.width / 2.5,
              height: 35,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(30),
                color: Colors.white.withOpacity(0.5),
              ),
              child: Text(
                widget.sportCategory,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Container(
        width: 52,
        height: 52,
        child: FloatingActionButton(
          backgroundColor: Colors.black,
          onPressed: sendSport,
          child: Icon(Icons.send, color: Colors.white),
        ),
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
          _buildTopBar(),
        ],
      ),
    );
  }
}
