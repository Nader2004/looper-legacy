import 'dart:io';

import 'package:flutter/material.dart';
import 'package:admob_flutter/admob_flutter.dart';

class MinimizedNativeAd extends StatefulWidget {
  MinimizedNativeAd({Key key}) : super(key: key);

  @override
  _MinimizedNativeAdState createState() => _MinimizedNativeAdState();
}

class _MinimizedNativeAdState extends State<MinimizedNativeAd> {
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
