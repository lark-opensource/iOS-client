//
//  NLEFilter_OC+Extension.h
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/6/8.
//

#import <NLEPlatform/NLEFilter+iOS.h>

@class IESMMAudioFilter;
@interface NLEFilter_OC (Extension)

- (BOOL)isVoiceChangerFilter;

- (BOOL)isAudioFilter;

- (IESMMAudioFilter *)mmAudioFilterFromCurrentFilter;

+ (NLEFilter_OC *)filterFromMMAudioFilter:(IESMMAudioFilter *)mmAudioFilter  draftFolder:(NSString *)draftFolder;

+ (NLEFilter_OC *)voiceChangerFilterFromEffectPath:(NSString *)effectPath draftFolder:(NSString *)draftFolder;

- (BOOL)isNLEFilterForMMAudioFilter:(IESMMAudioFilter *)filter;

@end
