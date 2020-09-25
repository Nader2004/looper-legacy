import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_native_admob/flutter_native_admob.dart';
import 'package:flutter_native_admob/native_admob_options.dart';
import 'package:flutter_native_admob/native_admob_controller.dart';

class SportNativeAd extends StatefulWidget {
  SportNativeAd({Key key}) : super(key: key);

  @override
  _SportNativeAdState createState() => _SportNativeAdState();
}

class _SportNativeAdState extends State<SportNativeAd> {
  static const String AndroidAdUnitId =
      'ca-app-pub-9448985372006294/2961269368';
  static const String IOSAdUnitId = 'ca-app-pub-9448985372006294/6816753892';
  final _nativeAdController = NativeAdmobController();
  double _height;

  @override
  void initState() {
    _nativeAdController.stateChanged.listen(_onStateChanged);
    super.initState();
  }

  void _onStateChanged(AdLoadState state) {
    switch (state) {
      case AdLoadState.loading:
        setState(() {
          _height = 0;
        });
        break;

      case AdLoadState.loadCompleted:
        setState(() {
          _height = MediaQuery.of(context).size.height / 1.8;
        });
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: NativeAdmob(
            adUnitID: Platform.isAndroid ? AndroidAdUnitId : IOSAdUnitId,
            controller: _nativeAdController,
            loading: Container(),
            options: NativeAdmobOptions(
              adLabelTextStyle: NativeTextStyle(
                backgroundColor: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
