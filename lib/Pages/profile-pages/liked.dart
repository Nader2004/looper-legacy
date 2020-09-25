import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:looper/widgets/comedy-joke.dart';
import 'package:looper/widgets/post.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class LikedListPage extends StatefulWidget {
  LikedListPage({Key key}) : super(key: key);

  @override
  _LikedListPageState createState() => _LikedListPageState();
}

class _LikedListPageState extends State<LikedListPage> {
  String _id = 'empty';
  int _selectedIndex = 0;
  Stream<QuerySnapshot> _stream = Stream.empty();

  @override
  void initState() {
    super.initState();
    setPrefs();
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    setState(() {
      _id = _prefs.get('id');
    });
    _stream = FirebaseFirestore.instance
        .collection('posts')
        .where('liked-people', arrayContains: _id)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData.fallback(),
        centerTitle: true,
        title: Text(
          'Your Likes',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: _id == 'empty' && _stream == Stream.empty()
          ? SizedBox.shrink()
          : Stack(
              children: [
                StreamBuilder(
                  stream: _stream,
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 1.2,
                          valueColor: AlwaysStoppedAnimation(Colors.black),
                        ),
                      );
                    } else {
                      if (snapshot.data.docs.length == 0) {
                        return Center(
                          child: Text(
                            'You didn\'t like yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      return _selectedIndex == 0 || _selectedIndex == 2
                          ? ListView.builder(
                              itemCount: snapshot.data.docs.length,
                              itemBuilder: (context, index) {
                                if (_selectedIndex == 0) {
                                  return PostWidget(
                                    snapshot: snapshot.data.docs[index],
                                  );
                                } else {
                                  return ComedyJoke(
                                    data: snapshot.data.docs[index],
                                  );
                                }
                              },
                            )
                          : GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: snapshot.data.docs.length,
                              itemBuilder: (context, index) {
                                return VideoWidget(
                                  videoUrl: snapshot.data.docs[index]
                                      .data()['videoUrl'],
                                );
                              },
                            );
                    }
                  },
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: FlutterToggleTab(
                      width: 80,
                      borderRadius: 40,
                      labels: ['', '', '', '', ''],
                      icons: [
                        MdiIcons.cards,
                        MdiIcons.star,
                        MdiIcons.dramaMasks,
                        MdiIcons.baseball,
                        MdiIcons.flagCheckered,
                      ],
                      selectedBackgroundColors: [
                        Colors.black,
                        Colors.black,
                      ],
                      initialIndex: 0,
                      selectedIndex: _selectedIndex,
                      selectedLabelIndex: (int index) {
                        setState(
                          () {
                            _selectedIndex = index;
                            if (_selectedIndex == 0) {
                              _stream = FirebaseFirestore.instance
                                  .collection('posts')
                                  .where('liked-people', arrayContains: _id)
                                  .orderBy('timestamp', descending: true)
                                  .snapshots();
                            } else if (_selectedIndex == 1) {
                              _stream = FirebaseFirestore.instance
                                  .collection('talents')
                                  .where('yes-counted-people',
                                      arrayContains: _id)
                                  .orderBy('timestamp', descending: true)
                                  .snapshots();
                            } else if (_selectedIndex == 2) {
                              _stream = FirebaseFirestore.instance
                                  .collection('comedy')
                                  .where('laughed-people', arrayContains: _id)
                                  .orderBy('timestamp', descending: true)
                                  .snapshots();
                            } else if (_selectedIndex == 3) {
                              _stream = FirebaseFirestore.instance
                                  .collection('sports')
                                  .where('liked-people', arrayContains: _id)
                                  .orderBy('timestamp', descending: true)
                                  .snapshots();
                            } else if (_selectedIndex == 4) {
                              _stream = FirebaseFirestore.instance
                                  .collection('challenge')
                                  .where('liked-people', arrayContains: _id)
                                  .orderBy('timestamp', descending: true)
                                  .snapshots();
                            } else {
                              return;
                            }
                          },
                        );
                      },
                      selectedTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                      unSelectedTextStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class VideoWidget extends StatefulWidget {
  final String videoUrl;

  VideoWidget({Key key, this.videoUrl}) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.network(widget.videoUrl);
    _videoController.initialize()..then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.width / 2,
          height: MediaQuery.of(context).size.width / 2,
          child: !_videoController.value.initialized
              ? Container(color: Colors.grey[400])
              : OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width /
                          _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                ),
        ),
        Positioned(
          right: MediaQuery.of(context).size.width / 4.5,
          top: MediaQuery.of(context).size.width / 4.5,
          child: GestureDetector(
            child: FaIcon(
              FontAwesomeIcons.play,
              size: 20,
              color: Colors.white,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPreviewWidget(
                    videoPath: widget.videoUrl,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class VideoPreviewWidget extends StatefulWidget {
  final String videoPath;
  VideoPreviewWidget({Key key, this.videoPath}) : super(key: key);

  @override
  _VideoPreviewWidgetState createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
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
