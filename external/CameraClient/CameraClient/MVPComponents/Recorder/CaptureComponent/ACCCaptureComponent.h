//
//  ACCCaptureComponent.h
//  Pods
//
//  Created by guochenxiang on 2019/7/28.
//

#import <Foundation/Foundation.h>

//message
#import <CreativeKit/ACCFeatureComponent.h>

#import <CreationKitInfra/ACCGroupedPredicate.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCCaptureComponent : ACCFeatureComponent

@property (nonatomic, strong, readonly) ACCGroupedPredicate<id, id> *startVideoCaptureOnWillAppearPredicate;
@property (nonatomic, strong, readonly) ACCGroupedPredicate<id, id> *startAudioCaptureOnWillAppearPredicate;
@property (nonatomic, strong, readonly) ACCGroupedPredicate<id, id> *startVideoCaptureOnAuthorizedPredicate;
@property (nonatomic, strong, readonly) ACCGroupedPredicate<id, id> *startAudioCaptureOnAuthorizedPredicate;

@property (nonatomic, strong, readonly) ACCGroupedPredicate<id, id> *shouldStartSamplingPredicate;
- (void)startSamplingIfNeeded;

@end

NS_ASSUME_NONNULL_END
