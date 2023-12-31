//
//  AWEVideoBGManager.m
//  CameraClient-Pods-Aweme
//
//  Created by wishes on 2019/11/1.
//

#import "AWEVideoBGStickerManager.h"
#import <CameraClient/AWEAssetModel.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitInfra/ACCResponder.h>
#import <CreationKitArch/ACCStudioServiceProtocol.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIApplication+ACC.h>
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>

@interface AWEVideoBGStickerManager ()
@property (nonatomic, strong) id<ACCVideoConfigProtocol> videoConfig;
@end

@implementation AWEVideoBGStickerManager
IESAutoInject(ACCBaseServiceProvider(), videoConfig, ACCVideoConfigProtocol)

@synthesize currentApplyVideoBGUrl = _currentApplyVideoBGUrl;

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

//getter
- (void)applyVideoBGToCamera:(NSURL* _Nullable)url {
    acc_dispatch_main_async_safe(^{
        self.currentApplyVideoBGUrl = url;
        if (!self.isMultiScanBgVideoType || (self.isMultiScanBgVideoType && self.delegate.publishModel.repoVideoInfo.fragmentInfo.count == 0)) {
            self.isPausedManually = NO;
        }
        if (url) {
          [self setVideoBGCamera:url];
        } else {
          self.currentSelectedMattingAssetModel = nil;
          if (self.defaultVideoAssetUrl) {
              self.currentApplyVideoBGUrl = self.defaultVideoAssetUrl;
              [self setVideoBGCamera:self.defaultVideoAssetUrl];
          }
        }
        [self.delegate.configPublish configPublishModelMaxDurationWithAsset:nil showRecordLengthTipBlock:YES isFirstEmbed:NO];
    });
}

- (NSURL *)currentWrapApplyVideoBGUrl {
    return _currentApplyVideoBGUrl;
}

- (BOOL)needPlayBgVideo {
    if (!self.isMultiScanBgVideoType) {
        return YES;
    } else {
        if (self.isVideoControlSuccessing) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)needPauseWithCurrentMode
{
    if (!self.currentCameraMode.isPhoto && !self.currentCameraMode.isVideo) {
        return YES;
    }
    return NO;
}

- (void)setVideoBGCamera:(NSURL*)url {
    @weakify(self);
    [self bgVideoMutePlayer:NO];
    [self setBGVideoWithVideoURL:url key:self.pixaloopVKey rate: 1.0/self.delegate.selectedSpeed completeBlock:^(NSError * _Nullable error) {
          @strongify(self);
         [self setBGVideoAutoRepeat:YES];
         if (!self.isPausedManually && !self.isFinishTakePicture && [self needPlayBgVideo] && ![self needPauseWithCurrentMode]) {
            [self bgVideoPlay];
         }
    } didPlayToEndBlock:^{
        @strongify(self);
        if (self.isMultiScanBgVideoType && self.isVideoControlSuccessing && [self.delegate.cameraService.cameraControl status] == IESMMCameraStatusRecording) {
            ACCBLOCK_INVOKE(self.didPlayToEndBlock);
        }
    }];
}

// remove video
- (void)resetVideoBGCamera {
    // duet video or react video could not apply this effect
    if (self.delegate.publishModel.repoDuet.isDuet) {
        return;
    }
    self.currentApplyVideoBGUrl = nil;
    self.currentSelectedMattingAssetModel = nil;
    [self resetBGVideo];
    [self.delegate.configPublish configPublishModelMaxDurationWithAsset:nil showRecordLengthTipBlock:YES isFirstEmbed:NO];
    [self.delegate updateAudioRangeWithStartLocation:self.delegate.publishModel.repoMusic.audioRange.location];
    
}

- (void)stickerWillApply:(IESEffectModel *)sticker {
    @weakify(self);
    [self guardBGVideoStickerApplied:^{
        @strongify(self);
        [self resetVideoBGCamera];
    }];
}


- (void)cameraDidStartCapture {
    @weakify(self);
    self.isDeleteAllSegment = NO;
    [self guardBGVideoStickerApplied:^{
        @strongify(self);
        [self setBGVideoAutoRepeat:NO];
        self.delegate.publishModel.repoVideoInfo.fragmentInfo.lastObject.stickerVideoAssetURL = [self currentWrapApplyVideoBGUrl];
        [self bgVideoMutePlayer: self.delegate.publishModel.repoMusic.music != nil];
        
        NSUInteger fragmentCount = self.delegate.publishModel.repoVideoInfo.fragmentInfo.count;
        if (fragmentCount <= 1) {
            if ([self needPlayBgVideo]) {
                [self bgVideoRestart];
            }
        } else if ([[self currentWrapApplyVideoBGUrl].absoluteString isEqualToString:self.delegate.publishModel.repoVideoInfo.fragmentInfo[fragmentCount - 2].stickerVideoAssetURL.absoluteString]) {
            if ([self needPlayBgVideo]) {
                [self bgVideoPlay];
            }
        } else {
            if ([self needPlayBgVideo]) {
                [self bgVideoRestart];
            }
        }
    }];
}

- (void)cameraDidPauseCapture {
    @weakify(self);
    [self guardBGVideoStickerApplied:^{
        @strongify(self);
        [self bgVideoPause];
        [self bgVideoCurrentPlayPercent:^(float percent) {
            @strongify(self);
            self.delegate.publishModel.repoVideoInfo.fragmentInfo.lastObject.stickerBGPlayedPercent = percent;
        }];
    }];

}

- (void)cameraDidStopCapture {
    @weakify(self);
    [self guardBGVideoStickerApplied:^{
        @strongify(self);
        [self bgVideoPause];
        [self bgVideoCurrentPlayPercent:^(float percent) {
            @strongify(self);
            self.delegate.publishModel.repoVideoInfo.fragmentInfo.lastObject.stickerBGPlayedPercent = percent;
         }];
    }];
}

- (void)cameraSpeedDidChange:(CGFloat)speed {
    @weakify(self);
    [self bgVideoCurrentPlayPercent:^(float percent) {
        CGFloat currentPercent = percent;
        @strongify(self);
        [self guardBGVideoStickerApplied:^{
            @strongify(self);
            [self bgVideoChangeRate:1.0/speed completeBlock:^(NSError * _Nullable error) {
                @strongify(self);
                [self bgVideoSeekToPercent:currentPercent completeBlock:nil];
            }];
        }];
    }];
}


- (void)cameraLastSegmentDidDeleted {
    @weakify(self);
    [self guardBGVideoStickerApplied:^{
        @strongify(self);
        if (self.delegate.publishModel.repoVideoInfo.fragmentInfo.count == 0) {
            if (![self bgVideoIsPlaying]) {
                [self bgVideoSeekToPercent:0 completeBlock:nil];
            }
            [self.delegate.configPublish configPublishModelMaxDurationWithAsset:nil showRecordLengthTipBlock:YES isFirstEmbed:NO];
            return;
        }
        // 当前的贴纸视频和删除结束最后一段相同，则是在同一段视频下拍摄
        if ([[self currentWrapApplyVideoBGUrl].absoluteString isEqualToString:self.delegate.publishModel.repoVideoInfo.fragmentInfo.lastObject.stickerVideoAssetURL.absoluteString]) {
            [self bgVideoSeekToPercent:self.delegate.publishModel.repoVideoInfo.fragmentInfo.lastObject.stickerBGPlayedPercent completeBlock:nil];
        } else {
            if (![self bgVideoIsPlaying]) {
                [self bgVideoSeekToPercent:0 completeBlock:nil];
            }
            [self.delegate.configPublish configPublishModelMaxDurationWithAsset:nil showRecordLengthTipBlock:YES isFirstEmbed:NO];
        }
    }];
}

- (void)cameraAllSegmentDidDeleted {
    @weakify(self);
    [self guardBGVideoStickerApplied:^{
        @strongify(self);
        self.isDeleteAllSegment = YES;
        if (![self bgVideoIsPlaying]) {
            [self bgVideoSeekToPercent:0 completeBlock:nil];
        }
        [self.delegate.configPublish configPublishModelMaxDurationWithAsset:nil showRecordLengthTipBlock:YES isFirstEmbed:NO];
    }];
}

- (void)cameraRecordModeChange:(ACCRecordMode *)mode {
    self.currentCameraMode = mode;
    [self guardBGVideoStickerApplied:^{
        if ([self needPauseWithCurrentMode]) {
           [self bgVideoPause];
        } else {
            if (!self.isPausedManually && [self needPlayBgVideo]) {
              [self bgVideoPlay];
            }
        }
    }];
}


- (void)guardBGVideoStickerApplied:(dispatch_block_t)compltion {
    if (self.currentApplyVideoBGUrl != nil && self.currentApplyVideoBGUrl.absoluteString.length > 0 ) {
        compltion();
    }
}


- (void)applicationDidBecomeActive:(NSNotification *)notification {
    @weakify(self);
    [self guardBGVideoStickerApplied:^{
        @strongify(self);
        if (!self.isPausedManually && [[ACCResponder topViewController] isKindOfClass:[IESAutoInline(ACCBaseServiceProvider(), ACCStudioServiceProtocol) classOfPageType:AWEStuioPageVideoRecord]] ) {
            if (!self.isMultiScanBgVideoType) {
                [self bgVideoPlay];
            }
        }
    }];
}

- (void)containerViewControllerWillDisAppear {
    @weakify(self);
    [self guardBGVideoStickerApplied:^{
        @strongify(self);
        [self bgVideoPause];
    }];
}


- (void)containerViewControllerDidAppear {
    @weakify(self);
    self.isFinishTakePicture = NO;
    [self guardBGVideoStickerApplied:^{
        @strongify(self);
        if (!self.isPausedManually && [self needPlayBgVideo] && ![self needPauseWithCurrentMode]) {
            [self bgVideoPlay];
        }
    }];
}

#pragma camera bg interface

- (void)setBGVideoWithVideoURL:(NSURL *)url key:(NSString *)key rate:(float)rate completeBlock:(CompleteBlock)completeBlock didPlayToEndBlock:(void (^)(void))didPlayToEndBlock {
    [self.delegate.cameraService.recorder setBGVideoWithVideoURL:url key:key rate:rate completeBlock:completeBlock didPlayToEndBlock:didPlayToEndBlock];
}

- (void)resetBGVideo {
    [self.delegate.cameraService.recorder resetBGVideo];
}

- (void)bgVideoPlay {
    [self.delegate.cameraService.recorder bgVideoPlay];
}

- (void)bgVideoPause {
    [self.delegate.cameraService.recorder bgVideoPause];
}

- (void)bgVideoRestart {
    [self.delegate.cameraService.recorder bgVideoRestart];
}

- (BOOL)bgVideoIsPlaying {
    return [self.delegate.cameraService.recorder bgVideoIsPlaying];
}

- (void)bgVideoMutePlayer:(BOOL)muted {
    [self.delegate.cameraService.recorder bgVideoMutePlayer:muted];
}


- (void)bgVideoCurrentPlayPercent:(void (^)(float percent))responseBlock {
    @weakify(self);
    if ([self.delegate.cameraService.recorder  respondsToSelector:@selector(bgVideoCurrentPlayPercent)]){
        //because the interface bgVideoCurrentPlayPercent run in main thread would frozen
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @strongify(self);
            float percent = [self.delegate.cameraService.recorder bgVideoCurrentPlayPercent];
            if (isnan(percent)) {
                acc_dispatch_main_async_safe(^{
                    ACCBLOCK_INVOKE(responseBlock,0.f);
                });
            } else {
                acc_dispatch_main_async_safe(^{
                    ACCBLOCK_INVOKE(responseBlock,percent);
                });
            }
        });
    } else {
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(responseBlock,0.f);
        });
    }
}


- (void)bgVideoSeekToPercent:(float)percent completeBlock:(nullable void (^)(BOOL finished))completeBlock {
    [self.delegate.cameraService.recorder bgVideoSeekToPercent:percent completeBlock:completeBlock];
}


- (void)bgVideoChangeRate:(float)rate completeBlock:(CompleteBlock)completeBlock {
    [self.delegate.cameraService.recorder multiVideoChangeRate:rate completeBlock:completeBlock];
}

- (void)setBGVideoAutoRepeat:(BOOL)autoRepeat {
    [self.delegate.cameraService.cameraControl setBGVideoAutoRepeat:autoRepeat];
}

#pragma choose video asset

+ (void)verifyAssetValid:(AWEAssetModel*)assetModel completion:(dispatch_block_t)completion {
   
    let videoConfig = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    CGFloat duration = assetModel.asset.duration;
     if (duration < [videoConfig videoMinSeconds]) {
          NSString *minTimeTipDes = [NSString stringWithFormat: ACCLocalizedString(@"profile_cover_video_duration",@"视频时长不能小于%d秒"), [videoConfig videoMinSeconds]];
          [ACCToast() show:minTimeTipDes];
          return;
    }
      
    if (duration > (Float64)[videoConfig videoSelectableMaxSeconds]) {
          [ACCToast() show: ACCLocalizedString(@"com_mig_video_is_too_long_try_another_one",@"视频太长，请重新选择")];
          return;
    }
    if (!assetModel.avAsset) {
        UIView *maskView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        maskView.backgroundColor = [UIColor clearColor];
        [[UIApplication acc_currentWindow] addSubview:maskView];
        PHAsset* phAsset = assetModel.asset;
        NSURL *url = [phAsset valueForKey:@"ALAssetURL"];
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        if (@available(iOS 14.0, *)) {
            options.version = PHVideoRequestOptionsVersionCurrent;
            options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        }
        
        [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset
                                                          options:options
                                                    resultHandler:^(AVAsset *_Nullable blockAsset, AVAudioMix *_Nullable audioMix, NSDictionary *_Nullable info) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            BOOL isICloud = [info[PHImageResultIsInCloudKey] boolValue];
                                                            assetModel.isFromICloud = isICloud;
                                                            if (isICloud && !blockAsset) {
                                                               [maskView removeFromSuperview];
                                                                [ACCToast() show:ACCLocalizedString(@"creation_icloud_download", @"正在从iCloud同步内容")];
                                                               [self requestAVAssetFromiCloudWithModel:assetModel];
                                                            } else {
                                                                if (blockAsset) {
                                                                    assetModel.avAsset = blockAsset;
                                                                    if (SYSTEM_VERSION_LESS_THAN(@"9") && assetModel.mediaSubType == AWEAssetModelMediaSubTypeVideoHighFrameRate) {
                                                                        AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
                                                                        if (urlAsset) {
                                                                            assetModel.avAsset = urlAsset;
                                                                        }
                                                                    }
                                                                    assetModel.info = info;
                                                                    [maskView removeFromSuperview];
                                                                    completion();
                                                                } else {
                                                                    [maskView removeFromSuperview];
                                                                    [ACCToast() show: ACCLocalizedString(@"error_param",@"出错了")];
                                                                }
                                                            }
                                                        });
                                                    }];
    } else {
        completion();
    }
}


+ (void)requestAVAssetFromiCloudWithModel:(AWEAssetModel *)assetModel {
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.networkAccessAllowed = YES;

    //run animation ahead
    assetModel.iCloudSyncProgress = 0.f;
    
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            assetModel.iCloudSyncProgress = progress;
        });
    };
    if (@available(iOS 14.0, *)) {
        options.version = PHVideoRequestOptionsVersionCurrent;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    }
    
    PHAsset *sourceAsset = assetModel.asset;
    NSURL *url = [sourceAsset valueForKey:@"ALAssetURL"];
    [[PHImageManager defaultManager] requestAVAssetForVideo:sourceAsset
                                                    options:options
                                              resultHandler:^(AVAsset *_Nullable asset, AVAudioMix *_Nullable audioMix,
                                                              NSDictionary *_Nullable info) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                          if (asset) {
                                                              assetModel.avAsset = asset;
                                                              if (SYSTEM_VERSION_LESS_THAN(@"9") && assetModel.mediaSubType == AWEAssetModelMediaSubTypeVideoHighFrameRate) {
                                                                  AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
                                                                  if (urlAsset) {
                                                                      assetModel.avAsset = urlAsset;
                                                                  }
                                                              }
                                                              assetModel.info = info;
                                                          } else {
                                                              //没有获取到照片
                                                              [ACCToast() show:ACCLocalizedString(@"error_param",@"出错了")];
                                                          }
                                                    
                                                  });
                                              }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
