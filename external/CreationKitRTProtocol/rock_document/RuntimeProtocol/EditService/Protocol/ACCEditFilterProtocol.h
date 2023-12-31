//
//  ACCEditFilterProtocol.h
//  CameraClient
//
//  Created by haoyipeng on 2020/8/13.
//

#import <Foundation/Foundation.h>
#import "ACCEditWrapper.h"
#import <EffectPlatformSDK/IESEffectModel.h>
NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditFilterProtocol <ACCEditWrapper>

- (void)applyFilterEffect:(nullable IESEffectModel *)effect;
- (void)applyFilterEffect:(nullable IESEffectModel *)effect intensity:(float)intensity;

- (BOOL)switchColorLeftFilter:(IESEffectModel *)leftFilter
                  rightFilter:(IESEffectModel *)rightFilter
                   inPosition:(float)position
              inLeftIntensity:(float)leftIntensity
             inRightIntensity:(float)rightIntensity;

- (BOOL)switchColorLeftFilter:(IESEffectModel *)leftFilter
                  rightFilter:(IESEffectModel *)rightFilter
                   inPosition:(float)position;

/// Get specified filter's intensity.
/// @param path Specified filte
- (float)filterEffectOriginIndensity:(nullable IESEffectModel *)effect;

@end

NS_ASSUME_NONNULL_END
