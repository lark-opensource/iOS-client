//
//  AWEColorFilterConfigurationHelper.h
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2020/9/15.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/EffectPlatform.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AWEColorFilterConfigurationType) {
    AWEColorFilterCaptureConfigurationType = 0,
    AWEColorFilterEditorConfigurationType,
    AWEColorFilterMvConfigurationType,
    AWEColorFilterPhotoConfigurationType,
    AWEColorFilterStoryConfigurationType,
};

@interface AWEColorFilterConfigurationHelper : NSObject

- (instancetype)initWithBeautyConfiguration:(AWEColorFilterConfigurationType)type;
- (void)setIndensityRatioForColorEffect:(IESEffectModel *)effectModel ratio:(float)ratio;
- (BOOL)hasIndensityRatioForColorEffect:(IESEffectModel *)effectModel;
- (float)indensityRatioForColorEffect:(IESEffectModel *)effectModel;
- (float)getEffectIndensityWithDefaultIndensity:(float)defaultIndensity Ratio:(float)ratio;

@end


NS_ASSUME_NONNULL_END
