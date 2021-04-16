import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';

class SportNativeAd extends StatefulWidget {
  SportNativeAd({Key key}) : super(key: key);

  @override
  _SportNativeAdState createState() => _SportNativeAdState();
}

class _SportNativeAdState extends State<SportNativeAd> {
  static const String AndroidAdUnitId =
      'ca-app-pub-9448985372006294/2961269368';
  static const String IOSAdUnitId = 'ca-app-pub-9448985372006294/6816753892';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AdmobBanner(
          adUnitId: Platform.isIOS ? IOSAdUnitId : AndroidAdUnitId,
          adSize: AdmobBannerSize.BANNER,
        ),
      ),
    );
  }
}
