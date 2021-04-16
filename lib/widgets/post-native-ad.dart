import 'dart:io';

import 'package:flutter/material.dart';
import 'package:admob_flutter/admob_flutter.dart';

class PostNativeAd extends StatefulWidget {
  PostNativeAd({Key key}) : super(key: key);

  @override
  _PostNativeAdState createState() => _PostNativeAdState();
}

class _PostNativeAdState extends State<PostNativeAd> {
  static const String AndroidAdUnitId =
      'ca-app-pub-3940256099942544/2247696110'; // 'ca-app-pub-9448985372006294/2961269368';
  static const String IOSAdUnitId =
      'ca-app-pub-3940256099942544/3986624511'; //'ca-app-pub-9448985372006294/6816753892';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              margin: EdgeInsets.only(bottom: 20.0),
              child: AdmobBanner(
                adUnitId: Platform.isIOS ? IOSAdUnitId : AndroidAdUnitId,
                adSize: AdmobBannerSize.BANNER,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
