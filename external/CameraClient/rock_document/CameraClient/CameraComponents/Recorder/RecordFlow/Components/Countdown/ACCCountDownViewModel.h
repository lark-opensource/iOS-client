//
//  ACCCountDownViewModel.h
//  CameraClient
//
//  Created by guochenxiang on 2020/4/26.
//

#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitArch/ACCStudioDefines.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <AVFoundation/AVFoundation.h>

@class ACCCountDownModel;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCountDownProvideProtocol <NSObject>


@property (nonatomic, assign) AWEDelayRecordMode delayRecordMode;

@property (nonatomic, strong) ACCCountDownModel *countDownModel;

@end

@interface ACCCountDownViewModel : ACCRecorderViewModel <ACCCountDownProvideProtocol>

- (void)configDelayRecordMode;
- (void)showVolumesWithShouldCount:(NSInteger)shouldCount completion:(void(^)(NSArray<NSNumber *> *volumes))completion;
- (AVAsset *)musicAsset;

@end

NS_ASSUME_NONNULL_END
