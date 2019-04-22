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

#import "GADMAdapterUnitySingleton.h"

#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityWeakReference.h"

@implementation GADMAdapterUnitySingleton

+ (instancetype)sharedInstance {
  static GADMAdapterUnitySingleton *sharedManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedManager = [[self alloc] init];
  });
  return sharedManager;
}

-(BOOL)configureWithGameID:(NSString *)gameID {
    if ([UnityAds isSupported]) {
      if (![UnityAds isInitialized]) {
        [UnityAds initialize:gameID];
        return YES;
      }
    }
    return NO;
}


@end
