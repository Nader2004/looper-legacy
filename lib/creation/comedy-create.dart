import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/services/personality.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/comedyModel.dart';
import '../services/database.dart';
import '../services/storage.dart';

class ComedyCreation extends StatefulWidget {
  ComedyCreation({Key key}) : super(key: key);

  @override
  _ComedyCreationState createState() => _ComedyCreationState();
}

class _ComedyCreationState extends State<ComedyCreation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _tabIndex = 0;
  int _selectedCameraIndex = 0;
  String _media = '';
  String _userId = '';
  String _userName = '';
  Map<String, dynamic> _personalityType;
  String _userImage = '';
  String _videoPath = '';
  bool _showLoading = false;
  bool _startRecording = false;
  List<bool> isSelected = [true, false, false];
  List<CameraDescription> _cameras;
  CameraController _cameraController;
  Future<void> _initializeControllerFuture;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _jokeController = TextEditingController();
  final TextEditingController _namingController = TextEditingController();

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final DocumentSnapshot _snapshot =
        await _firestore.collection('users').doc(_prefs.get('id')).get();
    setState(() {
      _userName = _snapshot?.data()['username'];
      _userImage = _snapshot?.data()['profilePictureUrl'];
      _personalityType = _snapshot?.data()['personality-type'];
      _userId = _prefs.get('id');
    });
  }

  void sendComedy() async {
    if (_media == '' && _jokeController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Add something first');
    } else {
      setState(() => _showLoading = true);
      List<String> _mediaUrl = [];
      if (_media.isNotEmpty) {
        if (_media.contains('.mp4')) {
          await PersonalityService.setVideoInput(_media);
        } else {
          await PersonalityService.setImageInput(_media);
        }
        _mediaUrl = await StorageService.uploadMediaFile(
          [File(_media)],
          'comedy-media',
        );
      }
      if (_jokeController.text.isNotEmpty) {
        await PersonalityService.setTextInput(_jokeController.text);
      }
      final Comedy _newComedy = Comedy(
        authorId: _userId,
        authorName: _userName,
        authorPersonality: _personalityType,
        authorImage: _userImage,
        mediaUrl: _mediaUrl.isEmpty ? '' : _mediaUrl.first,
        type: _media.isNotEmpty ? '1' : '0',
        caption: _namingController.text,
        content: _jokeController.text,
        timestamp: DateTime.now().toUtc().toString(),
      );
      DatabaseService.addComedy(_newComedy);
      NotificationsService.sendNotificationToFollowers(
        'New Comeddy',
        '$_userName uploaded a new comedy',
        _userId,
        'comedy-creation',
        DateTime.now().toUtc().toString(),
      );
      setState(() => _showLoading = false);
      Fluttertoast.showToast(msg: 'Comedy created');
      Navigator.pop(context);
    }
  }

  Widget _buildSegmentControl() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.all(25),
        child: CupertinoSlidingSegmentedControl(
          groupValue: _tabIndex,
          thumbColor: Colors.white,
          children: {
            0: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                FaIcon(
                  FontAwesomeIcons.grinTongue,
                  size: 20,
                ),
                Text('Joke')
              ],
            ),
            1: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                FaIcon(
                  FontAwesomeIcons.users,
                  size: 20,
                ),
                Text('Comedy show'),
              ],
            ),
          },
          onValueChanged: (int index) {
            setState(() {
              _tabIndex = index;
            });
            if (index == 0) {
              _namingController.clear();
            }
          },
        ),
      ),
    );
  }

  void _showMediaPicker(String cameraAction) {
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

                  final PickedFile _file = cameraAction == 'Record a Video'
                      ? await _picker.getVideo(source: ImageSource.camera)
                      : await _picker.getImage(source: ImageSource.camera);
                  setState(() {
                    _media = _file.path;
                  });
                },
                title: Text(cameraAction),
              ),
              ListTile(
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker _picker = ImagePicker();

                  final PickedFile _file = cameraAction == 'Record a Video'
                      ? await _picker.getVideo(source: ImageSource.gallery)
                      : await _picker.getImage(
                          source: ImageSource.gallery,
                        );
                  setState(() {
                    _media = _file.path;
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

  Widget _buildJokeWidget() {
    return Column(
      mainAxisAlignment: _media != ''
          ? MainAxisAlignment.start
          : MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height / 14,
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.close,
                  size: 30,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 50),
              child: ToggleButtons(
                borderColor: Colors.black,
                fillColor: Colors.black,
                selectedBorderColor: Colors.black,
                color: Colors.black,
                selectedColor: Colors.white,
                borderRadius: BorderRadius.circular(25),
                constraints: BoxConstraints(
                  minHeight: 30,
                  minWidth: 80,
                ),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Text(
                      'Aa',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(Icons.camera_alt),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(Icons.videocam),
                  ),
                ],
                onPressed: (int index) {
                  setState(() {
                    for (int i = 0; i < isSelected.length; i++) {
                      isSelected[i] = i == index;
                    }
                  });
                  if (index == 1) {
                    _showMediaPicker(
                      'Take a Photo',
                    );
                    _jokeController.clear();
                  } else if (index == 2) {
                    _showMediaPicker(
                      'Record a Video',
                    );
                    _jokeController.clear();
                  } else {
                    setState(() => _media = '');
                    _namingController.clear();
                  }
                },
                isSelected: isSelected,
              ),
            ),
          ],
        ),
        _media != '' && !_media.endsWith('.mp4')
            ? Stack(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(
                      top: 20,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_media),
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width / 1.1,
                        height: MediaQuery.of(context).size.height / 2,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _media = '';
                            isSelected = [true, false, false];
                          });
                        },
                        child: Container(
                          height: 25,
                          width: 25,
                          margin: EdgeInsets.only(right: 10, top: 25),
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
                ],
              )
            : _media != '' && _media.endsWith('.mp4')
                ? VideoThumbWidget(
                    videoUrl: _media,
                    onRemove: () {
                      setState(() {
                        _media = '';
                        isSelected = [true, false, false];
                      });
                    },
                  )
                : Center(
                    child: InkWell(
                      borderRadius: BorderRadius.all(
                        Radius.circular(16),
                      ),
                      onTap: () => _showNamingDialog(
                        'joke',
                        _jokeController,
                        limit: 120,
                      ),
                      child: DottedBorder(
                        borderType: BorderType.RRect,
                        radius: Radius.circular(16),
                        color: Colors.black,
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(16),
                          ),
                          child: Container(
                            height: MediaQuery.of(context).size.height / 4,
                            width: MediaQuery.of(context).size.width - 30,
                            padding: EdgeInsets.all(8),
                            alignment: Alignment.center,
                            child: SelectableLinkify(
                              onOpen: (link) async {
                                if (await canLaunch(link.url)) {
                                  await launch(link.url);
                                } else {
                                  Fluttertoast.showToast(
                                    msg: 'can not launch this link',
                                  );
                                }
                              },
                              text: _jokeController.text.isNotEmpty
                                  ? _jokeController.text
                                  : 'What\'s your joke ?',
                              style: TextStyle(
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
        _media != '' && _namingController.text == ''
            ? Container(
                width: MediaQuery.of(context).size.width / 2,
                margin: EdgeInsets.only(
                  top: 20,
                  bottom: 20,
                ),
                child: OutlineButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  borderSide: BorderSide(color: Colors.blue),
                  textColor: Colors.blue,
                  onPressed: () =>
                      _showNamingDialog('caption', _namingController),
                  child: Text('Add caption'),
                ),
              )
            : Container(),
        _jokeController.text.isNotEmpty
            ? Positioned.fill(
                child: Align(
                  alignment: Alignment(0.0, 0.5),
                  child: Container(
                    width: MediaQuery.of(context).size.width / 2,
                    margin: EdgeInsets.only(
                      bottom: 20,
                    ),
                    child: FlatButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textColor: Colors.white,
                      color: Colors.black,
                      onPressed: sendComedy,
                      child: Text('Post'),
                    ),
                  ),
                ),
              )
            : Container(),
        _namingController.text != '' && _media != ''
            ? SingleChildScrollView(
                child: Container(
                  margin: EdgeInsets.only(
                    top: 20,
                    bottom: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        _namingController.text,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(width: 5),
                      GestureDetector(
                        onTap: () =>
                            _showNamingDialog('caption', _namingController),
                        child: Icon(
                          Icons.edit,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container(),
        _media != ''
            ? Container(
                width: MediaQuery.of(context).size.width / 2,
                margin: EdgeInsets.only(
                  bottom: 20,
                ),
                child: FlatButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textColor: Colors.white,
                  color: Colors.black,
                  onPressed: sendComedy,
                  child: Text('Post'),
                ),
              )
            : Container(),
      ],
    );
  }

  Widget _buildComedyShowWidget() {
    return Stack(
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
            child: _namingController.text.length != 0
                ? Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      _namingController.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  )
                : Container(
                    width: MediaQuery.of(context).size.width - 30,
                    height: 35,
                    margin: EdgeInsets.only(top: 20),
                    child: OutlineButton(
                      borderSide: BorderSide(color: Colors.white),
                      onPressed: () => _showNamingDialog(
                        'show name',
                        _namingController,
                        limit: 15,
                      ),
                      textColor: Colors.white,
                      child: Text('Add your show name'),
                    ),
                  ),
          ),
        ),
        Align(
          alignment: Alignment(0.0, 0.7),
          child: Container(
            width: MediaQuery.of(context).size.width / 3,
            height: MediaQuery.of(context).size.height / 15,
            child: FlatButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onPressed: () {
                if (!_cameraController.value.isRecordingVideo) {
                  setState(() {
                    _startRecording = true;
                  });
                  onVideoRecordButtonPressed();
                } else {
                  setState(() {
                    _startRecording = false;
                  });
                  onVideoStopButtonPressed(context);
                }
              },
              color: Colors.blue,
              textColor: Colors.white,
              child: Text(
                _startRecording == true ? 'Recording' : 'GO AHEAD !',
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment(1.0, 0.7),
          child: Container(
            width: MediaQuery.of(context).size.width / 3,
            height: MediaQuery.of(context).size.height / 15,
            child: IconButton(
              onPressed: _onSwitchCamera,
              icon: Icon(
                Icons.repeat,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    setPrefs();
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

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((_) {
      if (mounted) setState(() {});
    });
  }

  void onVideoStopButtonPressed(BuildContext context) {
    stopVideoRecording().then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ComedyViewPage(
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _jokeController.dispose();
    _namingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Stack(
        children: <Widget>[
          AnimatedCrossFade(
            firstChild: _buildJokeWidget(),
            secondChild: _buildComedyShowWidget(),
            crossFadeState: _tabIndex == 1
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 500),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _buildSegmentControl(),
            ),
          ),
          _showLoading == true
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

  void _showNamingDialog(
    String label,
    TextEditingController controller, {
    int limit = 40,
  }) {
    showDialog(
      context: context,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          content: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Your $label',
                  ),
                  maxLength: limit,
                ),
              )
            ],
          ),
          actions: <Widget>[
            FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  controller.clear();
                  Navigator.pop(context);
                }),
            FlatButton(
                child: const Text('DONE'),
                onPressed: () {
                  if (controller.text.length != 0) {
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
    var status = await Permission.storage.request();
    if (status.isGranted) {
      String _retrievedFilePath = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl == null ? '' : widget.videoUrl,
      );
      setState(() {
        _path = _retrievedFilePath;
      });
    } else {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _path == null
        ? Container()
        : Container(
            margin: EdgeInsets.only(top: 20),
            child: Stack(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_path),
                      height: MediaQuery.of(context).size.height / 2,
                      width: MediaQuery.of(context).size.width,
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
                      width: 50,
                      height: 50,
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
                          size: 27,
                        ),
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
  VideoWidget({Key key, this.videoPath}) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  double _opacity = 1.0;
  double _positionValue;
  String _positionText;
  VideoPlayerController _playerController;

  String get _duration =>
      _playerController.value.duration
          ?.toString()
          ?.substring(2)
          ?.split('.')
          ?.first ??
      '';
  String get _position =>
      _playerController.value.position
          ?.toString()
          ?.substring(2)
          ?.split('.')
          ?.first ??
      '';

  @override
  void initState() {
    super.initState();
    _playerController = VideoPlayerController.file(
      File(widget.videoPath),
    )..initialize().then((_) {
        setState(() {});
      });
    _playerController.addListener(_listenToValues);
  }

  void _listenToValues() {
    setState(() {
      _positionText = _position ?? '';
      _positionValue =
          _playerController?.value?.position?.inSeconds?.toDouble() ?? 0.0;
    });
    if (_position == _duration) {
      setState(() {
        _opacity = 1.0;
      });
    }
  }

  void seekToSecond(int seconds) {
    final Duration _newDuration = Duration(seconds: seconds);
    _playerController.seekTo(_newDuration);
  }

  @override
  void dispose() {
    _playerController.removeListener(_listenToValues);
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            if (_opacity == 1.0) {
              _opacity = 0.0;
            } else {
              _opacity = 1.0;
            }
          });
        },
        child: Stack(
          children: <Widget>[
            AspectRatio(
              aspectRatio: _playerController?.value?.aspectRatio,
              child: VideoPlayer(_playerController),
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
                      if (_playerController.value.isPlaying) {
                        _playerController.pause();
                      } else if (!_playerController.value.isPlaying &&
                          _position != _duration) {
                        _playerController.play();
                        _opacity = 0.0;
                      } else if (_position == _duration) {
                        _playerController.seekTo(Duration.zero);
                        _playerController.play();
                        _opacity = 0.0;
                      } else {
                        return;
                      }
                    });
                  },
                  child: FaIcon(
                    _playerController.value.isPlaying
                        ? FontAwesomeIcons.pause
                        : _position == _duration
                            ? Icons.replay
                            : FontAwesomeIcons.play,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedOpacity(
                  opacity: _opacity,
                  duration: Duration(milliseconds: 350),
                  curve: Curves.easeIn,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20, left: 10),
                        child: Text(
                          _positionText == null ? '' : _positionText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: SliderTheme(
                            data: SliderThemeData(
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                            ),
                            child: Slider(
                              value:
                                  _positionValue == null ? 0.0 : _positionValue,
                              min: 0.0,
                              max: _playerController?.value?.duration?.inSeconds
                                      ?.toDouble() ??
                                  1.0,
                              onChanged: (value) {
                                setState(() {
                                  seekToSecond(value.toInt());
                                  _positionValue = value;
                                  _positionText =
                                      Duration(seconds: value.toInt())
                                              ?.toString()
                                              ?.substring(2)
                                              ?.split('.')
                                              ?.first ??
                                          '';
                                  value = value;
                                });
                              },
                              activeColor: Colors.deepPurpleAccent,
                              inactiveColor:
                                  Colors.deepPurpleAccent.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20, right: 10),
                        child: Text(
                          _duration == null ? '' : _duration,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ComedyViewPage extends StatefulWidget {
  final String videoUrl;
  final String showName;
  const ComedyViewPage({
    Key key,
    this.videoUrl,
    this.showName,
  }) : super(key: key);

  @override
  _ComedyViewPageState createState() => _ComedyViewPageState();
}

class _ComedyViewPageState extends State<ComedyViewPage> {
  bool _showSpinner = false;
  String _userId = '';
  String _userName = '';
  String _userImage = '';
  VideoPlayerController _controller;
  Map<String, dynamic> _personalityType;

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
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final DocumentSnapshot _snapshot =
        await _firestore.collection('users').doc(_prefs.get('id')).get();
    _userId = _prefs.get('id');
    _userName = _snapshot?.data()['username'];
    _userImage = _snapshot?.data()['profilePictureUrl'];
    _personalityType = _snapshot?.data()['personality-type'];
  }

  Future<void> sendComedy() async {
    setState(() => _showSpinner = true);
    await PersonalityService.setVideoInput(widget.videoUrl);
    final List<String> _videos = await StorageService.uploadMediaFile(
      [File(widget.videoUrl)],
      'comedy-media',
    );
    final Comedy _newComedy = Comedy(
      authorId: _userId,
      authorName: _userName,
      authorImage: _userImage,
      caption: widget.showName,
      authorPersonality: _personalityType,
      mediaUrl: _videos.first,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'show',
    );
    DatabaseService.addComedy(_newComedy);
    Fluttertoast.showToast(msg: 'Comedy show Created');
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
        onPressed: sendComedy,
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
        title: Text(
          widget.showName == null ? 'Your Comedy show' : widget.showName,
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
        ],
      ),
    );
  }
}
