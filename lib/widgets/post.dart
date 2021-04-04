import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/services/personality.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage.dart';
import '../services/database.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import 'package:flutter_bounce/flutter_bounce.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
import '../models/postModel.dart';
import '../models/commentModel.dart';

enum PlayerState { stopped, playing, paused }

class PostWidget extends StatefulWidget {
  final DocumentSnapshot snapshot;
  const PostWidget({Key key, this.snapshot}) : super(key: key);
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget>
    with SingleTickerProviderStateMixin {
  String _userId = '';
  Post _post;
  AudioPlayer _audioPlayer;
  int _mediaIndex = 0;
  String _userName;
  String _userImage;
  String _commentMedia = '';
  bool _isFollowing = false;
  bool _isLikedPost = false;
  bool _choosedOption1 = false;
  bool _choosedOption2 = false;
  int _likePostCount = 0;
  int _commentCount = 0;
  int _shareCount = 0;
  int _option1Count = 0;
  int _option2Count = 0;

  TextEditingController _textEditingController;
  StreamSubscription<Duration> _durationStream;
  StreamSubscription<Duration> _positionStream;
  StreamSubscription<void> _onCompleteStream;
  Duration _audioPosition;
  Duration _audioDuration;
  PlayerState _playerState;
  AnimationController _animationController;
  Animation<double> _animation;
  Stream<QuerySnapshot> _blockedUsers;
  bool get _isPlaying => _playerState == PlayerState.playing;
  bool get _isPaused => _playerState == PlayerState.paused;
  bool get _isStopped => _playerState == PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    getUserData();
    _prepareAudioStreaming();
    initializeAnimation();
  }

  void getUserData() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = _prefs.get('id');
      _blockedUsers = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('blocked-users')
          .snapshots();
      _post = Post.fromDoc(widget.snapshot);
      _likePostCount = _post.likeCount;
      _commentCount = _post.commentCount;
      _shareCount = _post.shareCount;
      _isLikedPost = _post.likedPeople.contains(
        _userId,
      );
      _choosedOption1 = _post.option1People.contains(_userId);
      _choosedOption2 = _post.option2People.contains(_userId);
      _option1Count = _post.option1Count;
      _option2Count = _post.option2Count;
      _textEditingController = TextEditingController();
    });
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final DocumentSnapshot _snapshot =
        await _firestore.collection('users').doc(_userId).get();
    final bool isFollowing =
        await DatabaseService.checkIsFollowing(_post.authorId);
    _userName = _snapshot?.data()['username'];
    _userImage = _snapshot?.data()['profilePictureUrl'];
    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
      });
    }
  }

  void initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _animationController,
    );
  }

  void _prepareAudioStreaming() {
    _audioPlayer = AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);
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
        _animationController.reset();
      }),
    );
  }

  Future<int> _play() async {
    print(_post.audioUrl);
    final playPosition = (_audioPosition != null &&
            _audioPosition != null &&
            _audioPosition.inSeconds > 0 &&
            _audioPosition.inSeconds < _audioPosition.inSeconds)
        ? _audioPosition
        : null;
    final result = await _audioPlayer.play(
      _post.audioUrl,
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

  String getPostTiming() {
    String msg = '';
    var dt = DateTime.parse(_post.timestamp).toLocal();

    if (DateTime.now().toLocal().isBefore(dt)) {
      return DateFormat.jm()
          .format(DateTime.parse(_post.timestamp).toLocal())
          .toString();
    }

    var dur = DateTime.now().toLocal().difference(dt);
    if (dur.inDays > 0) {
      msg = '${dur.inDays} d ago';
      return dur.inDays == 1 ? '1d ago' : DateFormat("dd MMM").format(dt);
    } else if (dur.inHours > 0) {
      msg = '${dur.inHours} h ago';
    } else if (dur.inMinutes > 0) {
      msg = '${dur.inMinutes} m ago';
    } else if (dur.inSeconds > 0) {
      msg = '${dur.inSeconds} s ago';
    } else {
      msg = 'now';
    }
    return msg;
  }

  void showReportDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report this post'),
        content: Text(
          'A report will get send with your username and the post you have reported',
        ),
        actions: [
          FlatButton(
            onPressed: () async {
              final Email _reportEmail = Email(
                body:
                    'User $_userName reported the post ${_post.id} from the author ${_post.authorName}',
                subject: 'POST REPORT',
                recipients: ['nk.loop2020@gmail.com'],
                isHTML: false,
              );
              FlutterEmailSender.send(_reportEmail);
              Navigator.pop(context);
            },
            child: Text('Send Report'),
          ),
          FlatButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPostWidget(List<String> blockedUsers) {
    return Container(
      margin: EdgeInsets.only(top: 8, left: 8, bottom: 10),
      child: Row(
        children: <Widget>[
          Container(
            height: 50,
            width: 50,
            decoration: ShapeDecoration(
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(
                        userId: _post.authorId,
                      ),
                    ),
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: _post.authorImage,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[400],
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _post.authorName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              SizedBox(height: 3),
              Text(
                getPostTiming(),
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Spacer(),
          Row(
            children: <Widget>[
              ButtonTheme(
                minWidth: 85,
                height: 25,
                child: FlatButton(
                  padding: EdgeInsets.all(0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: _post.authorName == _userName
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                  color: _isFollowing == true ? Colors.black : Colors.white,
                  textColor: _isFollowing == true ? Colors.white : Colors.black,
                  onPressed: _post.authorName == _userName
                      ? null
                      : () {
                          if (_isFollowing == false) {
                            DatabaseService.followUser(
                              _post.authorId,
                              _post.authorName,
                            );
                            NotificationsService.sendNotification(
                              'New Follower',
                              '$_userName followed you',
                              _post.authorId,
                              'post',
                              _post.id,
                            );
                            NotificationsService.subscribeToTopic(
                                _post.authorId);
                            setState(() {
                              _isFollowing = true;
                            });
                          } else {
                            DatabaseService.unFollowUser(_post.authorId);
                            NotificationsService.unsubscribeFromTopic(
                                _post.authorId);
                            setState(() {
                              _isFollowing = false;
                            });
                          }
                        },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isFollowing == true
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : SizedBox.shrink(),
                      _isFollowing == true
                          ? SizedBox(width: 5)
                          : SizedBox.shrink(),
                      Text(
                        _isFollowing == true ? 'Following' : 'FOLLOW',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 2.7,
                        padding: EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Container(
                              width: MediaQuery.of(context).size.width * 0.1,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Theme.of(context).dividerColor,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.share,
                                color: Colors.grey,
                                size: 22,
                              ),
                              onTap: () async {
                                if (_post.type == 1) {
                                  if (_post.authorName != _userName) {
                                    await PersonalityService.setTextInput(
                                      _post.text,
                                    );
                                  }
                                  Share.share(
                                    _post.text,
                                    subject: 'from ${_post.authorName}',
                                  );
                                } else if (_post.type == 2) {
                                  if (_post.authorName != _userName) {
                                    await PersonalityService.setTextInput(
                                      '${_post.question['question']}? ${_post.question['option1']} or ${_post.question['option2f']}',
                                    );
                                  }
                                  Share.share(
                                    _post.question['question'],
                                    subject: 'from ${_post.authorName}',
                                  );
                                } else if (_post.type == 3) {
                                  if (_post.mediaUrl.length == 1) {
                                    var request =
                                        await HttpClient().getUrl(Uri.parse(
                                      _post.mediaUrl.first['media'],
                                    ));
                                    var response = await request.close();
                                    Uint8List bytes =
                                        await consolidateHttpClientResponseBytes(
                                            response);
                                    var buffer = bytes.buffer;
                                    ByteData byteData = ByteData.view(buffer);
                                    var tempDir = await getTemporaryDirectory();
                                    File file =
                                        await File('${tempDir.path}/img')
                                            .writeAsBytes(buffer.asUint8List(
                                                byteData.offsetInBytes,
                                                byteData.lengthInBytes));

                                    Share.shareFiles(
                                      [file.path],
                                      text: 'from ${_post.authorName}',
                                    );
                                    if (_post.authorName != _userName) {
                                      if (_post.mediaUrl.first['media']
                                          .contains('.mp4')) {
                                        await PersonalityService.setVideoInput(
                                          _post.mediaUrl.first['media'],
                                        );
                                      } else {
                                        await PersonalityService.setImageInput(
                                          _post.mediaUrl.first['media'],
                                        );
                                      }
                                    }
                                  } else {
                                    Fluttertoast.showToast(
                                      msg: 'Can\'t share more than one media',
                                    );
                                    if (_post.authorName != _userName) {
                                      for (String media in _post.mediaUrl) {
                                        if (media.toString().contains('.mp4')) {
                                          await PersonalityService
                                              .setVideoInput(
                                            media.toString(),
                                          );
                                        } else {
                                          await PersonalityService
                                              .setImageInput(
                                            media.toString(),
                                          );
                                        }
                                      }
                                    }
                                  }
                                } else if (_post.type == 4) {
                                  if (_post.authorName != _userName) {
                                    if (_post.gif['caption'] != '') {
                                      await PersonalityService.setTextInput(
                                        _post.gif['caption'],
                                      );
                                    }
                                  }
                                  var request = await HttpClient()
                                      .getUrl(Uri.parse(_post.gif['gif']));
                                  var response = await request.close();
                                  Uint8List bytes =
                                      await consolidateHttpClientResponseBytes(
                                          response);
                                  var buffer = bytes.buffer;
                                  ByteData byteData = ByteData.view(buffer);
                                  var tempDir = await getTemporaryDirectory();
                                  File file = await File('${tempDir.path}/img')
                                      .writeAsBytes(buffer.asUint8List(
                                          byteData.offsetInBytes,
                                          byteData.lengthInBytes));

                                  Share.shareFiles(
                                    [file.path],
                                    text: 'from ${_post.authorName}',
                                  );
                                } else {
                                  if (_post.authorName != _userName) {
                                    await PersonalityService.setAudioInput(
                                      _post.audioUrl,
                                    );
                                  }
                                  var request = await HttpClient()
                                      .getUrl(Uri.parse(_post.audioUrl));
                                  var response = await request.close();
                                  Uint8List bytes =
                                      await consolidateHttpClientResponseBytes(
                                          response);
                                  var buffer = bytes.buffer;
                                  ByteData byteData = ByteData.view(buffer);
                                  var tempDir = await getTemporaryDirectory();
                                  File file = await File('${tempDir.path}/img')
                                      .writeAsBytes(buffer.asUint8List(
                                          byteData.offsetInBytes,
                                          byteData.lengthInBytes));

                                  Share.shareFiles(
                                    [file.path],
                                    text: 'from ${_post.authorName}',
                                  );
                                }
                              },
                              title: Text(
                                'SHARE',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.bookmark,
                                color: Colors.grey,
                                size: 22,
                              ),
                              title: Text(
                                'SAVE',
                                style: TextStyle(color: Colors.grey),
                              ),
                              onTap: () {
                                DatabaseService.saveContent(
                                  'saved-posts',
                                  _post.id,
                                );
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.report,
                                color: Colors.red,
                                size: 22,
                              ),
                              title: Text(
                                'Report Post',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                showReportDialog();
                              },
                            ),
                            _post.authorName == _userName
                                ? ListTile(
                                    leading: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 22,
                                    ),
                                    title: Text(
                                      'DELETE',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onTap: () {
                                      DatabaseService.deletePost(_post.id);
                                      Navigator.pop(context);
                                    },
                                  )
                                : SizedBox.shrink(),
                            _post.authorName != _userName
                                ? ListTile(
                                    leading: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 22,
                                    ),
                                    title: Text(
                                      !blockedUsers.contains(_post.authorId)
                                          ? 'Block ${_post.authorName}'
                                          : 'Unblock ${_post.authorName}',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onTap: () {
                                      if (!blockedUsers
                                          .contains(_post.authorId)) {
                                        DatabaseService.blockUser(
                                          _userId,
                                          _post.authorId,
                                        );
                                        Fluttertoast.showToast(
                                          msg: '${_post.authorName} is blocked',
                                        ).then((_) {
                                          Timer(
                                            Duration(milliseconds: 1500),
                                            () => Fluttertoast.showToast(
                                              msg:
                                                  'To unBlock ${_post.authorName} , go to his profile page',
                                            ),
                                          );
                                        });
                                      } else {
                                        DatabaseService.unBlockUser(
                                          _userId,
                                          _post.authorId,
                                        );
                                        Fluttertoast.showToast(
                                          msg:
                                              '${_post.authorName} is unBlocked',
                                        );
                                      }
                                      Navigator.pop(context);
                                    },
                                  )
                                : SizedBox.shrink(),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: Icon(
                  MdiIcons.dotsVertical,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareLabel() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: Row(
        children: <Widget>[
          Text(
            '${_post.shareAuthorName} shared',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 5),
          Icon(MdiIcons.share, color: Colors.grey[700], size: 17),
        ],
      ),
    );
  }

  Widget _buildImagePost(
    double screenWidth,
    double screenHeight,
    double elevation,
    String image,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 15, left: 7),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: image,
          width: screenWidth - 40,
          height: screenHeight / 3.5,
          progressIndicatorBuilder: (context, url, downloadProgress) => Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(
                    backgroundColor: Colors.grey,
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                    strokeWidth: 1.5,
                    value: downloadProgress.progress),
              ),
            ),
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPostMediaContent(double screenWidth, double screenHeight) {
    if (_post.mediaUrl.length == 1 && _post.mediaUrl.first['type'] == '0') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImagePreviewWidget(
                imageUrl: _post.mediaUrl.first['media'],
              ),
            ),
          );
        },
        child: _buildImagePost(
          screenWidth,
          screenHeight,
          16,
          _post.mediaUrl.first['media'],
        ),
      );
    } else if (_post.mediaUrl.length == 1 &&
        _post.mediaUrl.first['type'] == '1') {
      return VideoWidget(videoUrl: _post.mediaUrl.first['media']);
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: CarouselSlider(
          options: CarouselOptions(
            height: screenHeight / 3,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            onPageChanged: (int index, CarouselPageChangedReason reason) {
              setState(() {
                _mediaIndex = index;
              });
            },
          ),
          items: List.generate(
            _post.mediaUrl.length,
            (index) {
              if (_post.mediaUrl[index]['type'] == '0') {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImagePreviewWidget(
                          imageUrl: _post.mediaUrl[index]['media'],
                        ),
                      ),
                    );
                  },
                  child: _buildImagePost(
                    screenWidth,
                    screenHeight,
                    5,
                    _post.mediaUrl[index]['media'],
                  ),
                );
              } else {
                return VideoWidget(
                  videoUrl: _post.mediaUrl[index]['media'],
                );
              }
            },
          ),
        ),
      );
    }
  }

  Widget _buildBottomPostPart() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(_post.id)
                    .collection('comments')
                    .get(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container();
                  }
                  if (snapshot.data.docs.length == 0) {
                    return Text(
                      'No comments yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                  final DocumentSnapshot _doc =
                      snapshot.data.docs[snapshot.data.docs.length - 1];
                  return Text(
                    _doc.data()['content'] != null
                        ? _doc.data()['content']
                        : 'Check out comments',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                }),
          ),
        ),
        Container(
          height: 20,
          padding: EdgeInsets.symmetric(horizontal: 10),
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30),
          ),
          child: IntrinsicWidth(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  MdiIcons.eyeOutline,
                  size: 16,
                  color: Colors.white,
                ),
                SizedBox(width: 5),
                Text(
                  _post.viewsCount.toString(),
                  style: GoogleFonts.comfortaa(
                    textStyle: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Bounce(
                  onPressed: () {
                    DatabaseService.sharePost(_post.id, _post, _userName);
                    NotificationsService.sendNotificationToFollowers(
                      'New share',
                      '$_userName shared your post',
                      _post.authorId,
                      'post',
                      _post.id,
                    );
                    NotificationsService.sendNotificationToFollowers(
                      'New share',
                      '$_userName shared a post',
                      _post.authorId,
                      'post',
                      _post.id,
                    );
                    setState(() {
                      _shareCount++;
                    });

                    if (_post.type == 1) {
                      PersonalityService.setTextInput(_post.text);
                    } else if (_post.type == 2) {
                      PersonalityService.setTextInput(
                        '${_post.question['question']}',
                      );
                    } else if (_post.type == 3) {
                      if (_post.mediaUrl.length == 1) {
                        if (_post.mediaUrl.first.toString().contains('.mp4')) {
                          PersonalityService.setVideoInput(
                              _post.mediaUrl.first.toString());
                        } else {
                          PersonalityService.setImageInput(
                              _post.mediaUrl.first.toString());
                        }
                      } else {
                        for (String media in _post.mediaUrl) {
                          if (media.toString().contains('.mp4')) {
                            PersonalityService.setVideoInput(
                              media.toString(),
                            );
                          } else {
                            PersonalityService.setImageInput(
                              media.toString(),
                            );
                          }
                        }
                      }
                    } else if (_post.type == 4) {
                      if (_post.gif['caption'].toString().isNotEmpty) {
                        PersonalityService.setTextInput(
                          _post.gif['caption'].toString(),
                        );
                      }
                    } else {
                      PersonalityService.setAudioInput(_post.audioUrl);
                      if (_post.audioImage.isNotEmpty) {
                        PersonalityService.setImageInput(_post.audioImage);
                      }
                      if (_post.audioDescribtion.isNotEmpty) {
                        PersonalityService.setTextInput(
                          _post.audioDescribtion,
                        );
                      }
                    }
                  },
                  duration: Duration(milliseconds: 100),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        MdiIcons.shareAllOutline,
                        color: Colors.black,
                        size: 22,
                      ),
                      SizedBox(height: 5),
                      Text(
                        _shareCount.toString(),
                        style: GoogleFonts.comfortaa(),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Bounce(
                  onPressed: openCommentSection,
                  duration: Duration(milliseconds: 100),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        MdiIcons.commentTextMultipleOutline,
                        color: Colors.black,
                        size: 22,
                      ),
                      SizedBox(height: 5),
                      Text(
                        _commentCount.toString(),
                        style: GoogleFonts.comfortaa(),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Bounce(
                  duration: Duration(milliseconds: 100),
                  onPressed: () {
                    setState(() {
                      if (!_isLikedPost) {
                        _likePostCount++;
                        _isLikedPost = true;

                        DatabaseService.like(
                          'posts',
                          _post.id,
                          _userId,
                        );
                        NotificationsService.sendNotification(
                          'New Like ❤',
                          '$_userName liked your post',
                          _post.authorId,
                          'post',
                          _post.id,
                        );
                        NotificationsService.sendNotificationToFollowers(
                          'New Like ❤',
                          '$_userName liked a post',
                          _post.authorId,
                          'post',
                          _post.id,
                        );
                        if (_post.type == 1) {
                          PersonalityService.setTextInput(_post.text);
                        } else if (_post.type == 2) {
                          PersonalityService.setTextInput(
                            '${_post.question['question']}',
                          );
                        } else if (_post.type == 3) {
                          if (_post.mediaUrl.length == 1) {
                            if (_post.mediaUrl.first
                                .toString()
                                .contains('.mp4')) {
                              PersonalityService.setVideoInput(
                                  _post.mediaUrl.first['media'].toString());
                            } else {
                              PersonalityService.setImageInput(
                                  _post.mediaUrl.first['media'].toString());
                            }
                          } else {
                            for (Map<String, dynamic> media in _post.mediaUrl) {
                              if (media.toString().contains('.mp4')) {
                                PersonalityService.setVideoInput(
                                  media['media'].toString(),
                                );
                              } else {
                                PersonalityService.setImageInput(
                                  media['media'].toString(),
                                );
                              }
                            }
                          }
                        } else if (_post.type == 4) {
                          if (_post.gif['caption'].toString().isNotEmpty) {
                            PersonalityService.setTextInput(
                              _post.gif['caption'].toString(),
                            );
                          }
                        } else {
                          PersonalityService.setAudioInput(_post.audioUrl);
                          if (_post.audioImage.isNotEmpty) {
                            PersonalityService.setImageInput(_post.audioImage);
                          }
                          if (_post.audioDescribtion.isNotEmpty) {
                            PersonalityService.setTextInput(
                              _post.audioDescribtion,
                            );
                          }
                        }
                      } else {
                        _likePostCount--;
                        _isLikedPost = false;
                        DatabaseService.unLike(
                          'posts',
                          _post.id,
                          _userId,
                        );
                      }
                    });
                  },
                  child: Column(
                    children: <Widget>[
                      Icon(
                        _isLikedPost == true
                            ? MdiIcons.heart
                            : MdiIcons.heartOutline,
                        color: _isLikedPost == true ? Colors.red : Colors.black,
                        size: 25,
                      ),
                      SizedBox(height: 5),
                      Text(
                        _likePostCount.toString(),
                        style: GoogleFonts.comfortaa(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationWidget() {
    if (_post.location != null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: <Widget>[
            Icon(Icons.location_on, color: Colors.blue, size: 16),
            Text(
              _post.location,
              style: TextStyle(color: Colors.blue),
            ),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
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
                  List<String> _media = [];
                  final ImagePicker _picker = ImagePicker();
                  final PickedFile _file =
                      await _picker.getImage(source: ImageSource.camera);
                  _commentMedia = _file.path;
                  if (_commentMedia.isNotEmpty) {
                    await PersonalityService.setImageInput(_commentMedia);
                    final String _commentDate =
                        TimeOfDay.fromDateTime(DateTime.now()).format(context);
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                    if (_commentMedia.isNotEmpty) {
                      _media = await StorageService.uploadMediaFile(
                        [File(_commentMedia)],
                        'comments/media',
                      );
                    }
                    final Comment _comment = Comment(
                      author: _userName,
                      authorId: _userId,
                      authorImage: _userImage,
                      media: _media.first,
                      type: 1,
                      timestamp: _commentDate,
                    );
                    DatabaseService.addComment(
                      'posts',
                      _post.id,
                      _comment,
                    );
                    NotificationsService.sendNotification(
                      'New comment',
                      '$_userName commented on your post',
                      _post.authorId,
                      'post',
                      _post.authorId,
                    );
                    NotificationsService.sendNotificationToFollowers(
                      'New comment',
                      '$_userName commented on a post',
                      _post.authorId,
                      'post',
                      _post.authorId,
                    );
                    setState(() {
                      _commentCount++;
                    });
                  }
                },
                title: Text('Take a Photo'),
              ),
              ListTile(
                onTap: () async {
                  List<String> _media = [];
                  final ImagePicker _picker = ImagePicker();
                  final PickedFile _file =
                      await _picker.getImage(source: ImageSource.gallery);
                  _commentMedia = _file.path;

                  if (_commentMedia.isNotEmpty) {
                    await PersonalityService.setImageInput(_commentMedia);
                    final String _commentDate =
                        TimeOfDay.fromDateTime(DateTime.now()).format(context);
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                    if (_commentMedia.isNotEmpty) {
                      _media = await StorageService.uploadMediaFile(
                        [File(_commentMedia)],
                        'comments/media',
                      );
                    }
                    final Comment _comment = Comment(
                      author: _userName,
                      authorId: _userId,
                      authorImage: _userImage,
                      media: _media.first,
                      type: 1,
                      timestamp: _commentDate,
                    );
                    DatabaseService.addComment(
                      'posts',
                      _post.id,
                      _comment,
                    );
                    NotificationsService.sendNotification(
                      'New comment',
                      '$_userName commented on your post',
                      _post.authorId,
                      'post',
                      _post.authorId,
                    );
                    NotificationsService.sendNotificationToFollowers(
                      'New comment',
                      '$_userName commented on a post',
                      _post.authorId,
                      'post',
                      _post.authorId,
                    );
                    setState(() {
                      _commentCount++;
                    });
                  }
                },
                title: Text('Get from Gallery'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openCommentSection() {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 1.5,
            padding: MediaQuery.of(context).viewInsets,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    _commentCount.toString() + ' Comments',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Divider(),
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(_post.id)
                        .collection('comments')
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SpinKitWave(
                          color: Colors.black,
                          size: 27,
                        );
                      } else {
                        return ListView.builder(
                          itemBuilder: (context, int index) {
                            final Comment _comment = Comment.fromDoc(
                              snapshot.data.docs[index],
                            );
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 10,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ProfilePage(
                                            userId: _comment.authorId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.grey[400],
                                      backgroundImage:
                                          CachedNetworkImageProvider(
                                        _comment.authorImage,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: _comment.type == 1 ? 10 : 5),
                                  _comment.type == 1
                                      ? Stack(
                                          children: <Widget>[
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ProfilePage(
                                                        userId:
                                                            _comment.authorId,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: CachedNetworkImage(
                                                  imageUrl: _comment.media,
                                                  fit: BoxFit.cover,
                                                  progressIndicatorBuilder:
                                                      (context, url,
                                                              downloadProgress) =>
                                                          Padding(
                                                    padding:
                                                        EdgeInsets.all(10.0),
                                                    child: CircularProgressIndicator(
                                                        backgroundColor:
                                                            Colors.grey,
                                                        valueColor:
                                                            AlwaysStoppedAnimation(
                                                                Colors.black),
                                                        value: downloadProgress
                                                            .progress),
                                                  ),
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height /
                                                      3,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .height /
                                                      3,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 10,
                                              bottom: 10,
                                              child: Text(
                                                _comment.timestamp,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              3,
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _comment.author == _userName
                                                ? Colors.blue.withOpacity(0.1)
                                                : Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Flexible(
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: SelectableLinkify(
                                                    onOpen: (link) async {
                                                      if (await canLaunch(
                                                          link.url)) {
                                                        await launch(link.url);
                                                      } else {
                                                        Fluttertoast.showToast(
                                                          msg:
                                                              'can not launch this link',
                                                        );
                                                      }
                                                    },
                                                    text: _comment.content,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                _comment.timestamp,
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  SizedBox(
                                    width: _comment.type == 1 ? 10 : 5,
                                  ),
                                  _comment.type == 1
                                      ? Column(
                                          children: [
                                            Column(
                                              children: <Widget>[
                                                Bounce(
                                                  onPressed: () {
                                                    if (!_comment.likedPeople
                                                        .contains(_userId)) {
                                                      DatabaseService
                                                          .likeComment(
                                                        _post.id,
                                                        'posts',
                                                        _comment.id,
                                                        _userId,
                                                      );
                                                      PersonalityService
                                                          .setImageInput(
                                                        _comment.media,
                                                      );
                                                    } else {
                                                      DatabaseService
                                                          .unLikeComment(
                                                        _post.id,
                                                        'posts',
                                                        _comment.id,
                                                        _userId,
                                                      );
                                                    }
                                                  },
                                                  duration: Duration(
                                                      milliseconds: 100),
                                                  child: Icon(
                                                    Icons.favorite,
                                                    size: 16,
                                                    color: _comment.likedPeople
                                                            .contains(_userId)
                                                        ? Colors.red
                                                        : Colors.black,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(_comment.likes.toString()),
                                              ],
                                            ),
                                            SizedBox(height: 5),
                                            Column(
                                              children: <Widget>[
                                                Bounce(
                                                  onPressed: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            ReplyPage(
                                                          userId: _userId,
                                                          commentId:
                                                              _comment.id,
                                                          objectId: _post.id,
                                                          userName: _userName,
                                                          userImage: _userImage,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  duration: Duration(
                                                      milliseconds: 100),
                                                  child: Icon(
                                                    Icons.reply,
                                                    size: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(_comment.replies
                                                    .toString()),
                                              ],
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: <Widget>[
                                            Bounce(
                                              onPressed: () {
                                                if (!_comment.likedPeople
                                                    .contains(_userId)) {
                                                  DatabaseService.likeComment(
                                                    _post.id,
                                                    'posts',
                                                    _comment.id,
                                                    _userId,
                                                  );
                                                  PersonalityService
                                                      .setTextInput(
                                                    _comment.content,
                                                  );
                                                } else {
                                                  DatabaseService.unLikeComment(
                                                    _post.id,
                                                    'posts',
                                                    _comment.id,
                                                    _userId,
                                                  );
                                                }
                                              },
                                              duration:
                                                  Duration(milliseconds: 100),
                                              child: Icon(
                                                Icons.favorite,
                                                size: 16,
                                                color: _comment.likedPeople
                                                        .contains(_userId)
                                                    ? Colors.red
                                                    : Colors.black,
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                            Text(_comment.likes.toString()),
                                          ],
                                        ),
                                  SizedBox(width: 5),
                                  _comment.type == 1
                                      ? SizedBox.shrink()
                                      : Row(
                                          children: <Widget>[
                                            Bounce(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ReplyPage(
                                                      commentId: _comment.id,
                                                      comment: _comment.content,
                                                      objectId: _post.id,
                                                      userId: _userId,
                                                      userName: _userName,
                                                      userImage: _userImage,
                                                    ),
                                                  ),
                                                );
                                              },
                                              duration:
                                                  Duration(milliseconds: 100),
                                              child: Icon(
                                                Icons.reply,
                                                size: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                            Text(_comment.replies.toString()),
                                          ],
                                        ),
                                ],
                              ),
                            );
                          },
                          itemCount: snapshot.data.docs.length,
                        );
                      }
                    },
                  ),
                ),
                Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Bounce(
                        child: Icon(Icons.camera_alt),
                        onPressed: () async {
                          _showMediaPicker();
                        },
                        duration: Duration(milliseconds: 100),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: TextField(
                          controller: _textEditingController,
                          textInputAction: TextInputAction.none,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(10.0),
                            border: InputBorder.none,
                            hintText: 'Type a comment',
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final String _commentDate =
                            TimeOfDay.fromDateTime(DateTime.now())
                                .format(context);
                        FocusScope.of(context).requestFocus(FocusNode());
                        final Comment _comment = Comment(
                          author: _userName,
                          authorId: _userId,
                          authorImage: _userImage,
                          content: _textEditingController.text,
                          type: 0,
                          timestamp: _commentDate,
                        );
                        await PersonalityService.setTextInput(
                          _comment.content,
                        );
                        DatabaseService.addComment(
                          'posts',
                          _post.id,
                          _comment,
                        );
                        NotificationsService.sendNotification(
                          'New comment',
                          '$_userName commented on your post',
                          _post.authorId,
                          'post',
                          _post.authorId,
                        );
                        NotificationsService.sendNotificationToFollowers(
                          'New comment',
                          '$_userName commented on a post',
                          _post.authorId,
                          'post',
                          _post.authorId,
                        );
                        _textEditingController.clear();
                        setState(() {
                          _commentCount++;
                        });
                      },
                      icon: Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
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

  String getOptionPercentage(int count) {
    int total = _option1Count + _option2Count;
    double percentage = (count / total) * 100;
    return percentage.round().toString() + '%';
  }

  @override
  void didUpdateWidget(PostWidget oldWidget) {
    if (_post != Post.fromDoc(widget.snapshot)) {
      setState(() {
        _post = Post.fromDoc(widget.snapshot);
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _durationStream.cancel();
    _positionStream.cancel();
    _onCompleteStream.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double _screenWidth = MediaQuery.of(context).size.width;
    final double _screenHeight = MediaQuery.of(context).size.height;
    if (_post != null) {
      if (_post.type == 2) {
        return StreamBuilder(
            stream: _blockedUsers,
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox.shrink();
              }

              final List<String> blockedUsers =
                  snapshot.data.docs.map((e) => e.id).toList();
              if (blockedUsers.contains(_post.authorId)) {
                return Container();
              }
              return VisibilityDetector(
                key: Key(_post.id),
                onVisibilityChanged: (VisibilityInfo info) {
                  double _visibilePercentage = info.visibleFraction * 100;
                  Timer(
                    Duration(milliseconds: 2300),
                    () {
                      if (!_post.viewedPeople.contains(_userId)) {
                        if (_visibilePercentage == 100) {
                          DatabaseService.addView(
                            'posts',
                            _post.id,
                            _userId,
                          );
                        }
                      }
                    },
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: <Widget>[
                          _post.isShared == true
                              ? _buildShareLabel()
                              : SizedBox.shrink(),
                          _buildTopPostWidget(blockedUsers),
                          _buildLocationWidget(),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Container(
                              height: MediaQuery.of(context).size.width / 9,
                              constraints: BoxConstraints(
                                minWidth:
                                    MediaQuery.of(context).size.width / 10,
                                maxWidth:
                                    MediaQuery.of(context).size.width / 1.3,
                              ),
                              decoration: ShapeDecoration(
                                color: Colors.black,
                                shape: SuperellipseShape(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _post.question['question'],
                                style: GoogleFonts.abel(
                                  textStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          _post.question['media1'] != null &&
                                  _post.question['media2'] != null
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Column(
                                      children: <Widget>[
                                        _post.question['media1']
                                                .toString()
                                                .contains('.mp4')
                                            ? VideoQuestionThumbWidget(
                                                videoUrl:
                                                    _post.question['media1'],
                                              )
                                            : GestureDetector(
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ImagePreviewWidget(
                                                      imageUrl: _post
                                                          .question['media1'],
                                                    ),
                                                  ),
                                                ),
                                                child: Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      3,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      2,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    child: CachedNetworkImage(
                                                      imageUrl: _post
                                                          .question['media1'],
                                                      progressIndicatorBuilder:
                                                          (context, url,
                                                                  downloadProgress) =>
                                                              Padding(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child: Center(
                                                          child: SizedBox(
                                                            height: 40,
                                                            width: 40,
                                                            child: CircularProgressIndicator(
                                                                backgroundColor:
                                                                    Colors.grey,
                                                                valueColor:
                                                                    AlwaysStoppedAnimation(
                                                                        Colors
                                                                            .black),
                                                                strokeWidth:
                                                                    1.5,
                                                                value: downloadProgress
                                                                    .progress),
                                                          ),
                                                        ),
                                                      ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        SizedBox(height: 5),
                                        ButtonTheme(
                                          minWidth: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              4,
                                          child: OutlineButton(
                                            borderSide: BorderSide(
                                              color: _choosedOption1 == true
                                                  ? Colors.black
                                                  : Colors.grey,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            child: _choosedOption1 == true
                                                ? Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: <Widget>[
                                                      Text(
                                                        _post.question[
                                                            'option1'],
                                                        style: TextStyle(
                                                          color:
                                                              _choosedOption1 ==
                                                                      true
                                                                  ? Colors.black
                                                                  : Colors.grey,
                                                        ),
                                                      ),
                                                      SizedBox(width: 5),
                                                      Text(
                                                        getOptionPercentage(
                                                          _option1Count,
                                                        ),
                                                        style: TextStyle(
                                                          color:
                                                              Colors.blueGrey,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Text(
                                                    _post.question['option1'],
                                                    style: TextStyle(
                                                      color: _choosedOption1 ==
                                                              true
                                                          ? Colors.black
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                            onPressed: () {
                                              if (!_choosedOption1 &&
                                                  !_choosedOption2) {
                                                setState(() {
                                                  _choosedOption1 = true;
                                                  _option1Count++;
                                                });
                                                DatabaseService.chooseOption1(
                                                  _post.id,
                                                  _userId,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: <Widget>[
                                        _post.question['media2']
                                                .toString()
                                                .contains('.mp4')
                                            ? VideoQuestionThumbWidget(
                                                videoUrl:
                                                    _post.question['media2'],
                                              )
                                            : GestureDetector(
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ImagePreviewWidget(
                                                      imageUrl: _post
                                                          .question['media2'],
                                                    ),
                                                  ),
                                                ),
                                                child: Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      3,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      2,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    child: CachedNetworkImage(
                                                      imageUrl: _post
                                                          .question['media2'],
                                                      progressIndicatorBuilder:
                                                          (context, url,
                                                                  downloadProgress) =>
                                                              Padding(
                                                        padding:
                                                            EdgeInsets.all(8.0),
                                                        child: Center(
                                                          child: SizedBox(
                                                            height: 40,
                                                            width: 40,
                                                            child: CircularProgressIndicator(
                                                                backgroundColor:
                                                                    Colors.grey,
                                                                valueColor:
                                                                    AlwaysStoppedAnimation(
                                                                        Colors
                                                                            .black),
                                                                strokeWidth:
                                                                    1.5,
                                                                value: downloadProgress
                                                                    .progress),
                                                          ),
                                                        ),
                                                      ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        SizedBox(height: 5),
                                        ButtonTheme(
                                          minWidth: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              4,
                                          child: OutlineButton(
                                            borderSide: BorderSide(
                                              color: _choosedOption2 == true
                                                  ? Colors.black
                                                  : Colors.grey,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            child: _choosedOption2 == true
                                                ? Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: <Widget>[
                                                      Text(
                                                        _post.question[
                                                            'option2'],
                                                        style: TextStyle(
                                                          color:
                                                              _choosedOption2 ==
                                                                      true
                                                                  ? Colors.black
                                                                  : Colors.grey,
                                                        ),
                                                      ),
                                                      SizedBox(width: 5),
                                                      Text(
                                                        getOptionPercentage(
                                                          _option2Count,
                                                        ),
                                                        style: TextStyle(
                                                          color:
                                                              Colors.blueGrey,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Text(
                                                    _post.question['option2'],
                                                    style: TextStyle(
                                                      color: _choosedOption2 ==
                                                              true
                                                          ? Colors.black
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                            onPressed: () {
                                              if (!_choosedOption2 &&
                                                  !_choosedOption1) {
                                                setState(() {
                                                  _choosedOption2 = true;
                                                  _option2Count++;
                                                });
                                                DatabaseService.chooseOption2(
                                                  _post.id,
                                                  _userId,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Column(
                                  children: <Widget>[
                                    ButtonTheme(
                                      minWidth:
                                          MediaQuery.of(context).size.width / 4,
                                      child: OutlineButton(
                                        borderSide: BorderSide(
                                          color: _choosedOption1 == true
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: _choosedOption1 == true
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  Text(
                                                    _post.question['option1'],
                                                    style: TextStyle(
                                                      color: _choosedOption1 ==
                                                              true
                                                          ? Colors.black
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                                  SizedBox(width: 5),
                                                  Text(
                                                    getOptionPercentage(
                                                      _option1Count,
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.blueGrey,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                _post.question['option1'],
                                                style: TextStyle(
                                                  color: _choosedOption1 == true
                                                      ? Colors.black
                                                      : Colors.grey,
                                                ),
                                              ),
                                        onPressed: () {
                                          if (!_choosedOption1 &&
                                              !_choosedOption2) {
                                            setState(() {
                                              _choosedOption1 = true;
                                              _option1Count++;
                                            });
                                            DatabaseService.chooseOption1(
                                              _post.id,
                                              _userId,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    ButtonTheme(
                                      minWidth:
                                          MediaQuery.of(context).size.width / 4,
                                      child: OutlineButton(
                                        borderSide: BorderSide(
                                          color: _choosedOption2 == true
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: _choosedOption2 == true
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  Text(
                                                    _post.question['option2'],
                                                    style: TextStyle(
                                                      color: _choosedOption2 ==
                                                              true
                                                          ? Colors.black
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                                  SizedBox(width: 5),
                                                  Text(
                                                    getOptionPercentage(
                                                      _option2Count,
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.blueGrey,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                _post.question['option2'],
                                                style: TextStyle(
                                                  color: _choosedOption2 == true
                                                      ? Colors.black
                                                      : Colors.grey,
                                                ),
                                              ),
                                        onPressed: () {
                                          if (!_choosedOption2 == true &&
                                              !_choosedOption1 == true) {
                                            setState(() {
                                              _choosedOption2 = true;
                                              _option2Count++;
                                            });
                                            DatabaseService.chooseOption2(
                                              _post.id,
                                              _userId,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                          _buildBottomPostPart(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
      } else if (_post.type == 4) {
        return StreamBuilder(
            stream: _blockedUsers,
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox.shrink();
              }

              final List<String> blockedUsers =
                  snapshot.data.docs.map((e) => e.id).toList();
              if (blockedUsers.contains(_post.authorId)) {
                return Container();
              }
              return VisibilityDetector(
                key: Key(_post.id),
                onVisibilityChanged: (VisibilityInfo info) {
                  double _visibilePercentage = info.visibleFraction * 100;
                  Timer(
                    Duration(milliseconds: 2300),
                    () {
                      if (!_post.viewedPeople.contains(_userId)) {
                        if (_visibilePercentage == 100) {
                          DatabaseService.addView(
                            'posts',
                            _post.id,
                            _userId,
                          );
                        }
                      }
                    },
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _post.isShared == true
                              ? _buildShareLabel()
                              : SizedBox.shrink(),
                          _buildTopPostWidget(blockedUsers),
                          _buildLocationWidget(),
                          _post.gif['caption'] == ''
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.only(
                                      bottom: 10, left: 26, top: 5),
                                  child: Text(
                                    _post.gif['caption'],
                                    textAlign: TextAlign.end,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                          Padding(
                            padding: _post.gif['caption'] == ''
                                ? EdgeInsets.only(top: 10, left: 16)
                                : EdgeInsets.only(left: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: _post.gif['gif'],
                                progressIndicatorBuilder:
                                    (context, url, downloadProgress) => Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                      backgroundColor: Colors.grey,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.black),
                                      value: downloadProgress.progress),
                                ),
                                height: MediaQuery.of(context).size.height / 4,
                                fit: BoxFit.cover,
                                width: MediaQuery.of(context).size.width / 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          _buildBottomPostPart(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
      } else if (_post.type == 5) {
        return StreamBuilder(
            stream: _blockedUsers,
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox.shrink();
              }

              final List<String> blockedUsers =
                  snapshot.data.docs.map((e) => e.id).toList();
              if (blockedUsers.contains(_post.authorId)) {
                return Container();
              }
              return VisibilityDetector(
                key: Key(_post.id),
                onVisibilityChanged: (VisibilityInfo info) {
                  double _visibilePercentage = info.visibleFraction * 100;
                  Timer(
                    Duration(milliseconds: 2300),
                    () {
                      if (!_post.viewedPeople.contains(_userId)) {
                        if (_visibilePercentage == 100) {
                          DatabaseService.addView(
                            'posts',
                            _post.id,
                            _userId,
                          );
                        }
                      }
                    },
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: <Widget>[
                          _post.isShared == true
                              ? _buildShareLabel()
                              : SizedBox.shrink(),
                          _buildTopPostWidget(blockedUsers),
                          _buildLocationWidget(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _post.audioDescribtion.isEmpty
                                  ? Container()
                                  : Padding(
                                      padding:
                                          EdgeInsets.only(left: 20, bottom: 10),
                                      child: Text(
                                        _post.audioDescribtion,
                                        style: TextStyle(
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: 10,
                                  left: MediaQuery.of(context).size.width / 3,
                                ),
                                child: RotationTransition(
                                  turns: _animation,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    child: Card(
                                      elevation: 20,
                                      shape: CircleBorder(),
                                      child: _post.audioImage == ''
                                          ? Center(
                                              child: Icon(
                                                Icons.mic,
                                                color: Colors.black,
                                                size: 30,
                                              ),
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    _post.audioImage ?? '',
                                                progressIndicatorBuilder:
                                                    (context, url,
                                                            downloadProgress) =>
                                                        Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: CircularProgressIndicator(
                                                      backgroundColor:
                                                          Colors.grey,
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                              Colors.black),
                                                      value: downloadProgress
                                                          .progress),
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Container(
                                      height: 50,
                                      width: 50,
                                      child: OutlineButton(
                                        shape: CircleBorder(),
                                        borderSide:
                                            BorderSide(color: Colors.black),
                                        onPressed: () {
                                          _seekToSecond(
                                            _audioPosition.inSeconds < 10
                                                ? 0
                                                : _audioPosition.inSeconds -
                                                    100,
                                          );
                                        },
                                        child: Icon(MdiIcons.rewind10),
                                      ),
                                    ),
                                    Container(
                                      width: 60,
                                      height: 60,
                                      child: OutlineButton(
                                        shape: CircleBorder(),
                                        borderSide:
                                            BorderSide(color: Colors.black),
                                        onPressed: () {
                                          if (_isPlaying) {
                                            _animationController.stop();
                                            _pause();
                                          } else {
                                            _animationController.repeat();
                                            _play();
                                          }
                                        },
                                        child: Icon(_getButtonIcon()),
                                      ),
                                    ),
                                    Container(
                                      width: 50,
                                      height: 50,
                                      child: OutlineButton(
                                        shape: CircleBorder(),
                                        borderSide:
                                            BorderSide(color: Colors.black),
                                        onPressed: () {
                                          if (_audioPosition.inSeconds <
                                              _audioDuration.inSeconds) {
                                            _seekToSecond(
                                              _audioPosition.inSeconds >
                                                      _audioDuration.inSeconds -
                                                          10
                                                  ? _audioPosition.inSeconds +
                                                      (_audioDuration
                                                              .inSeconds -
                                                          _audioPosition
                                                              .inSeconds)
                                                  : _audioPosition.inSeconds +
                                                      10,
                                            );
                                          }
                                        },
                                        child: Icon(MdiIcons.fastForward10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          _buildBottomPostPart(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
      } else {
        return StreamBuilder(
            stream: _blockedUsers,
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox.shrink();
              }
              final List<String> blockedUsers =
                  snapshot.data.docs.map((e) => e.id).toList();
              if (blockedUsers.contains(_post.authorId)) {
                return Container();
              }
              return VisibilityDetector(
                key: Key(_post.id),
                onVisibilityChanged: (VisibilityInfo info) {
                  double _visibilePercentage = info.visibleFraction * 100;
                  Timer(
                    Duration(milliseconds: 2300),
                    () {
                      if (!_post.viewedPeople.contains(_userId)) {
                        if (_visibilePercentage == 100) {
                          DatabaseService.addView(
                            'posts',
                            _post.id,
                            _userId,
                          );
                        }
                      }
                    },
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _post.isShared == true
                              ? _buildShareLabel()
                              : SizedBox.shrink(),
                          _buildTopPostWidget(blockedUsers),
                          _buildLocationWidget(),
                          _post.type == 3 && _post.caption.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 10, left: 20),
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
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                    text: _post.caption,
                                  ),
                                )
                              : Container(),
                          _post.type == 1
                              ? Padding(
                                  padding: const EdgeInsets.all(20),
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
                                    text: _post.text,
                                    style: TextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                                )
                              : _buildPostMediaContent(
                                  _screenWidth, _screenHeight),
                          _post.mediaUrl.length == 1 ||
                                  _post.mediaUrl.length == 0
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.only(
                                    left:
                                        MediaQuery.of(context).size.width / 2.5,
                                  ),
                                  child: DotsIndicator(
                                    dotsCount: _post.mediaUrl.length == 1 ||
                                            _post.mediaUrl.length == 0
                                        ? 1
                                        : _post.mediaUrl.length,
                                    position: _mediaIndex.toDouble(),
                                  ),
                                ),
                          _post.type == 5
                              ? Column(
                                  children: <Widget>[
                                    Container(
                                      width: 100,
                                      height: 100,
                                      child: Card(
                                        elevation: 20,
                                        child: _post.audioImage == null
                                            ? Container()
                                            : ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                                child: CachedNetworkImage(
                                                  imageUrl:
                                                      _post.audioImage ?? '',
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(),
                          _buildBottomPostPart(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
      }
    } else {
      return SizedBox.shrink();
    }
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
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width / 1.8,
          margin: EdgeInsets.only(bottom: 15, left: 10, right: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
        ),
        Positioned.fill(
          child: Center(
            child: GestureDetector(
              child: FaIcon(
                FontAwesomeIcons.play,
                size: 30,
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

class ImagePreviewWidget extends StatelessWidget {
  final String imageUrl;

  const ImagePreviewWidget({Key key, this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                color: Colors.white,
                icon: Icon(Icons.arrow_back),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoQuestionThumbWidget extends StatefulWidget {
  final String videoUrl;

  VideoQuestionThumbWidget({this.videoUrl});

  @override
  State<StatefulWidget> createState() {
    return _VideoQuestionThumbWidgetState();
  }
}

class _VideoQuestionThumbWidgetState extends State<VideoQuestionThumbWidget> {
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
          width: MediaQuery.of(context).size.width / 3,
          height: MediaQuery.of(context).size.width / 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
        ),
        Positioned.fill(
          child: Center(
            child: GestureDetector(
              child: FaIcon(
                FontAwesomeIcons.play,
                size: 30,
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
        ),
      ],
    );
  }
}

class ReplyPage extends StatefulWidget {
  final String userId;
  final String objectId;
  final String commentId;
  final String comment;
  final String userName;
  final String userImage;
  ReplyPage(
      {Key key,
      this.userId,
      this.objectId,
      this.commentId,
      this.comment,
      this.userName,
      this.userImage})
      : super(key: key);

  @override
  _ReplyPageState createState() => _ReplyPageState();
}

class _ReplyPageState extends State<ReplyPage> {
  TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            widget.userName + ' Comment',
            style: TextStyle(color: Colors.black),
          ),
          iconTheme: IconThemeData.fallback(),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.objectId)
                    .collection('comments')
                    .doc(widget.commentId)
                    .collection('replies')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SpinKitWave(
                      color: Colors.black,
                      size: 27,
                    );
                  } else {
                    return ListView.builder(
                      itemBuilder: (context, int index) {
                        final Comment _comment = Comment.fromDoc(
                          snapshot.data.docs[index],
                        );
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[400],
                                backgroundImage: CachedNetworkImageProvider(
                                  _comment.authorImage,
                                ),
                              ),
                              SizedBox(width: 5),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _comment.author == widget.userName
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: <Widget>[
                                      SelectableLinkify(
                                        onOpen: (link) async {
                                          if (await canLaunch(link.url)) {
                                            await launch(link.url);
                                          } else {
                                            Fluttertoast.showToast(
                                              msg: 'can not launch this link',
                                            );
                                          }
                                        },
                                        text: _comment.content,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        _comment.timestamp,
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Row(
                                children: <Widget>[
                                  Bounce(
                                    onPressed: () {
                                      if (!_comment.likedPeople
                                          .contains(widget.userId)) {
                                        DatabaseService.likeReply(
                                          widget.objectId,
                                          'posts',
                                          widget.commentId,
                                          widget.userId,
                                          _comment.id,
                                        );
                                        PersonalityService.setTextInput(
                                          _comment.content,
                                        );
                                      } else {
                                        DatabaseService.unLikeReply(
                                          widget.objectId,
                                          'posts',
                                          widget.commentId,
                                          widget.userId,
                                          _comment.id,
                                        );
                                      }
                                    },
                                    duration: Duration(milliseconds: 100),
                                    child: Icon(
                                      Icons.favorite,
                                      size: 16,
                                      color: _comment.likedPeople
                                              .contains(widget.userId)
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Text(_comment.likes.toString()),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      itemCount: snapshot.data.docs.length,
                    );
                  }
                },
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: TextField(
                      controller: _textEditingController,
                      textInputAction: TextInputAction.none,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10.0),
                        border: InputBorder.none,
                        hintText: 'Replay to ${widget.userName}',
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final String _commentDate =
                        TimeOfDay.fromDateTime(DateTime.now()).format(context);
                    FocusScope.of(context).requestFocus(FocusNode());
                    final Comment _comment = Comment(
                      author: widget.userName,
                      authorImage: widget.userImage,
                      content: _textEditingController.text,
                      type: 0,
                      timestamp: _commentDate,
                    );
                    PersonalityService.setTextInput(
                      'I\'ll reply for this comment \"${widget.comment}\" by saying ${_comment.content}',
                    );
                    DatabaseService.replyToComment(
                      widget.objectId,
                      'posts',
                      widget.commentId,
                      _comment,
                    );
                    _textEditingController.clear();
                  },
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ],
        ));
  }
}
