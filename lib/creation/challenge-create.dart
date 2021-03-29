import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/services/personality.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../services/database.dart';
import '../services/storage.dart';
import '../models/challengeModel.dart';

class ChallengeCreation extends StatefulWidget {
  ChallengeCreation({Key key}) : super(key: key);

  @override
  _ChallengeCreationState createState() => _ChallengeCreationState();
}

class _ChallengeCreationState extends State<ChallengeCreation>
    with WidgetsBindingObserver {
  int _selectedCameraIndex = 0;
  String _videoPath;
  List<CameraDescription> _cameras;
  CameraController _cameraController;
  Future<void> _initializeControllerFuture;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _challengeNameController =
      TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    initializeCamera();
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

  void onVideoStopButtonPressed() {
    stopVideoRecording().then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoWidget(
            videoPath: _videoPath,
            challengeName: _challengeNameController.text,
          ),
        ),
      );
      if (mounted) setState(() {});
    });
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((_) {
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
    _challengeNameController?.dispose();
    super.dispose();
  }

  void _showNamingDialog(String label) {
    showDialog(
      context: context,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          content: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _challengeNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Your $label',
                  ),
                  maxLength: 15,
                ),
              )
            ],
          ),
          actions: <Widget>[
            FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  _challengeNameController.clear();
                  Navigator.pop(context);
                }),
            FlatButton(
                child: const Text('DONE'),
                onPressed: () {
                  if (_challengeNameController.text.length != 0) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            alignment: Alignment.topCenter,
            child: Container(
              height: MediaQuery.of(context).size.height / 7,
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black12.withOpacity(0.3),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 20, right: 10, left: 5),
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
                  _challengeNameController.text.length != 0
                      ? Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            _challengeNameController.text,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        )
                      : Container(
                          width: MediaQuery.of(context).size.width / 1.3,
                          height: 35,
                          margin: EdgeInsets.only(top: 20),
                          child: OutlineButton(
                            borderSide: BorderSide(color: Colors.white),
                            onPressed: () =>
                                _showNamingDialog('challenge name'),
                            textColor: Colors.white,
                            child: Text('Add your challenge name'),
                          ),
                        ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(25),
              child: Container(
                width: MediaQuery.of(context).size.width / 2.5,
                height: 35,
                child: FlatButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  color: Colors.blue,
                  onPressed: () {
                    if (_cameraController?.value?.isRecordingVideo == true) {
                      onVideoStopButtonPressed();
                    } else {
                      setState(() {
                        onVideoRecordButtonPressed();
                      });
                    }
                  },
                  textColor: Colors.white,
                  child: Text(
                    _cameraController?.value?.isRecordingVideo == true
                        ? 'Recording'
                        : 'Start challenge',
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment(-0.9, 0.94),
            child: IconButton(
              onPressed: _onSwitchCamera,
              icon: Icon(
                Icons.repeat,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          Align(
            alignment: Alignment(0.9, 0.92),
            child: Container(
              height: 35,
              width: 35,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
              ),
              child: GestureDetector(
                onTap: () async {
                  final ImagePicker _picker = ImagePicker();

                  final PickedFile _file =
                      await _picker.getVideo(source: ImageSource.gallery);
                  if (_file != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoWidget(
                          videoPath: _file.path,
                          challengeName: _challengeNameController.text,
                        ),
                      ),
                    );
                  }
                },
                child: Icon(
                  Icons.video_library_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoWidget extends StatefulWidget {
  final String videoPath;
  final String challengeName;
  VideoWidget({Key key, this.videoPath, this.challengeName}) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  VideoPlayerController _controller;
  String _userId;
  String _userName;
  Map<String, dynamic> _personalityType;
  String _userImage;
  bool _showSpinner;

  @override
  void initState() {
    super.initState();
    getUserData();
    _controller = VideoPlayerController.file(
      File(widget.videoPath),
    );
    _controller.initialize().then((_) => setState(() {}));
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

  Future<void> sendChallenge() async {
    setState(() => _showSpinner = true);
    final List<String> _video = await StorageService.uploadMediaFile(
        [File(widget.videoPath)], 'Challenge-media');
    final Challenge _newChallenge = Challenge(
      creatorId: _userId,
      creatorName: _userName,
      creatorProfileImage: _userImage,
      creatorPersonality: _personalityType,
      videoUrl: _video.first,
      category: widget.challengeName,
      timestamp: DateTime.now().toUtc().toString(),
    );
    await PersonalityService.setVideoInput(
      _newChallenge.videoUrl,
    );
    DatabaseService.addChallenge(_newChallenge);
    NotificationsService.sendNotificationToFollowers(
      'New Challenge',
      '$_userName uploaded a new challenge',
      _userId,
      'challenge-creation',
      DateTime.now().toUtc().toString(),
    );
    Fluttertoast.showToast(msg: 'Challenge Created');
    setState(() => _showSpinner = false);
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: sendChallenge,
        backgroundColor: Colors.white,
        child: Icon(Icons.send, color: Colors.black),
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
          Align(
            alignment: Alignment.bottomCenter,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
            ),
          ),
        ],
      ),
    );
  }
}
