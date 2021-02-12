import 'dart:async';

import 'package:flutter/material.dart';

import 'package:camera/camera.dart';

import 'package:stop_watch_timer/stop_watch_timer.dart';

import 'package:fluttertoast/fluttertoast.dart';

class Camera extends StatefulWidget {
  Camera({Key key}) : super(key: key);

  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedCameraIndex;
  bool _onRecordMode = false;
  bool _turnFlashOn = false;
  bool _displayCaptureEffect = false;
  List<bool> _isSelected = [false, false];
  String _imagePath;
  CameraController _cameraController;
  List<CameraDescription> _cameras;
  Future<void> _initializeControllerFuture;
  AnimationController _animationController;
  Animation<double> _animation;
  BorderRadiusGeometry _borderRadius = BorderRadius.circular(10.0);
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StopWatchTimer _stopWatchTimer = StopWatchTimer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeCamera();
    initializeAnimations();
    _isSelected[0] = true;
  }

  void initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInQuad,
      ),
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
    _cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
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

  Widget _buildSwitchCameraButton() {
    return FlatButton(
      color: Colors.black.withOpacity(0.3),
      shape: CircleBorder(),
      onPressed: _onSwitchCamera,
      child: Icon(
        Icons.switch_camera,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildFlashCameraButton() {
    return FlatButton(
      color: Colors.black.withOpacity(0.3),
      shape: CircleBorder(),
      onPressed: () {
        setState(() {
          if (_turnFlashOn == false) {
            _turnFlashOn = true;
          } else {
            _turnFlashOn = false;
          }
        });
      },
      child: Icon(
        _turnFlashOn == true ? Icons.flash_on : Icons.flash_off,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildRedDottIcon() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      height: 20,
      width: 20,
      decoration: BoxDecoration(
        color: Colors.red[700],
        borderRadius: _borderRadius,
      ),
    );
  }

  Widget _buildVideoTimer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: const Color(0x40000000),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.fiber_manual_record,
              size: 16.0,
              color: Colors.red,
            ),
            StreamBuilder<int>(
              stream: _stopWatchTimer.rawTime,
              initialData: 0,
              builder: (context, snap) {
                final _value = snap.data;
                final _displayTime = StopWatchTimer.getDisplayTime(
                  _value,
                  milliSecond: false,
                );
                return Padding(
                  padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                  child: Text(
                    _displayTime,
                    style: TextStyle(fontSize: 16.0, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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
    // _cameraController?.dispose();
    _animationController?.dispose();
    _stopWatchTimer?.dispose();
    super.dispose();
  }

  String timestamp() => DateTime.now().toIso8601String();

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(milliseconds: 850),
      ),
    );
  }

  void _addOnCaptureEffect() {
    setState(() {
      _displayCaptureEffect = true;
    });
    Timer(
      Duration(milliseconds: 50),
      () {
        setState(() {
          _displayCaptureEffect = false;
        });
      },
    );
  }

  Future<String> _capturePhoto() async {
    try {
      await _initializeControllerFuture;
      final XFile _file = await _cameraController.takePicture();
      return _file.path;
    } catch (_) {
      setState(() {
        _displayCaptureEffect = false;
      });
      _showCameraException('Can\'t capture a photo');
      return null;
    }
  }

  void onTakePictureButtonPressed(BuildContext context) {
    _capturePhoto().then((String filePath) {
      if (mounted) {
        setState(() {
          _imagePath = filePath;
        });
        if (filePath != null) {
          showInSnackBar('Picture saved');
          Navigator.pop(context, _imagePath);
        }
      }
    });
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((_) {
      if (mounted) setState(() {});
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((String video) {
      if (mounted) setState(() {});
      Navigator.of(context).pop(video);
    });
  }

  Future<void> startVideoRecording() async {
    if (!_cameraController.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (_cameraController.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      await _cameraController.startVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e.description);
      return null;
    }
  }

  Future<String> stopVideoRecording() async {
    if (!_cameraController.value.isRecordingVideo) {
      return null;
    }

    try {
      final XFile _file = await _cameraController.stopVideoRecording();
      return _file.path;
    } on CameraException catch (e) {
      _showCameraException(e.description);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.white,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation(Colors.black),
              ),
            ),
          );
        } else {
          return Scaffold(
            key: _scaffoldKey,
            body: Stack(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: _cameraController != null
                      ? _cameraController.value.aspectRatio / 3.16
                      : 0.1,
                  child: _cameraController?.value == null
                      ? Container()
                      : CameraPreview(_cameraController),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 45.0),
                    child: Visibility(
                      visible: _cameraController != null
                          ? _cameraController.value.isRecordingVideo
                          : false,
                      child: _buildVideoTimer(),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 45.0),
                    child: Visibility(
                      visible: _cameraController != null
                          ? !_cameraController.value.isRecordingVideo
                          : true,
                      child: SegementButtons(
                        isSelected: _isSelected,
                        onPressed: (int index) {
                          setState(() {
                            for (int buttonIndex = 0;
                                buttonIndex < _isSelected.length;
                                buttonIndex++) {
                              if (buttonIndex == index) {
                                _isSelected[buttonIndex] = true;
                              } else {
                                _isSelected[buttonIndex] = false;
                              }
                            }
                          });
                          if (index == 0) {
                            setState(() {
                              _onRecordMode = false;
                            });
                            _animationController.reverse();
                          } else {
                            setState(() {
                              _onRecordMode = true;
                            });
                            _animationController.forward();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                Visibility(
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  visible: _displayCaptureEffect,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: CaptureOrRecordButton(
                      onPressed: () {
                        if (_onRecordMode == true) {
                          setState(() {
                            if (_borderRadius == BorderRadius.circular(10)) {
                              _borderRadius = BorderRadius.circular(3);
                              if (_cameraController != null &&
                                  _cameraController.value.isInitialized &&
                                  !_cameraController.value.isRecordingVideo) {
                                _stopWatchTimer.onExecute
                                    .add(StopWatchExecute.start);
                                onVideoRecordButtonPressed();
                              } else {
                                return;
                              }
                            } else {
                              _borderRadius = BorderRadius.circular(10);
                              if (_cameraController != null &&
                                  _cameraController.value.isInitialized &&
                                  _cameraController.value.isRecordingVideo) {
                                _stopWatchTimer.onExecute
                                    .add(StopWatchExecute.stop);
                                onStopButtonPressed();
                              } else {
                                return;
                              }
                            }
                          });
                        }
                        if (_onRecordMode == false) {
                          _addOnCaptureEffect();
                          onTakePictureButtonPressed(context);
                        }
                      },
                      child: ScaleTransition(
                        scale: _animation,
                        child: _buildRedDottIcon(),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 5.0,
                      bottom: 30.0,
                    ),
                    child: _buildSwitchCameraButton(),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 5.0,
                      bottom: 30.0,
                    ),
                    child: Visibility(
                      visible: _cameraController != null
                          ? !_cameraController.value.isRecordingVideo
                          : true,
                      child: _buildFlashCameraButton(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

class CaptureOrRecordButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  const CaptureOrRecordButton({
    Key key,
    this.onPressed,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: CircleBorder(),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white.withOpacity(0.2),
        child: CircleAvatar(
          radius: 34,
          backgroundColor: Colors.white,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class SegementButtons extends StatelessWidget {
  final List<bool> isSelected;
  final Function(int) onPressed;
  const SegementButtons({
    Key key,
    this.isSelected,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      children: [
        Container(
          alignment: Alignment.center,
          width: 100,
          child: Text('Photo'),
        ),
        Container(
          alignment: Alignment.center,
          width: 100,
          child: Text('Video'),
        ),
      ],
      constraints: BoxConstraints(minHeight: 35),
      borderRadius: BorderRadius.circular(30),
      borderColor: Colors.white,
      borderWidth: 1.7,
      selectedBorderColor: Colors.white,
      fillColor: Colors.white,
      selectedColor: Colors.black,
      textStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      onPressed: onPressed,
      isSelected: isSelected,
    );
  }
}
