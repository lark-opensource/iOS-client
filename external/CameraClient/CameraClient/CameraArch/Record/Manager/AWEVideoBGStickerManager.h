//
//  AWEVideoBGManager.h
//  CameraClient-Pods-Aweme
//
//  Created by wishes on 2019/11/1.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import "AWECaptureButtonAnimationView.h"
#import "ACCRecordConfigService.h"
#import <CreationKitArch/ACCRecordMode.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEAssetModel;
@protocol ACCCameraService;

@protocol AWEVideoBGStickerManagerDelegate <NSObject>

- (AWEVideoPublishViewModel *)publishModel;

- (id<ACCRecordConfigService>)configPublish;

- (id<ACCCameraService>)cameraService;

- (CGFloat)selectedSpeed;

- (void)updateAudioRangeWithStartLocation:(double)startLocation;

@end


@interface AWEVideoBGStickerManager : NSObject

@property (nonatomic, strong) NSURL* defaultVideoAssetUrl;
@property (nonatomic, copy) NSString *pixaloopVKey;

@property (nonatomic, strong, nullable) AWEAssetModel* currentSelectedMattingAssetModel;
@property (nonatomic, strong, nullable) NSURL* currentApplyVideoBGUrl;
@property (nonatomic, weak) id<AWEVideoBGStickerManagerDelegate> delegate;
@property (nonatomic, assign) BOOL isPausedManually;
@property (nonatomic, assign) BOOL isDeleteAllSegment;
@property (nonatomic, assign) BOOL isMultiScanBgVideoType;
@property (nonatomic, assign) BOOL isFinishTakePicture;
@property (nonatomic, assign) BOOL isVideoControlSuccessing; // Algorithm recognition success
@property (nonatomic, strong) ACCRecordMode *currentCameraMode;

@property (nonatomic, copy, nullable) void (^didPlayToEndBlock)();

- (instancetype)init;

- (void)resetVideoBGCamera;

- (void)applyVideoBGToCamera:(NSURL* _Nullable)url;


- (void)cameraDidStartCapture;

- (void)cameraDidPauseCapture;

- (void)cameraDidStopCapture;

- (void)cameraSpeedDidChange:(CGFloat)speed;

- (void)cameraLastSegmentDidDeleted;

- (void)cameraAllSegmentDidDeleted;

- (void)cameraRecordModeChange:(ACCRecordMode *)mode;


- (void)stickerWillApply:(IESEffectModel*)sticker;

- (void)containerViewControllerWillDisAppear;

- (void)containerViewControllerDidAppear;


+ (void)verifyAssetValid:(AWEAssetModel*)assetModel completion:(dispatch_block_t)completion;

- (void)bgVideoPlay;
- (void)bgVideoPause;
- (void)bgVideoRestart;

@end

NS_ASSUME_NONNULL_END
