import 'package:flutter/material.dart';
import 'package:native_ads/native_ad_param.dart';
import 'package:native_ads/native_ad_view.dart';

class SportNativeAd extends StatefulWidget {
  SportNativeAd({Key key}) : super(key: key);

  @override
  _SportNativeAdState createState() => _SportNativeAdState();
}

class _SportNativeAdState extends State<SportNativeAd>
    with AutomaticKeepAliveClientMixin {
  static const String AndroidAdUnitId =
      'ca-app-pub-9448985372006294/2961269368';
  static const String IOSAdUnitId = 'ca-app-pub-9448985372006294/6816753892';

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      height: MediaQuery.of(context).size.height / 1.8,
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
        ),
      ),
    );
  }
}
