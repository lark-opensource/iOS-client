//
//  ACCPropComponentV2.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/7/12.
//

#import <CreativeKit/ACCFeatureComponent.h>
#import <CameraClient/ACCStickerGroupedApplyPredicate.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCPropComponentV2 : ACCFeatureComponent

- (void)addPropApplyPredicate:(id<ACCStickerApplyPredicate>)predicate;

@end

NS_ASSUME_NONNULL_END
