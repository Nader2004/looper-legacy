/*import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';*/

import 'package:firebase_core/firebase_core.dart';

/// Copyright 2020
/// Developer : Nader Khaled
/// App Name : Looper
/// App Category : Social Network
/// Company Owner : Looper INC
/// Development Time : 2019 >> 2020
/// Author: Nader Khaled
/// IBM Cloud Account Password : *UyAdgQ$KY82&w#
/// Giphy API Key : UhvOlgZPcbRwN490PThaYgBlNy7N5rIx
/// Google Maps API Key : AIzaSyAk6x-mEiibVC7NamZ0owHRzQthVDhXRuA

import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import './Pages/welcome_page.dart';
import './Pages/home.dart';

import './Pages/splash_screen.dart';
import './Pages/errorPage.dart';
import './Pages/personal_data.dart';
import './Pages/sign_up.dart';
import './Pages/log_in.dart';
import './creation/post-create.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp();
  runApp(Looper());
}

class Looper extends StatelessWidget {
  const Looper({Key key}) : super(key: key);

  Widget _screenId() {
    return StreamBuilder<User>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          }
          return HomePage();
        } else {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          }
          return WelcomePage();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (BuildContext context) => _screenId(),
        HomePage.id: (BuildContext context) => HomePage(),
        PersonalPage.id: (BuildContext context) => PersonalPage(),
        SignUpPage.id: (BuildContext context) => SignUpPage(),
        LogInPage.id: (BuildContext context) => LogInPage(),
        WelcomePage.id: (BuildContext context) => WelcomePage(),
        PostCreationPage.pageId: (BuildContext context) => PostCreationPage(),
      },
      onUnknownRoute: (RouteSettings settings) =>
          MaterialPageRoute(builder: (context) {
        return ErrorPage();
      }),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_compress/flutter_video_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'models/user_data_model.dart';

enum MessageType {
  text,
  animatedEmoji,
  image,
  video,
  voice,
  sticker,
  meme,
  gif,
  comic,
  polls,
}

void main() => runApp(MainApp());

class MainApp extends StatelessWidget {
  const MainApp({Key key}) : super(key: key);

  Widget _screenId() {
    return StreamBuilder<FirebaseUser>(
      stream: FirebaseAuth.instance.onAuthStateChanged,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return MainPage();
        } else {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return StartPage();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      builder: (context) => UserData(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (BuildContext context) => _screenId(),
          RegistrationPage.id: (BuildContext context) => RegistrationPage(),
          LogInPage.id: (BuildContext context) => LogInPage(),
          MainPage.id: (BuildContext context) => MainPage(),
        },
      ),
    );
  }
}

class StartPage extends StatefulWidget {
  static const String id = 'Start';
  StartPage({Key key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CustomButton(
              text: 'Log in',
              callBack: () {
                Navigator.of(context).pushNamed(LogInPage.id);
              },
            ),
            SizedBox(height: 10),
            CustomButton(
              text: 'Sign up',
              callBack: () {
                Navigator.of(context).pushNamed(RegistrationPage.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final VoidCallback callBack;
  final String text;

  const CustomButton({Key key, this.callBack, this.text}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6.0,
      borderRadius: BorderRadius.circular(30.0),
      color: Colors.blue,
      child: MaterialButton(
        minWidth: 200,
        height: 45,
        onPressed: callBack,
        child: Text(text),
      ),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  static const String id = 'SignUp';
  RegistrationPage({Key key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  String name;
  String email;
  String password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData.fallback(),
        title: Text(
          'Register',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            TextField(
              onChanged: (String value) => email = value,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter email please',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              obscureText: true,
              onChanged: (String value) => password = value,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter password please',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              obscureText: true,
              onChanged: (String value) => name = value,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter name please',
              ),
            ),
            SizedBox(height: 5),
            CustomButton(
              text: 'Register',
              callBack: () async {
                await AuthService.registerUser(context, email, password, name);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LogInPage extends StatefulWidget {
  static const String id = 'LogIn';
  LogInPage({Key key}) : super(key: key);

  @override
  _LogInPageState createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  String email;
  String password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData.fallback(),
        title: Text(
          'Log in',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            TextField(
              onChanged: (String value) => email = value,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter email please',
              ),
            ),
            SizedBox(height: 10),
            TextField(
              obscureText: true,
              onChanged: (String value) => password = value,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter password please',
              ),
            ),
            SizedBox(height: 5),
            CustomButton(
              text: 'Log in',
              callBack: () async {
                await AuthService.logInUser(context, email, password);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  static const String id = 'MainPage';
  MainPage({Key key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static Firestore _firestore = Firestore.instance;
  static int _index = 0;
  static String _id = '';
  
  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  void _initPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    _id = _prefs.get('id');
  }

 

  Widget _buildBody() {
    if (_index == 0) {
      return StreamBuilder(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(
              child: CircularProgressIndicator(),
            );
          return ListView.builder(
            itemCount: snapshot.data.documents.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(snapshot.data.documents[index].data['name']),
                trailing: FlatButton(
                  color: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onPressed: () {
                    DatabaseService.addFollower(index);
                    Fluttertoast.showToast(msg: 'Following now');
                  },
                  child: Text('Follow'),
                ),
              );
            },
          );
        },
      );
    }
    return StreamBuilder(
      stream: _firestore
          .collection('users')
          .document(_id)
          .collection('following')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshots) {
       
        return ListView.builder(
          itemCount: snapshots.data.documents.length,
          itemBuilder: (context, index) {
            return 
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prototype'),
        iconTheme: IconThemeData.fallback(),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.do_not_disturb),
            onPressed: () async {
              await AuthService.logOut(context);
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: _index,
        onTap: (int index) {
          setState(() {
            _index = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            title: Text('People'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text('Followers'),
          ),
        ],
      ),
    );
  }
}

// Sending Messages done  100%
// Getting Messages done  100%
// Sending Emojis   done  50%  left:custom emojis
// Sending Images   done  100%
// Sending Videos   done  100%
// Sending AnEmojis done  0%
// Sending Location done  0%
// Sending Voicemes done  0%
// Sending Polls    done  0%
// Sending Gifs     done  0%
// Sending Stickers done  0%
// Sending commics  done  0%
// Sending memes    done  0%

class ChatPage extends StatefulWidget {
  final String id;
  final String followerId;
  final String groupId;
  const ChatPage({this.id, this.followerId, this.groupId});
  @override
  State<StatefulWidget> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final Firestore _db = Firestore.instance;
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _followerName = '';

  @override
  void initState() {
    super.initState();
    _initDataBase();
   
  }

  void _initDataBase() async {
    final DocumentSnapshot _snapshot =
        await _db.collection('users').document(widget.followerId).get();
    final String _name = _snapshot?.data['name'];
    setState(() {
      _followerName = _name;
    });
    await _db.collection('chat').document(widget.groupId).setData({});
  }

  

  

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_followerName),
      ),
      body: Column(
        children: <Widget>[
          
          
        ],
      ),
    );
  }
}

class AuthService {
  static void _showErrorDialog(
      BuildContext context, String title, String content,
      {bool addButton = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Center(child: Text(title)),
          content: Container(
            height: 30,
            child: Text(
              content,
              textAlign: TextAlign.center,
            ),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Okay'),
            ),
            addButton == true
                ? FlatButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, LogInPage.id);
                    },
                    child: Text('login'),
                  )
                : Container(),
          ],
        );
      },
    );
  }

  static Future<void> registerUser(
    BuildContext context,
    String email,
    String password,
    String name,
  ) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final Firestore _firestore = Firestore.instance;
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    try {
      final AuthResult _result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final FirebaseUser _user = _result.user;
      UserData currentUserId = Provider.of<UserData>(context, listen: false);
      currentUserId.currentUserId = _user.uid;
      _prefs.setString('id', _user.uid);
      _firestore.collection('users').document(_user.uid).setData(
        {
          'name': name,
        },
      );
      Fluttertoast.showToast(msg: 'You are registered');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(),
        ),
      );
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'ERROR_INVALID_EMAIL':
          _showErrorDialog(
            context,
            'incorrect Email',
            'Please check your Email! Maybe you wrote it wrong.',
          );
          break;
        case 'ERROR_EMAIL_ALREADY_IN_USE':
          _showErrorDialog(
            context,
            'Email already exist',
            'This Email exists already. You can login instead',
            addButton: true,
          );
          break;
        case 'ERROR_WEAK_PASSWORD':
          _showErrorDialog(
            context,
            'The Password is weak',
            'Please write a stronger Password. Try to use numbers or symbols.',
          );
          break;
        case 'ERROR_NETWORK_ERROR':
          _showErrorDialog(
            context,
            'poor Connection',
            'Please check your Internet Connection',
          );
          break;
        default:
          _showErrorDialog(
            context,
            'Something went wrong',
            'Could not sign up',
          );
      }
    }
  }

  static Future<void> logInUser(
      BuildContext context, String email, String password) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    try {
      final AuthResult _result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final FirebaseUser _user = _result.user;
      _prefs.remove('id');
      _prefs.setString('id', _user.uid);
      Fluttertoast.showToast(msg: 'You are logged in');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(),
        ),
      );
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'ERROR_INVALID_EMAIL':
          _showErrorDialog(
            context,
            'incorrect Email',
            'Please check your Email! Maybe you wrote it wrong.',
          );
          break;
        case 'ERROR_USER_NOT_FOUND':
          _showErrorDialog(
            context,
            'Account not found',
            'The Email and Password you\'ve written were not found',
          );
          break;
        case 'ERROR_WRONG_PASSWORD':
          _showErrorDialog(
            context,
            'invalid Password',
            'Please enter a correct Password',
          );
          break;
        case 'ERROR_NETWORK_ERROR':
          _showErrorDialog(
            context,
            'Poor Connection',
            'Please check your Internet Connection',
          );
          break;
        default:
          _showErrorDialog(
            context,
            'Something went wrong',
            'Could not sign in',
          );
      }
    }
  }

  static Future<void> logOut(BuildContext context) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      await _auth.signOut();
      Fluttertoast.showToast(msg: 'You are logged out');
      Navigator.popUntil(context, (route) => route.isFirst);
    } on PlatformException catch (e) {
      if (e.code == 'ERROR_NETWORK_ERROR') {
        _showErrorDialog(
          context,
          'Poor Connection',
          'Please check your Internet Connection',
        );
      }
    }
  }
}

class DatabaseService {
  static final Firestore _db = Firestore.instance;

  static void addFollower(int index) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final String _id = _prefs.get('id');
    final QuerySnapshot _snapshots =
        await _db.collection('users').getDocuments();
    final DocumentSnapshot _docSnap =
        await _db.collection('users').document(_id).get();
    final String _userId = _snapshots.documents[index].documentID;
    final String _userName = _snapshots.documents[index].data['name'];
    final String _idName = _docSnap.data['name'];

    final DocumentReference _docFollowingRef = _db
        .collection('users')
        .document(_id)
        .collection('following')
        .document(_userId);
    final DocumentReference _docFollowersRef = _db
        .collection('users')
        .document(_userId)
        .collection('followers')
        .document(_id);
    Firestore.instance.runTransaction(
      (Transaction transaction) async {
        await transaction.set(_docFollowingRef, {
          'id': _userId,
          'name': _userName,
        });
        await transaction.set(_docFollowersRef, {
          'id': _id,
          'name': _idName,
        });
      },
    );
  }

  static void sendMessage(String groupId, Message message) {
    final String _timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    final DocumentReference _documentReference = _db
        .collection('chat')
        .document(groupId)
        .collection('messages')
        .document(_timeStamp);
    _db.runTransaction(
      (Transaction tx) async {
        await tx.set(
          _documentReference,
          {
            'id': _timeStamp,
            'from': message.author,
            'to': message.peerId,
            'content': message.content,
            'type': message.type,
            'timestamp': message.timestamp,
          },
        );
      },
    );
  }
}

class Message {
  final String id;
  final String author;
  final String peerId;
  final String content;
  final int type;
  final String timestamp;
  const Message({
    this.id,
    this.author,
    this.peerId,
    this.content,
    this.type,
    this.timestamp,
  });
  factory Message.fromDoc(DocumentSnapshot doc) {
    return Message(
      id: doc['id'],
      author: doc['from'],
      peerId: doc['to'],
      content: doc['content'],
      type: doc['type'],
      timestamp: doc['timestamp'],
    );
  }
}

class StorageService {
  static Future<File> compressImage(String photoId, File image) async {
    final Directory _temp = await getTemporaryDirectory();
    final String _path = _temp.path;
    final File _compressedImage = await FlutterImageCompress.compressAndGetFile(
      image.absolute.path,
      '$_path/img_$photoId.jpg',
    );
    return _compressedImage;
  }

  static Future<File> compressVideo(File video) async {
    final FlutterVideoCompress _videoCompress = FlutterVideoCompress();
    final MediaInfo _compressedVideo = await _videoCompress.compressVideo(
      video.path,
      includeAudio: true,
    );
    return _compressedVideo.file;
  }

  static Future uploadFile(
    String groupId,
    File file,
    int type,
  ) async {
    final StorageReference _storageRef = FirebaseStorage.instance.ref();
    String _fileId = Uuid().v4();
    final File _file = type == 2
        ? await compressVideo(file)
        : await compressImage(_fileId, file);
    final StorageUploadTask _uploadTask =
        _storageRef.child('chat/$groupId/$_fileId').putFile(_file);
    final StorageTaskSnapshot _storageSnap = await _uploadTask.onComplete;
    final String _downloadUrl = await _storageSnap.ref.getDownloadURL();
    return _downloadUrl;
  }
}
*/
