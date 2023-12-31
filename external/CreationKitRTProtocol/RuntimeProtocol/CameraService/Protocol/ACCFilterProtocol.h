//
//  ACCFilterProtocol.h
//  Pods
//
//  Created by liyingpeng on 2020/6/4.
//

#ifndef ACCFilterProtocol_h
#define ACCFilterProtocol_h

#import "ACCCameraWrapper.h"

@class IESEffectModel;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCFilterProtocol <ACCCameraWrapper>

- (float)acc_filterEffectOriginIndensity:(NSString * _Nullable)path;

- (void)acc_applyFilterEffect:(IESEffectModel * _Nullable)effect;
- (void)acc_applyFilterEffect:(IESEffectModel * _Nullable)effect intensity:(float)intensity;

- (void)acc_removeFilterEffect:(IESEffectModel * _Nullable)effect;
- (BOOL)switchColorLeftFilter:(IESEffectModel *)leftFilter
                  rightFilter:(IESEffectModel *)rightFilter
                   inPosition:(float)position
              inLeftIntensity:(float)leftIntensity
             inRightIntensity:(float)rightIntensity;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCFilterProtocol_h */
