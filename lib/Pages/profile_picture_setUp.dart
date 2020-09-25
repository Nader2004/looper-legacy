import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

class ProfilePictureSetup extends StatefulWidget {
  const ProfilePictureSetup({
    Key key,
  }) : super(key: key);

  @override
  _ProfilePictureSetupState createState() => _ProfilePictureSetupState();
}

class _ProfilePictureSetupState extends State<ProfilePictureSetup> {
  PickedFile _image;

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

  void editPhoto() async {
    getDialog();
  }

  void openCamera() async {
    final ImagePicker _picker = ImagePicker();
    PickedFile _pickedImage = await _picker.getImage(
      source: ImageSource.camera,
    );

    setState(() {
      _image = _pickedImage;
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
  }

  void done() {
    Navigator.pop(context, File(_image.path));
  }

  Widget _buildUserImage() {
    return Container(
      margin: EdgeInsets.only(left: 40, top: 80, bottom: 40),
      child: Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          _image == null
              ? Container()
              : CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: FileImage(
                    File(_image.path),
                  ),
                  radius: 75,
                ),
          Positioned(
            top: _image == null ? 100 : 122,
            left: _image == null ? 37 : 45,
            child: ButtonTheme(
              height: _image != null ? 40 : 45,
              minWidth: _image != null ? 40 : 45,
              child: RaisedButton(
                color: Colors.white,
                shape: CircleBorder(),
                onPressed: _image != null ? editPhoto : openCamera,
                child: Icon(
                  _image != null ? Icons.edit : Icons.add_a_photo,
                  size: _image != null ? 22 : 24.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstText() {
    return Container(
      margin: EdgeInsets.only(left: 30, bottom: 20),
      child: Text(
        'Add your Profile Picture',
        style: TextStyle(fontSize: 16, color: Colors.black),
      ),
    );
  }

  Widget _buildCameraButton() {
    return Container(
      width: 300,
      height: 42,
      margin: EdgeInsets.only(left: 10, bottom: 20),
      child: RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        color: Colors.blue,
        textColor: Colors.white,
        onPressed: _image == null ? openCamera : done,
        child: _image != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Finish up',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Take Photo',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGalleryButton() {
    return Container(
      width: 300,
      height: 42,
      margin: EdgeInsets.only(left: 10, bottom: 20),
      child: RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        color: Colors.blue,
        onPressed: _image != null ? editPhoto : openGallery,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              _image != null ? Icons.edit : Icons.photo_library,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              _image != null ? 'Edit Photo' : 'Get from Gallery',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      title: Text(
        'Add your Profile image',
        style: TextStyle(color: Colors.black),
      ),
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(
          Icons.arrow_back_ios,
          size: 18,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null ? Container() : _buildUserImage(),
            _buildFirstText(),
            _buildCameraButton(),
            _buildGalleryButton(),
          ],
        ),
      ),
    );
  }
}
