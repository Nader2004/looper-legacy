import 'package:flutter/material.dart';
import 'package:native_ads/native_ad_param.dart';
import 'package:native_ads/native_ad_view.dart';

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
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      child: NativeAdView(
        androidParam: AndroidParam()
          ..placementId = 'ca-app-pub-3940256099942544/2247696110'
          ..packageName = 'com.app.looper'
          ..layoutName = 'native_ad'
          ..attributionText = 'SPONSORED',
        iosParam: IOSParam()
          ..placementId = 'ca-app-pub-3940256099942544/3986624511'
          ..bundleId = 'com.app.looper'
          ..layoutName = 'UnifiedNativeAdView'
          ..attributionText = 'SPONSORED',
      ),
    );
  }
}
