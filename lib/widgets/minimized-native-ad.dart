import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MinimizedNativeAd extends StatefulWidget {
  MinimizedNativeAd({Key key}) : super(key: key);

  @override
  _MinimizedNativeAdState createState() => _MinimizedNativeAdState();
}

class _MinimizedNativeAdState extends State<MinimizedNativeAd> {
  static const String AndroidAdUnitId =
      'ca-app-pub-9448985372006294/2961269368';
  static const String IOSAdUnitId = 'ca-app-pub-9448985372006294/6816753892';
  NativeAd nativeAd;

  @override
  void initState() {
    super.initState();
    nativeAd = NativeAd(
      adUnitId: Platform.isIOS ? IOSAdUnitId : AndroidAdUnitId,
      factoryId: 'native-ad',
      listener: AdListener(
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          nativeAd.dispose();
        },
      ),
      request: AdRequest(),
    );
    nativeAd.load();
  }

  @override
  void dispose() {
    nativeAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AdWidget adWidget = AdWidget(ad: nativeAd);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: adWidget,
      ),
    );
  }
}
