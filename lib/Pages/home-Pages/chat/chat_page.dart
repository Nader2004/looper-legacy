import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounce/flutter_bounce.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_5.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
import 'package:looper/models/messageModel.dart';
import 'package:looper/models/userModel.dart';
import 'package:looper/services/database.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/services/personality.dart';
import 'package:looper/services/storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:video_player/video_player.dart';

enum PlayerState { stopped, playing, paused }

class ChatPage extends StatefulWidget {
  final String id;
  final String followerId;
  final String followerName;
  final String groupId;
  final bool isGlobal;
  ChatPage({
    Key key,
    this.id,
    this.followerId,
    this.followerName,
    this.groupId,
    this.isGlobal,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String _audioUrl = '';
  Stream<DocumentSnapshot> _blockCheckerStream;
  TextEditingController _textEditingController;
  TextEditingController _editController;
  ScrollController _scrollController;
  FlutterSoundRecorder _recorder;
  List<QueryDocumentSnapshot> _retrievedSnapshots =
      List<QueryDocumentSnapshot>();
  List<QueryDocumentSnapshot> _messagesSnapshots =
      List<QueryDocumentSnapshot>();
  StopWatchTimer _stopWatchTimer;

  @override
  void initState() {
    super.initState();
    _blockCheckerStream = FirebaseFirestore.instance
        .collection('global-chat')
        .doc(widget.groupId)
        .snapshots();
    _recorder = FlutterSoundRecorder();
    _textEditingController = TextEditingController();
    _editController = TextEditingController();
    _scrollController = ScrollController();
    _stopWatchTimer = StopWatchTimer();
    setDatabaseData();
    _scrollController.addListener(_scrollListener);
    initRecorder();
    print(widget.groupId);
  }

  void setDatabaseData() async {
    if (widget.isGlobal != true) {
      await FirebaseFirestore.instance
          .collection('chat')
          .doc(widget.groupId)
          .set({});
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300), curve: Curves.elasticOut);
    } else {
      Timer(Duration(milliseconds: 400), () => _scrollToBottom());
    }
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
    if (await Permission.microphone.request().isGranted) {
      try {
        final filePath = await getFilePath();
        await _recorder.startRecorder(
          toFile: filePath,
          numChannels: 1,
          sampleRate: 8000,
        );
        _stopWatchTimer.onExecute.add(StopWatchExecute.start);
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to record');
      }
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
    _stopWatchTimer.onExecute.add(StopWatchExecute.reset);
    final _filePath = await getFilePath();
    _audioUrl = _filePath;
    final String _messageDate = DateTime.now().toUtc().toString();
    List<String> _result = await StorageService.uploadMediaFile(
      [File(_audioUrl)],
      'chat/audio',
    );
    DatabaseService.sendMessage(
      widget.groupId,
      Message(
        author: widget.id,
        peerId: widget.followerId,
        content: _result.first,
        timestamp: _messageDate,
        type: 3,
      ),
      widget.isGlobal,
    );
    PersonalityService.setAudioInput(_audioUrl);
  }

  void _scrollListener() async {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      QuerySnapshot _newMessages = await FirebaseFirestore.instance
          .collection(
            widget.isGlobal == true ? 'global-chat' : 'chat',
          )
          .doc(widget.groupId)
          .collection('messages')
          .orderBy('timestamp')
          .startAfterDocument(
            _retrievedSnapshots[_retrievedSnapshots.length - 1],
          )
          .limit(20)
          .get();
      if (_newMessages.docs.isNotEmpty) {
        setState(() {
          _messagesSnapshots.addAll(_newMessages.docs);
        });
      }
    }
  }

  void _sendVideo(ImageSource source) {
    final String _messageDate = DateTime.now().toUtc().toString();
    final ImagePicker _picker = ImagePicker();
    _picker
        .getVideo(
      source: source,
    )
        .then(
      (PickedFile video) async {
        if (video != null) {
          PersonalityService.setVideoInput(video.path);
          final List<String> _contentUrl = await StorageService.uploadMediaFile(
            [File(video.path)],
            'chat/video',
          );
          DatabaseService.sendMessage(
            widget.groupId,
            Message(
              author: widget.id,
              peerId: widget.followerId,
              content: _contentUrl.first,
              timestamp: _messageDate,
              type: 2,
            ),
            widget.isGlobal,
          );
          NotificationsService.sendNotification('New Message',
              '${widget.followerName} sent a video', widget.followerId, 'chat');
        }
      },
    );
  }

  void _sendImage(ImageSource source) {
    final String _messageDate = DateTime.now().toUtc().toString();
    final ImagePicker _picker = ImagePicker();
    _picker
        .getImage(
      source: source,
    )
        .then(
      (PickedFile image) async {
        if (image != null) {
          print('process on');
          PersonalityService.setImageInput(image.path);
          final List<String> _contentUrl = await StorageService.uploadMediaFile(
            [File(image.path)],
            'chat/image',
          );
          print(_messageDate);
          DatabaseService.sendMessage(
            widget.groupId,
            Message(
              author: widget.id,
              peerId: widget.followerId,
              content: _contentUrl.first,
              timestamp: _messageDate,
              type: 1,
            ),
            widget.isGlobal,
          );
          NotificationsService.sendNotification(
              'New Message',
              '${widget.followerName} sent an image',
              widget.followerId,
              'chat');
        }
      },
    );
  }

  void _showDialog(String mediaType) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        children: [
          ListTile(
            title: Text('Choose from gallery'),
            leading: Icon(Icons.photo_library),
            onTap: () {
              if (mediaType == 'Image') {
                Navigator.pop(context);
                _sendImage(ImageSource.gallery);
              } else {
                Navigator.pop(context);
                _sendVideo(ImageSource.gallery);
              }
            },
          ),
          ListTile(
            title: Text('Capture from camera'),
            leading: Icon(Icons.camera_alt),
            onTap: () {
              if (mediaType == 'Image') {
                Navigator.pop(context);
                _sendImage(ImageSource.camera);
              } else {
                Navigator.pop(context);
                _sendVideo(ImageSource.camera);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          content: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _editController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Your edit',
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
                child: Text('CANCEL'),
                onPressed: () {
                  _editController?.clear();
                  Navigator.pop(context);
                }),
            FlatButton(
                child: Text('DONE'),
                onPressed: () {
                  if (_editController.text.length != 0) {
                    Navigator.pop(context);
                    FirebaseFirestore.instance
                        .collection(
                          widget.isGlobal == true ? 'global-chat' : 'chat',
                        )
                        .doc(widget.groupId)
                        .collection('messages')
                        .doc(
                          _retrievedSnapshots[index].id,
                        )
                        .update({
                      'content': _editController.text,
                    });
                  } else {
                    Fluttertoast.showToast(msg: 'Add your edit first');
                  }
                })
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    releaseFlauto();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _textEditingController.dispose();
    _stopWatchTimer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData.fallback(),
        automaticallyImplyLeading: false,
        title: FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.followerId)
                .get(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container();
              } else {
                final User _user = User.fromDoc(snapshot.data);
                return Row(
                  children: [
                    Bounce(
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                      ),
                      duration: Duration(milliseconds: 100),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    SizedBox(width: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                userId: _user.id,
                              ),
                            ),
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl: _user.profileImageUrl,
                          height: 45,
                          width: 45,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      _user.username,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }
            }),
        actions: [
          widget.isGlobal == false
              ? SizedBox.shrink()
              : StreamBuilder(
                  stream: _blockCheckerStream,
                  builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox.shrink();
                    }
                    final DocumentSnapshot _snapshot = snapshot.data;
                    return FlatButton(
                      child: Text(_snapshot.data()['isBlocked'] == true &&
                              _snapshot.data()['blocker'] == widget.id
                          ? 'Unblock'
                          : 'Block'),
                      textColor: _snapshot.data()['isBlocked'] == true &&
                              _snapshot.data()['blocker'] == widget.id
                          ? Colors.blue
                          : Colors.red,
                      onPressed: () {
                        if (_snapshot.data()['isBlocked'] == true &&
                            _snapshot.data()['blocker'] == widget.id) {
                          DatabaseService.unBlockUserChat(widget.groupId);
                        } else {
                          print('clicked');
                          print(widget.groupId);
                          DatabaseService.blockUserChat(
                            widget.groupId,
                            widget.id,
                          );
                        }
                      },
                    );
                  }),
        ],
      ),
      body: Column(
        children: [
          Flexible(
            child: Container(
              height: MediaQuery.of(context).size.height / 1.1,
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection(
                      widget.isGlobal == true ? 'global-chat' : 'chat',
                    )
                    .doc(widget.groupId)
                    .collection('messages')
                    .orderBy('timestamp')
                    .limit(25)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  print(widget.groupId);
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());
                  _retrievedSnapshots = snapshot.data.docs;
                  _retrievedSnapshots.addAll(
                    _messagesSnapshots.length == 0 ? [] : _messagesSnapshots,
                  );
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: _retrievedSnapshots.length,
                    itemBuilder: (context, index) {
                      final QueryDocumentSnapshot _snapshot =
                          _retrievedSnapshots[index];
                      final Message _receivedMessage = Message.fromDoc(
                        _snapshot,
                      );
                      return Row(
                        mainAxisAlignment: _receivedMessage.author == widget.id
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _receivedMessage.author == widget.id
                                    ? GestureDetector(
                                        onTap: () {
                                          FirebaseFirestore.instance
                                              .collection(
                                                widget.isGlobal == true
                                                    ? 'global-chat'
                                                    : 'chat',
                                              )
                                              .doc(widget.groupId)
                                              .collection('messages')
                                              .doc(
                                                _retrievedSnapshots[index].id,
                                              )
                                              .delete();
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey[200],
                                          ),
                                          child: Icon(
                                            Icons.delete,
                                            color: Colors.grey[700],
                                            size: 14,
                                          ),
                                        ),
                                      )
                                    : Container(),
                                _receivedMessage.author == widget.id &&
                                        _receivedMessage.type == 0
                                    ? SizedBox(width: 10)
                                    : SizedBox.shrink(),
                                _receivedMessage.author == widget.id &&
                                        _receivedMessage.type == 0
                                    ? GestureDetector(
                                        onTap: () {
                                          _showEditDialog(index);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey[200],
                                          ),
                                          child: Icon(
                                            Icons.edit,
                                            color: Colors.grey[700],
                                            size: 14,
                                          ),
                                        ),
                                      )
                                    : Container(),
                                SizedBox(width: 10),
                                ChatBubble(
                                  backGroundColor:
                                      _receivedMessage.author == widget.id
                                          ? Colors.black
                                          : Colors.white,
                                  clipper: ChatBubbleClipper5(
                                    type: _receivedMessage.author == widget.id
                                        ? BubbleType.sendBubble
                                        : BubbleType.receiverBubble,
                                  ),
                                  child: Container(
                                    constraints: BoxConstraints(
                                      minWidth:
                                          MediaQuery.of(context).size.width /
                                              10,
                                      maxWidth:
                                          MediaQuery.of(context).size.width /
                                              2.5,
                                    ),
                                    child: _receivedMessage.type == 2
                                        ? Stack(
                                            children: [
                                              VideoWidget(
                                                videoUrl:
                                                    _receivedMessage.content,
                                              ),
                                              Positioned.fill(
                                                child: Align(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      DatabaseService
                                                          .getMessageTiming(
                                                        _receivedMessage
                                                            .timestamp,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : _receivedMessage.type == 1
                                            ? Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                    child: CachedNetworkImage(
                                                      imageUrl: _receivedMessage
                                                          .content,
                                                      fit: BoxFit.cover,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              1.8,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              1.8,
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
                                                    ),
                                                  ),
                                                  Positioned.fill(
                                                    child: Align(
                                                      alignment:
                                                          Alignment.bottomRight,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text(
                                                          DatabaseService
                                                              .getMessageTiming(
                                                            _receivedMessage
                                                                .timestamp,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : _receivedMessage.type == 0
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        _receivedMessage
                                                            .content,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: _receivedMessage
                                                                      .author ==
                                                                  widget.id
                                                              ? Colors.white
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                      SizedBox(height: 6),
                                                      Text(
                                                        DatabaseService
                                                            .getMessageTiming(
                                                          _receivedMessage
                                                              .timestamp,
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : AudioPlayerWidget(
                                                    audioUrl: _receivedMessage
                                                        .content,
                                                    timestamp: DatabaseService
                                                        .getMessageTiming(
                                                      _receivedMessage
                                                          .timestamp,
                                                    ),
                                                  ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          widget.isGlobal == true
              ? StreamBuilder(
                  stream: _blockCheckerStream,
                  builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox.shrink();
                    }
                    print(_blockCheckerStream == null);
                    final DocumentSnapshot _snapshot = snapshot.data;
                    if (_snapshot.data() == null) {
                      return SizedBox.shrink();
                    }
                    return _snapshot.data()['isBlocked'] == true
                        ? Container(
                            alignment: Alignment.center,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height / 11,
                            color: Colors.grey[350],
                            child: Text(
                              _snapshot.data()['blocker'] == widget.id
                                  ? 'You have blocked this chat'
                                  : 'You are blocked',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Row(
                            children: <Widget>[
                              Container(
                                color: Colors.white,
                                child: IconButton(
                                  icon: Icon(Icons.mic),
                                  onPressed: () {
                                    _startRecording();
                                    Flushbar(
                                      titleText: StreamBuilder(
                                          stream: _stopWatchTimer.secondTime,
                                          builder: (context,
                                              AsyncSnapshot<int> snapshot) {
                                            return Text(
                                              snapshot.data == 0
                                                  ? '00.00'
                                                  : snapshot.data.toString(),
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 24,
                                              ),
                                            );
                                          }),
                                      message: 'Recording',
                                      mainButton: FlatButton(
                                        onPressed: () {
                                          _stopRecording();
                                          Navigator.pop(context);
                                        },
                                        textColor: Colors.red,
                                        child: Text('Stop'),
                                      ),
                                    )..show(context);
                                  },
                                ),
                              ),
                              Container(
                                color: Colors.white,
                                child: IconButton(
                                  icon: Icon(Icons.videocam),
                                  onPressed: () => _showDialog('Video'),
                                ),
                              ),
                              Container(
                                color: Colors.white,
                                child: IconButton(
                                  icon: Icon(Icons.image),
                                  onPressed: () => _showDialog('Image'),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: 300.0,
                                    ),
                                    child: TextField(
                                      onTap: () {
                                        _scrollController.jumpTo(
                                          _scrollController
                                              .position.maxScrollExtent,
                                        );
                                      },
                                      maxLines: null,
                                      textInputAction: TextInputAction.none,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(10.0),
                                        border: InputBorder.none,
                                        hintText: 'Type a message',
                                      ),
                                      controller: _textEditingController,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                color: Colors.black,
                                child: IconButton(
                                  onPressed: () {
                                    final String _messageDate =
                                        DateTime.now().toUtc().toString();
                                    FocusScope.of(context)
                                        .requestFocus(FocusNode());
                                    DatabaseService.sendMessage(
                                      widget.groupId,
                                      Message(
                                        author: widget.id,
                                        peerId: widget.followerId,
                                        content: _textEditingController.text,
                                        type: 0,
                                        timestamp: _messageDate,
                                      ),
                                      widget.isGlobal,
                                    );
                                    PersonalityService.setTextInput(
                                        _textEditingController.text);
                                    NotificationsService.sendNotification(
                                        'New Message',
                                        '${widget.followerName} sent a message',
                                        widget.followerId,
                                        'chat');
                                    _textEditingController.clear();
                                  },
                                  icon: Icon(
                                    Icons.send,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                  })
              : Row(
                  children: <Widget>[
                    Container(
                      color: Colors.white,
                      child: IconButton(
                        icon: Icon(Icons.mic),
                        onPressed: () {
                          _startRecording();
                          Flushbar(
                            titleText: StreamBuilder(
                                stream: _stopWatchTimer.secondTime,
                                builder:
                                    (context, AsyncSnapshot<int> snapshot) {
                                  return Text(
                                    snapshot.data == 0
                                        ? '00.00'
                                        : snapshot.data.toString(),
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 24,
                                    ),
                                  );
                                }),
                            message: 'Recording',
                            mainButton: FlatButton(
                              onPressed: () {
                                _stopRecording();
                                Navigator.pop(context);
                              },
                              textColor: Colors.red,
                              child: Text('Stop'),
                            ),
                          )..show(context);
                        },
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      child: IconButton(
                        icon: Icon(Icons.videocam),
                        onPressed: () => _showDialog('Video'),
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      child: IconButton(
                        icon: Icon(Icons.image),
                        onPressed: () => _showDialog('Image'),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 300.0,
                          ),
                          child: TextField(
                            onTap: () {
                              _scrollController.jumpTo(
                                _scrollController.position.maxScrollExtent,
                              );
                            },
                            maxLines: null,
                            textInputAction: TextInputAction.none,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.all(10.0),
                              border: InputBorder.none,
                              hintText: 'Type a message',
                            ),
                            controller: _textEditingController,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.black,
                      child: IconButton(
                        onPressed: () {
                          final String _messageDate =
                              DateTime.now().toUtc().toString();
                          FocusScope.of(context).requestFocus(FocusNode());
                          DatabaseService.sendMessage(
                            widget.groupId,
                            Message(
                              author: widget.id,
                              peerId: widget.followerId,
                              content: _textEditingController.text,
                              type: 0,
                              timestamp: _messageDate,
                            ),
                            widget.isGlobal,
                          );
                          PersonalityService.setTextInput(
                              _textEditingController.text);
                          NotificationsService.sendNotification(
                              'New Message',
                              '${widget.followerName} sent a message',
                              widget.followerId,
                              'chat');
                          _textEditingController.clear();
                        },
                        icon: Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
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
          width: MediaQuery.of(context).size.width / 1.8,
          height: MediaQuery.of(context).size.width / 1.8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
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

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String timestamp;
  AudioPlayerWidget({
    Key key,
    this.audioUrl,
    this.timestamp,
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
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 20,
                color: Colors.white,
                icon: Icon(_getButtonIcon()),
                onPressed: () {
                  if (_isPlaying) {
                    _pause();
                  } else {
                    _play();
                  }
                },
              ),
              Text(
                _audioPosition != null ? '${_positionText ?? ''}' : '',
                style: TextStyle(color: Colors.white, fontSize: 15.0),
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
                          _audioPosition.inSeconds < _audioDuration.inSeconds)
                      ? _audioDuration.inSeconds.toDouble()
                      : 1.0,
                  value: (_audioPosition != null &&
                          _audioDuration != null &&
                          _audioPosition.inSeconds > 0 &&
                          _audioPosition.inSeconds < _audioDuration.inSeconds)
                      ? _audioPosition.inSeconds.toDouble()
                      : 0.0,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.blue.withOpacity(0.3),
                ),
              ),
              Text(
                _audioDuration != null ? '${_durationText ?? ''}' : '',
                style: TextStyle(color: Colors.white, fontSize: 15.0),
              ),
            ],
          ),
          SizedBox(height: 3),
          Text(
            widget.timestamp,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
