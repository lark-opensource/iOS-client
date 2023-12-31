//
//  VEEditorSession+ACCFilter.h
//  CameraClient
//
//  Created by haoyipeng on 2020/8/19.
//

#import <TTVideoEditor/VEEditorSession.h>
#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface VEEditorSession (ACCFilter)

// 调整滤镜强度
- (void)acc_applyFilterEffect:(IESEffectModel *)effect intensity:(float)intensity videoData:(HTSVideoData *)videoData;
- (void)acc_applyFilterEffect:(IESEffectModel *)effect videoData:(HTSVideoData *)videoData;

- (BOOL)acc_switchColorLeftFilter:(IESEffectModel *)leftFilter
                      rightFilter:(IESEffectModel *)rightFilter
                       inPosition:(float)position
                  inLeftIntensity:(float)leftIntensity
                 inRightIntensity:(float)rightIntensity
                        videoData:(HTSVideoData *)videoData;

// 获得滤镜强度
- (float)acc_filterEffectOriginIndensity:(nullable IESEffectModel *)effect;

- (void)acc_dumpVideoData:(HTSVideoData *)videoData;

@end

NS_ASSUME_NONNULL_END
