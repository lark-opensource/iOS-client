//
//  ACCRecordSwitchModeComponent.h
//  Pods
//
//  Created by songxiangwu on 2019/7/30.
//

#import <CreativeKit/ACCFeatureComponent.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCGroupedPredicate;

@interface ACCRecordSwitchModeComponent : ACCFeatureComponent

@property (nonatomic, strong, readonly) ACCGroupedPredicate *shouldShowSwitchModeView;

- (void)updateSwitchModeViewHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
