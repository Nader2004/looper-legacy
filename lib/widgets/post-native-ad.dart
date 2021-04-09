import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class PostNativeAd extends StatefulWidget {
  PostNativeAd({Key key}) : super(key: key);

  @override
  _PostNativeAdState createState() => _PostNativeAdState();
}

class _PostNativeAdState extends State<PostNativeAd> {
  static const String AndroidAdUnitId = 'ca-app-pub-9448985372006294/2961269368';
  static const String IOSAdUnitId = 'ca-app-pub-9448985372006294/6816753892';
  NativeAd nativeAd; 
  bool _isLoaded = false;

  @override
  void initState() {
    nativeAd = NativeAd(
      adUnitId: Platform.isIOS ? IOSAdUnitId : AndroidAdUnitId,
      factoryId: 'native-ad',
      listener: AdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          nativeAd.dispose();
        },
        onApplicationExit: (ad) {
          nativeAd.dispose();
        },
      ),
      request: AdRequest(),
    );
    nativeAd.load();
    super.initState();
  }

  @override
  void dispose() {
    nativeAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AdWidget adWidget = AdWidget(ad: nativeAd);
    return _isLoaded == false
        ? SizedBox.shrink()
        : Container(
            height: MediaQuery.of(context).size.height / 3,
            margin: EdgeInsets.symmetric(horizontal: 10),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: adWidget,
              ),
            ),
          );
  }
}
