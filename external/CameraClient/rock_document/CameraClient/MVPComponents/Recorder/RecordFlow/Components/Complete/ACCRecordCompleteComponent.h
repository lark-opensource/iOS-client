//
//  ACCRecordCompleteComponent.h
//  CameraClient-Pods-Aweme
//
//  Created by guochenxiang on 2020/11/24.
//

#import <CreativeKit/ACCFeatureComponent.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CameraClient/ACCRecordCompletePauseStateHandler.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCGroupedPredicate;

@interface ACCRecordCompleteComponent : ACCFeatureComponent

- (void)updateCompleteButtonHidden:(BOOL)hidden;
- (void)clickCompleteBtn:(UITapGestureRecognizer *)sender;

@property (nonatomic, strong, readonly) ACCGroupedPredicate<id, id> *shouldShow;

@property (nonatomic, weak) id<ACCRecordCompletePauseStateHandler> liteLowQualityHandler;

@end

NS_ASSUME_NONNULL_END
