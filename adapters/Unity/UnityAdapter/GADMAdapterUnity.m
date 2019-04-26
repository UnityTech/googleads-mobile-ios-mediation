// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterUnity.h"

#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnitySingleton.h"
#import "GADUnityError.h"

@interface GADMAdapterUnity () <UADSInterstitialAdDelegate, UADSRewardedVideoAdDelegate, UADSBannerAdDelegate> {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMRewardBasedVideoAdNetworkConnector> _rewardBasedVideoAdConnector;

  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _networkConnector;

  /// Placement ID of Unity Ads network.
  NSString *_placementID;

  UADSInterstitialAd* _interstitialAd;
  UADSBannerAd* _bannerAd;
  UADSRewardedVideoAd* _rewardedVideoAd;
}

@end

@implementation GADMAdapterUnity

+ (NSString *)adapterVersion {
  return GADMAdapterUnityVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return Nil;
}

#pragma mark Reward-based Video Ad Methods

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
        (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }

  self = [super init];
  if (self) {
    _rewardBasedVideoAdConnector = connector;
  }
  return self;
}

- (void)setUp {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  NSString *gameID =
      [[[strongConnector credentials] objectForKey:GADMAdapterUnityGameID] copy];
  _placementID =
      [[[strongConnector credentials] objectForKey:GADMAdapterUnityPlacementID] copy];
  if (!gameID || !_placementID) {
    NSError *error = GADUnityErrorWithDescription(@"Game ID and Placement ID cannot be nil.");
    [strongConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
    return;
  }
  BOOL isConfigured = [[GADMAdapterUnitySingleton sharedInstance] configureWithGameID:gameID];
  if (isConfigured) {
    [strongConnector adapterDidSetUpRewardBasedVideoAd:self];
  } else {
    NSString *description =
        [[NSString alloc] initWithFormat:@"%@ is not supported for this device.",
                                         NSStringFromClass([UnityAds class])];
    NSError *error = GADUnityErrorWithDescription(description);
    [strongConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
  }
}

- (void)requestRewardBasedVideoAd {
  if (_rewardedVideoAd == nil) {
    _rewardedVideoAd = [[UADSRewardedVideoAd alloc] initWithPlacementId:_placementID];
    _rewardedVideoAd.delegate = self;
    [_rewardedVideoAd load];
  }
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
  if ([_rewardedVideoAd canShow]) {
    [_rewardedVideoAd showFromViewController:viewController];
  }
}

#pragma mark Interstitial Methods

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }

  self = [super init];
  if (self) {
    _networkConnector = connector;
  }
  return self;
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _networkConnector;
  NSString *gameID =
      [[[strongConnector credentials] objectForKey:GADMAdapterUnityGameID] copy];
  _placementID =
      [[[strongConnector credentials] objectForKey:GADMAdapterUnityPlacementID] copy];
  if (!gameID || !_placementID) {
    NSError *error = GADUnityErrorWithDescription(@"Game ID and Placement ID cannot be nil.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }
  [[GADMAdapterUnitySingleton sharedInstance] configureWithGameID:gameID];

  if (!_interstitialAd) {
    _interstitialAd = [[UADSInterstitialAd alloc] initWithPlacementId:_placementID];
    _interstitialAd.delegate = self;
    [_interstitialAd load];
  }
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    if ([_interstitialAd canShow]) {
      [_networkConnector adapterWillPresentInterstitial:self];
      [_interstitialAd showFromViewController:rootViewController];
    }
}

#pragma mark Banner Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongNetworkConnector = _networkConnector;
  NSString *gameID =
      [[[strongNetworkConnector credentials] objectForKey:GADMAdapterUnityGameID] copy];
  _placementID =
      [[[strongNetworkConnector credentials] objectForKey:GADMAdapterUnityPlacementID] copy];
  if (!gameID || !_placementID) {
    NSError *error = GADUnityErrorWithDescription(@"Game ID and Placement ID cannot be nil.");
    [strongNetworkConnector adapter:self didFailAd:error];
    return;
  }
  [[GADMAdapterUnitySingleton sharedInstance] configureWithGameID:gameID];

  if (!_bannerAd) {
    _bannerAd = [[UADSBannerAd alloc] initWithPlacementId:_placementID];
    _bannerAd.delegate = self;
    [_bannerAd load];
  }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

#pragma mark - UADSInterstitialAdDelegate

-(void)interstitialAdDidLoad:(UADSInterstitialAd *)interstitialAd {
  [_networkConnector adapterDidReceiveInterstitial:self];
}
-(void)interstitialAdDidFailToLoad:(UADSInterstitialAd *)interstitialAd error:(NSError *)error {
  [_networkConnector adapter:self didFailAd:GADUnityErrorWithDescription([error description])];
}
-(void)interstitialAdDidOpen:(UADSInterstitialAd *)interstitialAd {
}

-(void)interstitialAdDidClick:(UADSInterstitialAd *)interstitialAd {
  [_networkConnector adapterDidGetAdClick:self];
}
-(void)interstitialAdDidLeaveApplication:(UADSInterstitialAd *)interstitialAd {
  [_networkConnector adapterWillLeaveApplication:self];
}
-(void)interstitialAdDidInvalidate:(UADSInterstitialAd *)interstitialAd {
}

-(void)interstitialAdDidClose:(UADSInterstitialAd *)interstitialAd finishState:(UnityAdsFinishState)finishState {
  [_networkConnector adapterWillDismissInterstitial:self];
  _interstitialAd = nil;
  [_networkConnector adapterDidDismissInterstitial:self];
}

#pragma mark - UADSRewardedVideoAdDelegate

-(void)rewardedVideoAdDidLoad:(UADSRewardedVideoAd *)rewardedVideoAd {
  [_rewardBasedVideoAdConnector adapterDidReceiveRewardBasedVideoAd:self];
}
-(void)rewardedVideoAdDidFailToLoad:(UADSRewardedVideoAd *)rewardedVideoAd exception:(NSException *)exception {
  [_rewardBasedVideoAdConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:GADUnityErrorWithDescription([exception description])];
}
-(void)rewardedVideoAdDidOpen:(UADSRewardedVideoAd *)rewardedVideoAd {
  [_rewardBasedVideoAdConnector adapterDidOpenRewardBasedVideoAd:self];
}
-(void)rewardedVideoAdDidStart:(UADSRewardedVideoAd *)rewardedVideoAd {
  [_rewardBasedVideoAdConnector adapterDidStartPlayingRewardBasedVideoAd:self];
}

-(void)rewardedVideoAdDidClick:(UADSRewardedVideoAd *)rewardedVideoAd {
  [_rewardBasedVideoAdConnector adapterDidGetAdClick:self];
}
-(void)rewardedVideoAdDidLeaveApplication:(UADSRewardedVideoAd *)rewardedVideoAd {
  [_rewardBasedVideoAdConnector adapterWillLeaveApplication:self];
}
-(void)rewardedVideoAdDidReward:(UADSRewardedVideoAd *)rewardedVideoAd {
  GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:@"" rewardAmount:[NSDecimalNumber one]];
  [_rewardBasedVideoAdConnector adapter:self didRewardUserWithReward:reward];
}
-(void)rewardedVideoAdDidClose:(UADSRewardedVideoAd *)rewardedVideoAd finishState:(UnityAdsFinishState)finishState {
  [_rewardBasedVideoAdConnector adapterDidCloseRewardBasedVideoAd:self];
  _rewardedVideoAd = nil;
}
-(void)rewardedVideoAdDidInvalidate:(UADSRewardedVideoAd *)rewardedVideoAd {

}
-(void)rewardedVideoAdDidFinish:(UADSRewardedVideoAd *)rewardedVideoAd {
  [_rewardBasedVideoAdConnector adapterDidCompletePlayingRewardBasedVideoAd:self];
}

#pragma mark - UADSBannerAdDelegate

-(void)bannerAdDidLoad:(UADSBannerAd *)bannerAd {
  [_networkConnector adapter:self didReceiveAdView:[bannerAd getView]];
}

-(void)bannerAdDidFailToLoad:(UADSBannerAd *)bannerAd error:(NSError *)error {
  [_networkConnector adapter:self didFailAd:GADUnityErrorWithDescription([error description])];
}

-(void)bannerAdDidOpen:(UADSBannerAd *)bannerAd {
}

-(void)bannerAdDidClose:(UADSBannerAd *)bannerAd {
}

-(void)bannerAdDidClick:(UADSBannerAd *)bannerAd {
  [_networkConnector adapterDidGetAdClick:self];
}
-(void)bannerAdDidLeaveApplication:(UADSBannerAd *)bannerAd {
  [_networkConnector adapterWillLeaveApplication:self];
}

-(void)bannerAdDidInvalidate:(UADSBannerAd *)bannerAd {
}


@end


