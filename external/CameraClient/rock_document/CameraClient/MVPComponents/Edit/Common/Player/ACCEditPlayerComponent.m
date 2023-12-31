//
//  ACCEditPlayerComponent.m
//  Pods
//
//  Created by gcx on 2019/10/20.
//

#import "AWERepoVideoInfoModel.h"
#import "AWERepoContextModel.h"
#import "ACCEditPlayerComponent.h"

#import "ACCEditPlayerViewModel.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitRTProtocol/ACCEditAudioEffectProtocol.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import "AWEXScreenAdaptManager.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <KVOController/KVOController.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoVoiceChangerModel.h>
#import <CameraClient/ACCRepoAudioModeModel.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

@interface ACCEditPlayerComponent () <ACCEditPreviewMessageProtocol, ACCEditSessionLifeCircleEvent>

@property (nonatomic, assign) BOOL isAudioSessionInterrupted;
@property (nonatomic, assign) BOOL prefersStickerEditMode;
@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, strong) ACCEditPlayerViewModel *viewModel;
@property (nonatomic, assign) BOOL currentlyOnEditPage;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@end

@implementation ACCEditPlayerComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.editService addSubscriber:self];
    [self.editService.preview addSubscriber:self];
}

- (void)dealloc
{
    [self p_removeObserver];
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (void)loadComponentView {
    if (!self.editService.mediaContainerView.superview) {
        if (self.viewContainer.containerView.superview) {
            [self.viewContainer.mediaView addSubview:self.editService.mediaContainerView];
            [self addBottomAdapterMaskIfNeeded];
        }
    }
    // 原有逻辑封面加载在willAppear
    if ([self.controller enableFirstRenderOptimize]) {
        [self addCoverImageForPlayerIfNeeded];
    }
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    
    if (self.publishModel.repoContext.videoType == AWEVideoTypeReplaceMusicVideo) {
        [[self audioEffectService] setVolumeForVideo:0.0];
    }
    
    [self p_bindViewModel];
    [self p_addObserver];
    
    @weakify(self);
    self.viewContainer.containerView.videoPlayerTappedBlock = ^(UIView * _Nonnull sender) {
        @strongify(self);
        [ACCTracker() trackEvent:@"edit_play_button_click" params:nil];
        [self.viewModel setShouldPlay:@(!self.viewModel.shouldPlay.boolValue)];
    };
    
    [self.viewModel setShouldPlay:@YES];
}

- (void)componentDidUnmount
{
    [self.editService.preview pause];
    [self.KVOController unobserveAll];
}

- (void)componentWillAppear
{
    self.editService.preview.shouldObservePlayerTimeActionPerform = YES;
    
    [self addCoverImageForPlayerIfNeeded];
    
    self.currentlyOnEditPage = YES;
    
    [self.editService.preview addSubscriber:self];
    
    //配音变声要先恢复再play
    if (ACC_isEmptyString(self.publishModel.repoVoiceChanger.voiceChangerID) &&
        (([self.viewModel.inputData.publishModel.repoContext supportNewEditClip] && self.viewModel.inputData.publishModel.repoContext.appearedMoreThanOne) || ![self.viewModel.inputData.publishModel.repoContext supportNewEditClip])) {
        [self.editService.preview play];
    }
}

- (void)addCoverImageForPlayerIfNeeded {
    if (self.repository.repoAudioMode.isAudioMode) {
        //模板类合成进编辑无占位图 从editorSession才能获取到占位
        @weakify(self);
        [self p_getFirstImageForMVVideoWithCompletion:^(UIImage *image) {
            @strongify(self);
            self.repository.repoPublishConfig.firstFrameImage = image;
            if (!self.editService.mediaContainerView.coverImageView.image) {
                self.editService.mediaContainerView.coverImageView.hidden = NO;
                self.editService.mediaContainerView.coverImageView.image = self.publishModel.repoPublishConfig.firstFrameImage;
            } else {
                self.editService.mediaContainerView.coverImageView.hidden = YES;
            }
        }];
    } else if (self.publishModel.repoPublishConfig.firstFrameImage && self.publishModel.repoContext.videoRecordType != AWEVideoRecordTypeBoomerang) {
        if (![self.editService.mediaContainerView.coverImageView superview] && !self.currentlyOnEditPage) {
            [self.editService.mediaContainerView addSubview:self.editService.mediaContainerView.coverImageView];
        }
        if (!self.editService.mediaContainerView.coverImageView.image) {
            self.editService.mediaContainerView.coverImageView.hidden = NO;
            self.editService.mediaContainerView.coverImageView.image = self.publishModel.repoPublishConfig.firstFrameImage;
        } else {
            [UIView animateWithDuration:0.2f animations:^{
                self.editService.mediaContainerView.coverImageView.alpha = 0.f;
            } completion:^(BOOL finished) {
                self.editService.mediaContainerView.coverImageView.hidden = YES;
                self.editService.mediaContainerView.coverImageView.alpha = 1.f;
            }];
        }
    } else if (self.publishModel.repoUploadInfo.toBeUploadedImage && self.publishModel.repoContext.isQuickStoryPictureVideoType && ACCConfigBool(kConfigBool_enable_lightning_pic_to_video_optimize)) {
        if (![self.editService.mediaContainerView.coverImageView superview] && !self.currentlyOnEditPage) {
            [self.editService.mediaContainerView addSubview:self.self.editService.mediaContainerView.coverImageView];
        }
        if (!self.editService.mediaContainerView.coverImageView.image && self.publishModel.repoVideoInfo.canvasType == ACCVideoCanvasTypeNone) {
            self.editService.mediaContainerView.coverImageView.hidden = NO;
            self.editService.mediaContainerView.coverImageView.image = self.publishModel.repoUploadInfo.toBeUploadedImage;
        }
    }
}

- (void)componentDidAppear {
    self.isAudioSessionInterrupted = NO;
    [self.editService.preview continuePlay];
}

- (void)componentWillDisappear
{
    self.editService.preview.shouldObservePlayerTimeActionPerform = NO;
    [self.editService.preview pause];
    [self.editService.preview setHighFrameRateRender:NO];
}

- (void)componentWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        CGRect newFrame = [self.editService.mediaContainerView mediaBigMediaFrameForSize:size];
        self.editService.mediaContainerView.frame = newFrame;
        self.editService.mediaContainerView.coverImageView.frame = newFrame;
        [self.editService resetPlayerAndPreviewEdge];
    } completion:nil];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)p_bindViewModel
{
    @weakify(self);
    [self.KVOController observe:self.viewModel keyPath:FBKVOClassKeyPath(ACCEditPlayerViewModel, shouldPlay) options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        NSNumber *newValue = ACCDynamicCast(change[NSKeyValueChangeNewKey], NSNumber);
        
        if (!newValue || ![newValue isKindOfClass:[NSNumber class]]) {
            NSAssert(NO, @"shouldPlay value type wrong");
            return;
        }
        BOOL shouldPlay = newValue.boolValue;
        id<ACCEditPreviewProtocol> preview = self.editService.preview;
        HTSPlayerStatus status = preview.status;
        acc_dispatch_main_async_safe(^{
            do {
                if (!self.viewContainer.rootView.window) {
                    AWELogToolDebug2(@"player", AWELogToolTagEdit, @"Signal ignored. edit player not on screen, signals maybe sent by other pages");
                    break;
                }
                if (status != preview.status) {
                    AWELogToolDebug2(@"player", AWELogToolTagEdit, @"Signal ignored. edit player status has changed to %@", @(preview.status));
                    break;
                }
                if (shouldPlay) {
                    if (status == HTSPlayerStatusIdle || status == HTSPlayerStatusWaitingPlay) {
                        AWELogToolInfo2(@"player", AWELogToolTagEdit, @"play");
                        self.prefersStickerEditMode ? [preview setStickerEditMode:NO] : [preview play];
                    }
                    if (preview.stickerEditMode == YES) {
                        // if we enabled sticker edit mode, others called -start to resume player,
                        // then we need manually exit edit mode
                        [preview setStickerEditMode:NO];
                    }
                } else {
                    if (status == HTSPlayerStatusPlaying) {
                        AWELogToolInfo2(@"player", AWELogToolTagEdit, @"pause");
                        self.prefersStickerEditMode ? [preview setStickerEditMode:YES] : [preview pause];
                    }
                }
                
            } while (0);
            
            // display pause button only if paused by audio session interruption
            BOOL display = !shouldPlay && self.isAudioSessionInterrupted;
            BOOL success = [self.viewContainer.containerView displayPlayButton:display];
            if (success) {
                [ACCTracker() trackEvent:display ? @"edit_play_button_show" : @"edit_play_button_hide" params:nil];
            }
        });
    }];
}

#pragma mark - Private

- (void)p_addObserver {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:AVAudioSession.sharedInstance];
    [center addObserver:self selector:@selector(handleDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(handleKeyboardUp:) name:UIKeyboardDidShowNotification object:nil];
    [center addObserver:self selector:@selector(handleKeyboardDown:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)p_removeObserver {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - Notifications

- (void)handleInterruption:(NSNotification *)note {
    NSDictionary *info = note.userInfo;
    if (!info || info.count == 0 || !info[AVAudioSessionInterruptionTypeKey]) return;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    NSString *tag = [NSString stringWithFormat:@"system note.%@", note.name];
    switch (type) {
        case AVAudioSessionInterruptionTypeBegan: {
            self.isAudioSessionInterrupted = YES;
            self.prefersStickerEditMode = YES;
            AWELogToolInfo2(tag, AWELogToolTagEdit, @"interruption begin");
            // Interruption began, take appropriate actions (save state, update user interface)
            [self.viewModel setShouldPlay:@NO];
        }
            break;
        case AVAudioSessionInterruptionTypeEnded: {
            self.isAudioSessionInterrupted = NO;
            // Interruption Ended
            AVAudioSessionInterruptionOptions options = [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
            AWELogToolInfo2(tag, AWELogToolTagEdit, @"interruption end, options: %lul", (unsigned long)options);
            if (options & AVAudioSessionInterruptionOptionShouldResume) {
                // playback should resume
                [self.viewModel setShouldPlay:@YES];
            } else {
                // playback should not resume
            }
            self.prefersStickerEditMode = NO;
        }
            break;
        default:
            AWELogToolInfo2(tag, AWELogToolTagEdit, @"unsupported interruption type: %lul", (unsigned long)type);
            break;
    }
}

- (void)handleKeyboardUp:(NSNotification *)note {
    NSString *tag = [NSString stringWithFormat:@"system note.%@", note.name];
    AWELogToolInfo2(tag, AWELogToolTagEdit, @"--------");
    [self.editService.preview disableAutoResume:YES];
}

- (void)handleKeyboardDown:(NSNotification *)note {
    NSString *tag = [NSString stringWithFormat:@"system note.%@", note.name];
    AWELogToolInfo2(tag, AWELogToolTagEdit, @"--------");
    self.isAudioSessionInterrupted = NO;
    self.prefersStickerEditMode = NO;
    [self.editService.preview disableAutoResume:NO];
}

- (void)handleDidBecomeActive:(NSNotification *)note {
    NSString *tag = [NSString stringWithFormat:@"system note.%@", note.name];
    AWELogToolInfo2(tag, AWELogToolTagEdit, @"--------");
    self.isAudioSessionInterrupted = NO;
    self.prefersStickerEditMode = NO;
}

#pragma mark - ACCEditSessionLifeCircleEvent

- (void)executeSceneFirstRenderWithEditService:(id<ACCEditServiceProtocol>)editService
{
    if (!self.editService.mediaContainerView.coverImageView.hidden && self.publishModel.repoContext.videoRecordType != AWEVideoRecordTypeBoomerang) {
        // 鬼畜模式下，先不移除coverImageView
        [self.editService.mediaContainerView.coverImageView removeFromSuperview];
        self.editService.mediaContainerView.coverImageView = nil;
        self.editService.mediaContainerView.coverImageView.hidden = YES;
    }
    AWELogToolInfo2(@"first_frame", AWELogToolTagEdit, @"edit first frame call back excute");
}

- (void)p_getFirstImageForMVVideoWithCompletion:(void (^)(UIImage *image))completion
{
    CGSize videoSize = ACCConfigBool(kConfigBool_enable_1080p_photo_to_video) ? CGSizeMake(1080, 1920) : CGSizeMake(720, 1280);
    [self.editService.captureFrame getProcessedPreviewImageAtTime:0 preferredSize:videoSize compeletion:^(UIImage *image, NSTimeInterval atTime) {
        acc_infra_main_async_safe(^{
            ACCBLOCK_INVOKE(completion, image);
        });
    }];
}

// 拍摄器优化后，视频范围会有不规则扩大，超出的部分需要遮盖掉
- (void)addBottomAdapterMaskIfNeeded
{
    if ([AWEXScreenAdaptManager needAdaptScreen] && (ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize) & ACCViewFrameOptimizeFullDisplay)) {
        CGFloat maskHeight = self.viewContainer.mediaView.acc_height - [AWEXScreenAdaptManager standPlayerFrame].size.height;
        if (maskHeight > 0) {
            UIView *maskView = [[UIView alloc] initWithFrame:CGRectMake(0.f, self.viewContainer.mediaView.acc_height - maskHeight, self.viewContainer.mediaView.acc_width, maskHeight)];
            maskView.backgroundColor = [UIColor blackColor];
            [self.viewContainer.mediaView addSubview:maskView];
        }
    }
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)playStatusChanged:(HTSPlayerStatus)status {
    AWELogToolInfo2(@"player", AWELogToolTagEdit, @"receive player status 【ve】: %@", @(status));
    BOOL isPlaying = status == HTSPlayerStatusPlaying;
    if (isPlaying != self.viewModel.shouldPlay.boolValue) {
        // sync with player status
        AWELogToolInfo2(@"player", AWELogToolTagEdit, @"sync player status: %@", @(status));
        [self.viewModel setShouldPlay:@(isPlaying)];
    }
}

#pragma mark - lazy load

- (AWEVideoPublishViewModel *)publishModel
{
    return self.viewModel.inputData.publishModel;
}

- (ACCEditPlayerViewModel *)viewModel
{
    if (!_viewModel) {
        ACCEditPlayerViewModel *vm = [self.modelFactory createViewModel:ACCEditPlayerViewModel.class];
        NSAssert(vm, @"should not be nil");
        _viewModel = vm;
    }
    return _viewModel;
}

- (id<ACCEditAudioEffectProtocol>)audioEffectService
{
    return self.editService.audioEffect;
}

#pragma mark - SubComponent Visible

- (void)willEnterPublish
{
    self.currentlyOnEditPage = NO;
}

@end
