//
//  ACCRecordConfigService.h
//  CameraClient
//
//  Created by liuqing on 2020/4/20.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRecordConfigDurationHandler <NSObject>

@optional

- (CGFloat)getComponentDuration:(AVAsset *)asset;

- (void)willSetMaxDuration:(inout CGFloat *)duration
                     asset:(AVAsset *)asset
                   showTip:(BOOL)showTip
              isFirstEmbed:(BOOL)isFirstEmbed;

- (void)didSetMaxDuration:(CGFloat)duration;

@end

@protocol ACCRecordConfigAudioHandler <NSObject>

@optional

- (void)videoMutedTip:(NSString *)tip;

- (void)didFinishConfigAudioWithSetMusicCompletion:(void (^)(void))setMusicCompletion;

@end

@protocol ACCRecordConfigService <NSObject>

@required

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel;
- (void)setupInitialConfig;
- (CGFloat)videoMaxDuration;

- (BOOL)isFixedMaxDuration;
- (void)startFixedMaxDurationMode:(CGFloat)fixDuration;
- (void)endFixedMaxDurationMode;

- (void)configPublishModelMaxDurationAfterCameraSetMusic;
- (void)configPublishModelMaxDurationWithAsset:(nullable AVAsset *)asset showRecordLengthTipBlock:(BOOL)show isFirstEmbed:(BOOL)isFirstEmbed;
- (void)registDurationHandler:(id<ACCRecordConfigDurationHandler>)handler;

- (void)configAudioIfsetUp:(BOOL)isSetUpConfig withCompletion:(nullable void (^)(void))completion;
- (void)registAudioHandler:(id<ACCRecordConfigAudioHandler>)handler;

- (void)configRecordingMultiSegmentMaximumResolutionLimit;

- (void)configFinishPublishModel;

@optional
- (CGFloat)videoMinDuration;

@end

NS_ASSUME_NONNULL_END
