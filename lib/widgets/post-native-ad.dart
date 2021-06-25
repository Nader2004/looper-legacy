import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
              child: adWidget,
            ),
          ),
        ),
      ),
    );
  }
}
