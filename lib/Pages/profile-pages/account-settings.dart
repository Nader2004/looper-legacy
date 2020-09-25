import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:looper/models/userModel.dart';
import 'package:looper/services/auth.dart';
import 'package:looper/services/storage.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSettingsPage extends StatefulWidget {
  AccountSettingsPage({Key key}) : super(key: key);

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  String _id = 'empty';
  String userName = '';
  String email = '';
  PickedFile _image;
  Future<DocumentSnapshot> _future;
  GlobalKey<FormState> _usernameFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    setPrefs();
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();

    setState(() {
      _id = _prefs.get('id');
      _future = FirebaseFirestore.instance.collection('users').doc(_id).get();
    });
  }

  void getDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            height: 115,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                  ),
                  title: Text('Open Camera ..'),
                  onTap: () {
                    Navigator.pop(context);
                    openCamera();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: Colors.black,
                  ),
                  title: Text('Open Gallery ..'),
                  onTap: () {
                    Navigator.pop(context);
                    openGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void openCamera() async {
    final ImagePicker _picker = ImagePicker();
    PickedFile _pickedImage = await _picker.getImage(
      source: ImageSource.camera,
    );

    setState(() {
      _image = _pickedImage;
    });
    final List<String> _imageUrl = await StorageService.uploadMediaFile(
      [File(_image.path)],
      'profileImage',
    );
    FirebaseFirestore.instance.collection('users').doc(_id).update({
      'profilePictureUrl': _imageUrl.first,
    });
  }

  void openGallery() async {
    final ImagePicker _picker = ImagePicker();
    PickedFile _pickedImage = await _picker.getImage(
      source: ImageSource.gallery,
    );

    setState(() {
      _image = _pickedImage;
    });
    final List<String> _imageUrl = await StorageService.uploadMediaFile(
      [File(_image.path)],
      'profileImage',
    );
    FirebaseFirestore.instance.collection('users').doc(_id).update({
      'profilePictureUrl': _imageUrl.first,
    });
  }

  Widget _buildUsernameForm(String username) {
    return Form(
      key: _usernameFormKey,
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        width: 300,
        child: TextFormField(
          autocorrect: true,
          decoration: InputDecoration(
            labelText: username,
            border: OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.person,
              color: Colors.black,
            ),
          ),
          onChanged: (String value) {
            userName = value;
            if (userName != null) {
              _usernameFormKey.currentState.validate();
            }
          },
          validator: (String value) {
            if (value.isEmpty || value.length <= 1) {
              return 'invalid username';
            } else {
              return null;
            }
          },
          onEditingComplete: () {
            _usernameFormKey.currentState.validate();
            if (_usernameFormKey.currentState.validate()) {
              FocusScope.of(context).requestFocus(FocusNode());
            }
            FirebaseFirestore.instance.collection('users').doc(_id).update({
              'username': userName,
            });
          },
        ),
      ),
    );
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
          'Account settings',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: _id == 'empty'
          ? SizedBox.shrink()
          : FutureBuilder(
              future: _future,
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.2,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  );
                }
                final User _user = User.fromDoc(snapshot.data);
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 30,
                          ),
                          child: Stack(
                            overflow: Overflow.visible,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(250),
                                child: _image != null
                                    ? Image.file(
                                        File(_image.path),
                                        fit: BoxFit.cover,
                                        height:
                                            MediaQuery.of(context).size.height /
                                                3.5,
                                        width:
                                            MediaQuery.of(context).size.height /
                                                3.5,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: _user.profileImageUrl,
                                        fit: BoxFit.cover,
                                        height:
                                            MediaQuery.of(context).size.height /
                                                3.5,
                                        width:
                                            MediaQuery.of(context).size.height /
                                                3.5,
                                      ),
                              ),
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment(0.0, 1.25),
                                  child: ButtonTheme(
                                    height: 45,
                                    minWidth: 45,
                                    child: RaisedButton(
                                      color: Colors.white,
                                      shape: CircleBorder(),
                                      onPressed: () => getDialog(),
                                      child: Icon(Icons.edit, size: 22),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildUsernameForm(_user.username),
                        SizedBox(height: 10),
                        Container(
                          height: 35,
                          width: MediaQuery.of(context).size.width / 1.2,
                          child: FlatButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            onPressed: () => AuthService.logOut(context),
                            color: Colors.black,
                            textColor: Colors.white,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(MdiIcons.logout, color: Colors.white),
                                SizedBox(width: 5),
                                Text('Log out'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
    );
  }
}
