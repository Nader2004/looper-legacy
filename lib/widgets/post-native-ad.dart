import 'dart:async';
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
  final Completer<NativeAd> nativeAdCompleter = Completer<NativeAd>();

  @override
  void initState() {  
    nativeAd = NativeAd(
      adUnitId: Platform.isIOS ? IOSAdUnitId : AndroidAdUnitId,
      factoryId: 'native-ad',
      listener: AdListener(
        onAdLoaded: (ad) {
          nativeAdCompleter.complete(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          nativeAd.dispose();
          nativeAdCompleter.completeError(error);
        },
        onApplicationExit: (ad) {
          nativeAd.dispose();
        },
      ),
      request: AdRequest(),
    );
    Future<void>.delayed(Duration(seconds: 1), () => nativeAd.load());
    super.initState();
  }

  @override
  void dispose() {
    nativeAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NativeAd>(
        future: nativeAdCompleter.future,
        builder: (context, snapshot) {
          Widget child;

          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              child = Container();
              break;
            case ConnectionState.done:
              if (snapshot.hasData) {
                child = AdWidget(ad: nativeAd);
              } else {
                child = Text('Error loading $NativeAd');
              }
          }

          return Container(
            height: MediaQuery.of(context).size.height / 3,
            margin: EdgeInsets.symmetric(horizontal: 10),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: child,
              ),
            ),
          );
        });
  }
}
