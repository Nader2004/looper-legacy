#include "AppDelegate.h"
#import "FLTGoogleMobileAdsPlugin.h"
#include "GeneratedPluginRegistrant.h"

@interface LooperNativeAdFactory : NSObject <FLTNativeAdFactory>
@end

// The UnifiedNativeAdView.xib and example GADUnifiedNativeAdView is provided and
// explained by https://developers.google.com/admob/ios/native/advanced.
@implementation LooperNativeAdFactory
- (GADUnifiedNativeAdView *)createNativeAd:(GADUnifiedNativeAd *)nativeAd
                             customOptions:(NSDictionary *)customOptions {
  // Create and place ad in view hierarchy.
  GADUnifiedNativeAdView *adView =
      [[NSBundle mainBundle] loadNibNamed:@"UnifiedNativeAdView" owner:nil options:nil].firstObject;

  // Associate the native ad view with the native ad object. This is
  // required to make the ad clickable.
  adView.nativeAd = nativeAd;

  // Populate the native ad view with the native ad assets.
  // The headline is guaranteed to be present in every native ad.
  ((UILabel *)adView.headlineView).text = nativeAd.headline;

  // These assets are not guaranteed to be present. Check that they are before
  // showing or hiding them.
  ((UILabel *)adView.bodyView).text = nativeAd.body;
  adView.bodyView.hidden = nativeAd.body ? NO : YES;

  [((UIButton *)adView.callToActionView) setTitle:nativeAd.callToAction
                                         forState:UIControlStateNormal];
  adView.callToActionView.hidden = nativeAd.callToAction ? NO : YES;

  ((UIImageView *)adView.iconView).image = nativeAd.icon.image;
  adView.iconView.hidden = nativeAd.icon ? NO : YES;

  ((UILabel *)adView.storeView).text = nativeAd.store;
  adView.storeView.hidden = nativeAd.store ? NO : YES;

  ((UILabel *)adView.priceView).text = nativeAd.price;
  adView.priceView.hidden = nativeAd.price ? NO : YES;

  ((UILabel *)adView.advertiserView).text = nativeAd.advertiser;
  adView.advertiserView.hidden = nativeAd.advertiser ? NO : YES;

  // In order for the SDK to process touch events properly, user interaction
  // should be disabled.
  adView.callToActionView.userInteractionEnabled = NO;

  return adView;
}
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];

  LooperNativeAdFactory *nativeAdFactory = [[LooperNativeAdFactory alloc] init];
  [FLTGoogleMobileAdsPlugin registerNativeAdFactory:self
                                          factoryId:@"native-ad"
                                    nativeAdFactory:nativeAdFactory];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
