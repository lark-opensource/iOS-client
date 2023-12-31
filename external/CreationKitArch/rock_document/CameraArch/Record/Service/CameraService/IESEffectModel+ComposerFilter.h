//
//  IESEffectModel+ComposerFilter.h
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2020/9/11.
//

#import <EffectPlatformSDK/IESEffectModel.h>
#import <TTVideoEditor/IESMMEffectConfig.h>
#import "ACCFilterEffectItem.h"

extern NSString *const kLeftSlidePosition;
extern NSString *const kRightSlidePosition;

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectModel (ComposerFilter)

@property (nonatomic, strong, readonly, nullable) ACCFilterEffectItem *filterConfigItem;
@property (nonatomic, assign, readonly) BOOL isComposerFilter;

- (NSArray<VEComposerInfo *> *)nodeInfosWithIntensity:(float)intensity;
- (NSArray<VEComposerInfo *> *)nodeInfos;
- (NSArray<VEComposerInfo *> *)appendedNodeInfosWithPosition:(float)intensity
                                                  isLeftSide:(BOOL)isLeftSide;

@end

NS_ASSUME_NONNULL_END
