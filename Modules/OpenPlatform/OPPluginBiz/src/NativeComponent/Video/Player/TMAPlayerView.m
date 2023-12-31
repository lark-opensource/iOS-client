//
//  TMAPlayerView.m
//  OPPluginBiz
//
//  Created by bupozhuang on 2019/1/3.
//

#import "TMAPlayerView.h"
#import "TMAVideoControlView.h"
#import "TMAVideoOrientationHandler.h"
#import "TMAVideoDefines.h"
#import "TMABrightness.h"
#import <OPFoundation/BDPI18n.h>
#import <TTVideoEngine/TTVideoEngineHeader.h>
#import <TTVideoEngine/TTVideoEnginePlayerDefine.h>
#import "TMAPlayerModel.h"
#import <OPFoundation/EMASandBoxHelper.h>
#import <OPFoundation/NSString+EMA.h>
#import <OPFoundation/EEFeatureGating.h>
#import <OPFoundation/NSTimer+BDPWeakTarget.h>
#import <OPFoundation/BDPUtils.h>
#import <TTPlayerSDK/TTPlayerView.h>
#import <Masonry/Masonry.h>
#import <OPFoundation/BDPNetworking.h>
#import <OPFoundation/BDPNotification.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <VideoToolbox/VTUtilities.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <ECOInfra/ECOInfra-Swift.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"

static const CGFloat kTMAPlayerLowestSpeed = 0.5;
static const CGFloat kTMAPlayerHighestSpeed = 2;

@interface TMAPlayerView() <TTVideoEngineDelegate, TMAVideoControlViewDelegate, OPMediaResourceInterruptionObserver>

@property (nonatomic, strong) TMAVideoControlView *controlView;
@property (nonatomic, strong) TTVideoEngine *videoEngine;
@property (nonatomic, strong) NSTimer *timeUpdateTimer;
@property (nonatomic, weak) UIView *playerView;
@property (nonatomic, strong) id<TMAVideoOrientationDelegate> orientationHandler;
@property (nonatomic, strong) UIImageView *posterImageView;
@property (nonatomic, weak) UDToastForOC *snapshotSavingToast;

/** 是否被用户暂停 */
@property (nonatomic, assign) BOOL isPauseByUser;
/** 是否被页面切换暂停 */
@property (nonatomic, assign) BOOL forcePausedBySwitch;
/** 播发器播放状态 */
@property (nonatomic, assign) TTVideoEnginePlaybackState playbackState;
/** 播发器数据加载状态 */
@property (nonatomic, assign) TTVideoEngineLoadState loadState;
/** 播发器视图状态状态 */
@property (nonatomic, assign) TMAPlayerState state;
/** 播放结束*/
@property (nonatomic, assign) BOOL playDidEnd;
/** 是否锁定屏幕方向 */
@property (nonatomic, assign) BOOL isLocked;
/** 播放的视频URL */
@property (nonatomic, strong) NSURL *videoURL;
/** 是否播放本地文件 */
@property (nonatomic, assign, readonly) BOOL isLocalVideo;
/** 全屏时默认的旋转方向 **/
@property (nonatomic, assign) UIInterfaceOrientation defaultOrientation;
/** 音频 AudioSession 管理对象 */
@property (nonatomic, strong) BDPScenarioObj *scenarioObj;
@property (nonatomic, assign) OPMediaMutexScene mutexScene;
/** 是否首次播放 */
@property (nonatomic, assign) BOOL isFirstPlay;

@end

@implementation TMAPlayerView

@synthesize wrapper = _wrapper;

- (instancetype)init {
    self = [super init];
    if (self) {
        BDPLogInfo(@"TMAPlayerView init");
        // 初始化状态
        [self initializeStatus];
        // 初始化音频管理对象
        [self setupScenario];
        // 添加通知
        [self addNotifications];
        // 添加poster
        [self addPoster];
    }
    return self;
}

- (void)dealloc {
    [self leaveAudioSession];
    [self stopTimer];
}

#pragma mark - layoutSubviews

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerView.frame = self.bounds;
    self.controlView.frame = self.bounds;
    self.posterImageView.frame = self.bounds;
}

#pragma mark - Setup

- (void)setupScenario {
    NSString *name = [NSString stringWithFormat:@"com.player.gadget-%p", self];
    _scenarioObj = [[BDPScenarioObj alloc] initWithName:name
                                               category:AVAudioSessionCategoryPlayback
                                                   mode:AVAudioSessionModeDefault
                                                options:kNilOptions];
}

- (void)initializeStatus {
    _isPauseByUser = YES;
    _defaultOrientation = UIInterfaceOrientationLandscapeRight;
    _state = TMAPlayerStateStopped;
    _loadState = TTVideoEngineLoadStateUnknown;
    _orientationHandler = [TMAVideoOrientationHandler new];
    _orientationHandler.targetView = self;
    self.backgroundColor = [UIColor blackColor];
    _isFirstPlay = YES;
}

- (void)addPoster
{
    BDPLogInfo(@"TMAPlayerView addPoster");
    self.posterImageView = [UIImageView new];
    self.posterImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.posterImageView];
}

- (void)setupPlayer {
    BDPLogInfo(@"TMAPlayerView setupPlayer");
    // 移除其他的video实例
    [[TMAVideoContainer sharedContainer] closeAll];

    // 初始化VideoEngine
    _videoEngine = [[TTVideoEngine alloc] initWithOwnPlayer:YES];
    _videoEngine.delegate = self;
    [self.playerModel.header btd_forEach:^(NSString * _Nonnull key, NSString * _Nonnull obj) {
        [self.videoEngine setCustomHeaderValue:obj forKey:key];
    }];
    [_videoEngine setTag:@"miniapp"];
    [_videoEngine setOptions:[self setupOptions]];
    [self configPlayDataSource];
    self.videoEngine.muted = self.playerModel.muted;

    // 初始化状态
    self.playDidEnd = NO;
    self.isPauseByUser = YES;

    // 添加playerView
    if (self.playerView == nil) {
        [self setupPlayerView];
    }

    [[TMAVideoContainer sharedContainer] addPlayer:self];
}

#pragma mark - LarkMedia
- (NSString *)enterAudioSession {
    NSString* errorInfo = [OPMediaMutex tryLockSyncWithScene:self.mutexScene observer:self];
    if (!BDPIsEmptyString(errorInfo)) {
        BDPLogInfo(@"TMAPlayerView tryLockSyncWithScene fail: %@", errorInfo);
        return errorInfo;
    }
    [BDPAudioSessionProxy entryWithObj:self.scenarioObj scene:self.mutexScene observer:self];
    return nil;
}

- (void)leaveAudioSession {
    [BDPAudioSessionProxy leaveWithObj:self.scenarioObj scene:self.mutexScene wrapper:self.wrapper];
    [OPMediaMutex unlockWithScene:self.mutexScene wrapper:self.wrapper];
}

#pragma mark - OPMediaResourceInterruptionObserver

- (void)mediaResourceWasInterruptedBy:(NSString *)scene msg:(NSString * _Nullable)msg {
    BDPLogInfo(@"TMAPlayerView %@ mediaResourceWasInterruptedBy scene: %@, msg: %@", self, scene, msg ?: @"");
}

- (void)mediaResourceInterruptionEndFrom:(NSString *)scene {
    BDPLogInfo(@"TMAPlayerView %@ mediaResourceInterruptionEndFrom: %@", self, scene);
}

#pragma mark - public

- (void)updateWithPlayerModel:(TMAPlayerModel *)playerModel
            changedDataSource:(BOOL)changedDataSource
                     autoPlay:(BOOL)autoPlay
{
    BDPLogInfo(@"TMAPlayerView updateWithPlayerModel");
    self.playerModel = playerModel;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (changedDataSource) {
            [self close];
            [self configPlayDataSource];
        }
        if (autoPlay) {
            [self play];
        }
    });
}

// 播放
- (void)play
{
    BDPLogInfo(@"TMAPlayerView play ");
    self.playDidEnd = NO;
    if (self.state == TMAPlayerStatePlaying && self.videoEngine) {
        return;
    }
    
    NSString *errorInfo = [self enterAudioSession];
    if (!BDPIsEmptyString(errorInfo)) {
        self.state = TMAPlayerStateFailed;
        if ([self.delegate respondsToSelector:@selector(tma_playerViewErrorString:)]) {
            [self.delegate tma_playerViewErrorString:errorInfo];
        }
        return;
    }
    
    if(self.isFirstPlay && self.playerModel.autoFullscreen) {
        [self enterFullScreen:YES];
        self.isFirstPlay = NO;
    }
    if (self.state != TMAPlayerStatePause) {
        // 暂停时不重置，其它状态需要重置播放状态（controlView.playeEnd = NO）
        [self.controlView tma_playerResetControlView];
    }
    if (_videoEngine == nil) {
        [self setupPlayer];
        // 恢复播放进度
        if (_playerModel.seekTime > 0) {
            [self.videoEngine setOptions:@{VEKKEY(VEKKeyPlayerStartTime_CGFloat): @(_playerModel.seekTime)}];
            [self setupInitailProgressBar:_playerModel];
        }
    }

    [self.controlView tma_playerStartBtnState:YES];
    [self.controlView tma_playerSetRateText:self.videoEngine.playbackSpeed];
    if (!self.isLocalVideo && self.videoEngine.loadState != TTVideoEngineLoadStatePlayable) {
        self.state = TMAPlayerStateBuffering;
    }

    self.isPauseByUser = NO;
    [self.videoEngine play];
    [self.controlView tma_playerHideCenterButton];
    [self.controlView autoFadeOutControlView];
}

// 暂停
- (void)pauseByUser:(BOOL)byUser {
    BDPLogInfo(@"TMAPlayerView pauseByUser %@, state: %@", @(byUser), @(self.state));
    if ((self.state == TMAPlayerStatePlaying || self.state == TMAPlayerStateBuffering) && self.videoEngine) {
        [self.videoEngine pause];
        if (byUser) {
            self.isPauseByUser = YES;
        }
        [self leaveAudioSession];
    }
}

- (void)close {
    BDPLogInfo(@"TMAPlayerView close");
    if (self.videoEngine == nil) {
        return;
    }
    [self destroyVideoEngine];
}

- (void)addPlayerToFatherView {
    BDPLogInfo(@"TMAPlayerView addPlayerToFatherView");
    // 这里应该添加判断，因为view有可能为空，当view为空时[view addSubview:self]会crash
    [self removeFromSuperview];
    if (self.playerModel.fatherView) {
        [self.playerModel.fatherView addSubview:self];
        [self mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_offset(UIEdgeInsetsZero);
        }];
    }
}

- (NSString *)fullScreenDirection
{
    UIInterfaceOrientation orientation = self.defaultOrientation;
    if (self.playerModel.direction) {
        orientation = [self orientaionFromDirection:self.playerModel.direction];
    }
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return @"vertical";
    } else {
        return @"horizontal";
    }
}

- (CGFloat)currentSeekTime
{
    return self.videoEngine.currentPlaybackTime * 1000.0;
}

- (CGFloat)totalDuration
{
    return self.videoEngine.duration * 1000.0;
}

- (NSInteger)videoWidth
{
    return [self.videoEngine getVideoWidth];
}

- (NSInteger)videoHeight
{
    return [self.videoEngine getVideoHeight];
}

- (CGFloat)playbackSpeed
{
    return self.videoEngine.playbackSpeed;
}

/**
 *  从xx秒开始播放视频跳转
 *
 *  @param dragedSeconds 视频跳转的秒数
 */
- (void)seekToTime:(NSTimeInterval)dragedSeconds completionHandler:(void (^)(BOOL success))completionHandler {
    BDPLogInfo(@"TMAPlayerView seekToTime %@", @(dragedSeconds));
    if (dragedSeconds < 0) {
        dragedSeconds = 0;
    } else if (dragedSeconds > self.videoEngine.duration) {
        dragedSeconds = self.videoEngine.duration;
    }
    
    if (self.videoEngine == nil) {
        self.playerModel.seekTime = dragedSeconds;
        !completionHandler ?: completionHandler(YES);
        BDPLogInfo(@"TMAPlayerView seekToTime with videoEngine nil");
        return;
    }
    [self.controlView tma_playerActivity:YES];
    __weak typeof(self) weakSelf = self;
    [self.videoEngine setCurrentPlaybackTime:dragedSeconds complete:^(BOOL success) {
        BDPLogInfo(@"TMAPlayerView seekToTime result %@", @(success));
        [weakSelf.controlView tma_playerDraggedEnd];
        if (success) {
            [weakSelf.controlView tma_playerActivity:NO];
            if ([weakSelf.delegate respondsToSelector:@selector(tma_playerViewSeekComplete)]) {
                [weakSelf.delegate tma_playerViewSeekComplete];
            }
        }
        [weakSelf updateProgressWithEngine:weakSelf.videoEngine isFinished:NO];
        if (completionHandler) {
            completionHandler(success);
        }
    }];
}

- (void)enterFullScreen:(BOOL)enter
{
    BDPLogInfo(@"TMAPlayerView enterFullScreen %@", @(enter));
    if (enter == self.isFullScreen) {
        return;
    }
    [self _fullScreenAction];
}

- (void)setPlaybackRate:(CGFloat)rate
{
    BDPLogInfo(@"TMAPlayerView setPlaybackRate %@", @(rate));
    CGFloat speed = floor(rate * 10) / 10.f;
    if (rate < kTMAPlayerLowestSpeed) {
        speed = kTMAPlayerLowestSpeed;
    } else if (rate > kTMAPlayerHighestSpeed) {
        speed = kTMAPlayerHighestSpeed;
    }
    self.videoEngine.playbackSpeed = speed;
    [self.controlView tma_playerSetRateText:speed];
    if ([self.delegate respondsToSelector:@selector(tma_playerViewPlaybackRateChanged)]) {
        [self.delegate tma_playerViewPlaybackRateChanged];
    }
}

#pragma mark - setter & getter

- (void)setControlView:(TMAVideoControlView *)controlView {
    if (_controlView) { return; }
    _controlView = controlView;
    controlView.tma_delegate = self;
    [self insertSubview:controlView aboveSubview:self.posterImageView];
}

- (void)setPlayerModel:(TMAPlayerModel *)playerModel {
    _playerModel = playerModel;
    NSCAssert(playerModel.fatherView, @"Please specify the superView of the playerView");
    [self.posterImageView ema_setImageWithUrl:playerModel.poster placeHolder:nil];
    if (!self.controlView) {
        self.controlView = [[TMAVideoControlView alloc] init];
    }
    self.controlView.hidden = !(playerModel.controls);
    [self.controlView updateWithPlayerModel:playerModel];
    if (self.superview == nil) {
        [self addPlayerToFatherView];
    }
    self.videoURL = playerModel.videoURL;
    self.muted = playerModel.muted;
    [self.videoEngine setOptions:[self setupOptions]];
}

- (void)setMuted:(BOOL)muted {
    if (_muted == muted) {
        return;
    }
    BDPLogInfo(@"TMAPlayerView setMuted %@", @(muted));
    _muted = muted;
    self.playerModel.muted = muted;
    self.videoEngine.muted = muted;
    [self.controlView tma_playerMuteButtonState:_muted];
    if ([self.delegate respondsToSelector:@selector(tma_playerViewMuteChanged)]) {
        [self.delegate tma_playerViewMuteChanged];
    }
}

- (BOOL)isLocalVideo {
    if ([self.videoURL.scheme isEqualToString:@"file"]) {
        BDPLogInfo(@"TMAPlayerView isLocalVideo true");
        return YES;
    } else {
        BDPLogInfo(@"TMAPlayerView isLocalVideo false");
        return NO;
    }
}
/**
 *  设置播放的状态
 *
 *  @param playbackState TTVideoEnginePlaybackState
 */
- (void)setPlaybackState:(TTVideoEnginePlaybackState)playbackState {
    _playbackState = playbackState;
    BDPLogInfo(@"TMAPlayerView setPlaybackState %@", @(_playbackState));
    switch (playbackState) {
        case TTVideoEnginePlaybackStateError:
            self.state = TMAPlayerStateFailed;
            break;
        case TTVideoEnginePlaybackStatePaused:
            self.state = TMAPlayerStatePause;
            break;
        case TTVideoEnginePlaybackStatePlaying:
            self.state = TMAPlayerStatePlaying;
            break;
        case TTVideoEnginePlaybackStateStopped:
            self.state = TMAPlayerStateStopped;
            break;
    }
}

- (void)setPlayDidEnd:(BOOL)playDidEnd {
    _playDidEnd = playDidEnd;
    BDPLogInfo(@"TMAPlayerView setPlayDidEnd %@", @(playDidEnd));
    if (_playDidEnd) {
        [self updateProgressWithEngine:self.videoEngine isFinished:YES];
        self.state = TMAPlayerStateEnd;
    }
}

- (void)setLoadState:(TTVideoEngineLoadState)loadState {
    BDPLogInfo(@"TMAPlayerView setLoadState %@", @(loadState));
    _loadState = loadState;
    switch (loadState) {
        case TTVideoEngineLoadStateError:
            self.state = TMAPlayerStateFailed;
            break;
        case TTVideoEngineLoadStateStalled:
            self.state = TMAPlayerStateBuffering;
            break;
        case TTVideoEngineLoadStatePlayable: {
            if (self.state == TMAPlayerStateBuffering) {
                self.state = TMAPlayerStatePlaying;
            }
        }
            break;
        case TTVideoEngineLoadStateUnknown:
            break;
    }
}

- (void)setState:(TMAPlayerState)state {
    BDPLogInfo(@"TMAPlayerView setState %@", @(state));
    if (_state == state) {
        return;
    }
    _state = state;
    // 控制菊花显示、隐藏
    [self.controlView tma_playerActivity:state == TMAPlayerStateBuffering];
    if (state == TMAPlayerStateBuffering || state == TMAPlayerStatePlaying) {
        // 隐藏占位图
        [self.controlView tma_playerItemPlaying];
        if (state == TMAPlayerStatePlaying) {
            // 如果playerView是上次destroy videoEngin之前保留的快照，替换为当前videoEngine的playerView
            [self setupPlayerView];
        }
    } else if (state == TMAPlayerStateFailed) {
        [self playFailed];
    } else if (state == TMAPlayerStatePause) {
        [self.controlView tma_playerStartBtnState:NO];
        [self.controlView tma_playerShowControlViewWithAutoFade:NO];
    }
    // 控制poster的显示
    self.posterImageView.hidden = !(state == TMAPlayerStateEnd ||
                                    state == TMAPlayerStateFailed ||
                                    state == TMAPlayerStateStopped ||
                                    state == TMAPlayerStateBreak);
    if (state == TMAPlayerStatePlaying) {
        [self startTimer];
    } else {
        [self stopTimer];
    }
    if ([self.delegate respondsToSelector:@selector(tma_playerView:playStatuChanged:)]) {
        [self.delegate tma_playerView:self playStatuChanged:_state];
    }
}

- (void)setIsFullScreen:(BOOL)isFullScreen {
    BDPLogInfo(@"TMAPlayerView setIsFullScreen %@", @(isFullScreen));
    _isFullScreen = isFullScreen;
    [self.controlView tma_playerBecameFullScreen:isFullScreen];
    if (!isFullScreen) {
        [self exitFulScreenfromLock];
    }
}

#pragma mark - Action

/**
 *  锁定状态下推出全屏
 */
- (void)exitFulScreenfromLock {
    // 调用AppDelegate单例记录播放状态是否锁屏
    if (!TMABrightness.sharedBrightness.isLockScreen) {
        return;
    }
    TMABrightness.sharedBrightness.isLockScreen = NO;
    [self.controlView tma_playerLockBtnState:NO];
    self.isLocked = NO;
}

/** 全屏 */
- (void)_fullScreenAction {
    if (self.isFullScreen) {
        // exit fullscreen
        BDPLogInfo(@"exit fullscreen");
        [self _interfaceOrientation:UIInterfaceOrientationPortrait isFullScreen:NO];
    } else {
        // enter fullscreen
        UIInterfaceOrientation orientation = self.defaultOrientation;
        if (self.playerModel.direction) {
            orientation = [self orientaionFromDirection:self.playerModel.direction];
        }
        BDPLogInfo(@"enter fullscreen with orientation: %@", @(orientation));
        [self _interfaceOrientation:orientation isFullScreen:YES];
    }
}

- (void)_interfaceOrientation:(UIInterfaceOrientation)orientation isFullScreen:(BOOL)isFullScreen
{
    if ([self.orientationHandler respondsToSelector:@selector(interfaceOrientation:isFullScreen:completion:)]) {
        WeakSelf;
        [self.orientationHandler interfaceOrientation:orientation isFullScreen:isFullScreen completion:^(BOOL fullScreen) {
            self.isFullScreen = fullScreen;
            if ([wself.delegate respondsToSelector:@selector(tma_playerViewFullScreenChanged:)]) {
                [wself.delegate tma_playerViewFullScreenChanged:wself];
            }
        }];
    }
}

#pragma mark - Config Control View Status

- (void)startTimer {
    [self stopTimer];
    @weakify(self);
    self.timeUpdateTimer = [NSTimer bdp_scheduledRepeatedTimerWithInterval:0.25 target:self block:^(NSTimer * _Nonnull timer) {
        @strongify(self);
        [self updateProgressWithEngine:self.videoEngine isFinished:NO];
        [self.delegate tma_playerViewTimeUpdate];
    }];
}

- (void)stopTimer
{
    [self.timeUpdateTimer invalidate];
    self.timeUpdateTimer = nil;
}

#pragma mark - TTVideoEngine Delegate

- (void)videoEnginePrepared:(TTVideoEngine *)videoEngine {
    NSTimeInterval totalTime = videoEngine.duration;
    BDPLogInfo(@"video engine prepared, duration: %@", @(totalTime));
    self.playerModel.totalTime = totalTime;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat progress = 0.0;
        if (self.playerModel.seekTime < totalTime) {
            progress = ((CGFloat)self.playerModel.seekTime) / ((CGFloat)totalTime);
        }
        [self.controlView tma_playerCurrentTime:self.playerModel.seekTime
                                      totalTime:totalTime
                                    sliderValue:progress];
    });
    
    if ([self.delegate respondsToSelector:@selector(tma_playerViewLoadedMetaData)]) {
        [self.delegate tma_playerViewLoadedMetaData];
    }
}

- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine error:(NSError *)error {
    if (error) {
        NSMutableDictionary *params = [NSMutableDictionary new];
        params[@"msg"] = error.localizedDescription;
        params[@"url"] = self.videoURL.absoluteString;
        BDPLogError(@"videoFinishError %@", BDPParamStr(params));
        self.state = TMAPlayerStateFailed;
        if ([self.delegate respondsToSelector:@selector(tma_playerViewError:)]) {
            [self.delegate tma_playerViewError:error];
        }
    } else {
        self.playDidEnd = YES;
        [self.controlView tma_playerPlayEnd];
    }
    [self.controlView tma_playerActivity:NO];
    
}

- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine videoStatusException:(NSInteger)status {
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"status"] = [NSString stringWithFormat:@"%@", @(status)];
    params[@"url"] = self.videoURL.absoluteString;
    BDPLogError(@"videoFinishException %@", BDPParamStr(params));
    self.state = TMAPlayerStateFailed;
    
    if ([self.delegate respondsToSelector:@selector(tma_playerViewError:)]) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:status userInfo:nil];
        [self.delegate tma_playerViewError:error];
    }
}

- (void)videoEngine:(TTVideoEngine *)videoEngine playbackStateDidChanged:(TTVideoEnginePlaybackState)playbackState {
    self.playbackState = playbackState;
}

- (void)videoEngine:(TTVideoEngine *)videoEngine loadStateDidChanged:(TTVideoEngineLoadState)loadState {
    if (loadState == TTVideoEngineLoadStateUnknown) {
        return;
    }
    if (loadState == TTVideoEngineLoadStatePlayable) {
        self.defaultOrientation = [self orientationWithEngine:videoEngine];
    }
    self.loadState = loadState;
}

- (void)videoEngineReadyToPlay:(TTVideoEngine *)videoEngine {
    BDPLogInfo(@"video ready to play");
    [self.controlView tma_playerActivity:NO];
}

- (void)videoEngineUserStopped:(TTVideoEngine *)videoEngine {}

- (void)videoEngineCloseAysncFinish:(TTVideoEngine *)videoEngine {}

#pragma mark - TMAVideoControlViewDelegate

- (void)tma_controlView:(UIView *)controlView playAction:(UIButton *)sender isCenter:(BOOL)isCenter {
    BDPVideoUserAction action = isCenter ? BDPVideoUserActionCenterPlay : BDPVideoUserActionPlay;
    if (self.state == TMAPlayerStatePlaying || self.state == TMAPlayerStateBuffering) {
        [self pauseByUser:YES];
        [self notifyUserAction:action value:NO];
    } else {
        [self play];
        [self notifyUserAction:action value:YES];
    }
}

- (void)tma_controlViewBackAction {
    // 旋转
    if (self.isFullScreen) {
        [self _interfaceOrientation:UIInterfaceOrientationPortrait isFullScreen:NO];
    }
    [self notifyUserAction:BDPVideoUserActionBack value:YES];
}

- (void)tma_controlView:(UIView *)controlView fullScreenAction:(UIButton *)sender {
    [self _fullScreenAction];
    [self notifyUserAction:BDPVideoUserActionFullscreen value:!self.isFullScreen];
}

- (void)tma_controlView:(UIView *)controlView isLocked:(BOOL)isLocked {
    self.isLocked = isLocked;
    // 调用AppDelegate单例记录播放状态是否锁屏
    TMABrightness.sharedBrightness.isLockScreen = isLocked;
    if (isLocked || self.state != TMAPlayerStatePause) {
        [self.controlView autoFadeOutControlView];
    }
}

- (void)tma_controlView:(UIView *)controlView muteAction:(UIButton *)sender {
    self.muted = sender.isSelected;
    [self notifyUserAction:BDPVideoUserActionMute value:self.muted];
    [self.controlView autoFadeOutControlView];
}

- (void)tma_controlView:(UIView *)controlView centerStartAction:(UIButton *)sender {
    [self play];
}

- (void)tma_controlViewSnapshotAction {
    self.snapshotSavingToast = [UDToastForOC showLoadingWith:BDPI18n.LittleApp_VideoCompt_Saving on:self.window];
    UIImage *snapShotImage = [self getSnapShotImage];
    UIImageWriteToSavedPhotosAlbum(snapShotImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)tma_repeatPlayAction {
    // 没有播放完
    self.playDidEnd = NO;
    self.playerModel.seekTime = 0;
    [self.controlView tma_playerResetControlView];
    [self.controlView tma_playerHideCenterButton];
    WeakSelf;
    [self seekToTime:0 completionHandler:^(BOOL success) {
        [wself play];
    }];
}

/** 加载失败按钮事件 */
- (void)tma_controlViewRetryAction {
    [self notifyUserAction:BDPVideoUserActionRetry value:YES];
    [self play];
}

- (void)tma_controlView:(UIView *)controlView progressSliderTap:(CGFloat)value {
    // 视频总时间长度
    CGFloat total = self.videoEngine.duration;
    //计算出拖动的当前秒数
    NSInteger dragedSeconds = floorf(total * value);
    self.playerModel.seekTime = dragedSeconds;
    [self seekToTime:dragedSeconds completionHandler:nil];
}

- (void)tma_controlView:(UIView *)controlView progressSliderTouchBegan:(CGFloat)value {
    CGFloat totalTime = self.videoEngine.duration;
    CGFloat draggingTime = floorf(totalTime * value);
    [self.controlView tma_playerDragBegan:draggingTime totalTime:totalTime];
}

- (void)tma_controlView:(UIView *)controlView progressSliderValueChanged:(CGFloat)value {
    CGFloat duration = self.videoEngine.duration;
    CGFloat dragedTime = floorf(duration * value);
    self.playerModel.seekTime = dragedTime;
    [self.controlView tma_playerDraggingTime:dragedTime totalTime:duration];
}

- (void)tma_controlView:(UIView *)controlView progressSliderTouchEnded:(CGFloat)value {
    CGFloat duration = self.videoEngine.duration;
    CGFloat curTime = duration * value;
    self.playerModel.seekTime = curTime;
    [self seekToTime:curTime completionHandler:nil];
}

- (void)tma_controlViewRateAction {
    CGFloat currentSpeed = self.videoEngine.playbackSpeed;
    [self.controlView tma_playerShowRateSelectionPanel:currentSpeed];
}

- (void)tma_controlViewSelectRate:(CGFloat)rate {
    [self setPlaybackRate:rate];
}

- (void)tma_controlViewWillShow:(UIView *)controlView isFullscreen:(BOOL)fullscreen {
    if ([self.delegate respondsToSelector:@selector(tma_playerViewControlsToggle:)]) {
        [self.delegate tma_playerViewControlsToggle:YES];
    }
}

- (void)tma_controlViewWillHidden:(UIView *)controlView isFullscreen:(BOOL)fullscreen {
    if ([self.delegate respondsToSelector:@selector(tma_playerViewControlsToggle:)]) {
        [self.delegate tma_playerViewControlsToggle:NO];
    }
}

- (void)tma_controlViewDoubleTapAction {
    if (self.isPauseByUser) {
        [self play];
    } else {
        [self pauseByUser:YES];
    }
}

#pragma mark - 观察者、通知

/**
 *  添加观察者、通知
 */
- (void)addNotifications {
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground) name:UIApplicationDidBecomeActiveNotification object:nil];
    // 监听耳机插入和拔掉通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
    // 退出小程序
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTimorEnterBackgroundNotification:)
                                                 name:kBDPExitNotification
                                               object:nil];
    // 页面切换
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppPageSwitchNotification:)
                                                 name:kBDPSwitchPageNotification
                                               object:nil];
}

/**
 *  应用退到后台
 */
- (void)appDidEnterBackground {
    BDPLogInfo(@"app enter background, video state: %@", @(self.state));
    // 退到后台锁定屏幕方向
    TMABrightness.sharedBrightness.isLockScreen = YES;
    if ((self.state == TMAPlayerStatePlaying || self.state == TMAPlayerStateBuffering) && self.videoEngine) {
        [self pauseByUser:NO];
    }
}

/**
 *  应用进入前台
 */
- (void)appDidEnterPlayground {
    BDPLogInfo(@"app enter foreground, video state: %@, isPausedByUser: %@, forcePausedBySwitch: %@", @(self.state), @(self.isPauseByUser), @(self.forcePausedBySwitch));
    // 根据是否锁定屏幕方向 来恢复单例里锁定屏幕的方向
    TMABrightness.sharedBrightness.isLockScreen = self.isLocked;
    if (!self.isPauseByUser && self.state == TMAPlayerStatePause && self.videoEngine && self.forcePausedBySwitch == false) {
        [self play];
    }
}

/**
 *  耳机插入、拔出事件
 */
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;

    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];

    BDPLogInfo(@"TMAPlayerView audioRouteChangeListenerCallback routeChangeReason %@", @(routeChangeReason));

    switch (routeChangeReason) {

        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // 耳机插入
            break;

        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable: {
            // 耳机拔掉，继续播放
            if (!self.isPauseByUser) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self play];
                });
            }
        }
            break;

        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            BDPLogInfo(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}

- (void)handleTimorEnterBackgroundNotification:(NSNotification *)notification
{
    BDPLogInfo(@"TMAPlayerView enter background, state: %@", @(self.state));
    [self pauseByUser:NO];
}

- (void)handleAppPageSwitchNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    id pageVC = [userInfo objectForKey:kBDPPageVCKey];
    BOOL isLeaving = [[userInfo objectForKey:kBDPIsPageLeavingKey] boolValue];
    if (pageVC) {
        UIResponder *res = self.nextResponder;
        while (res) {
            if (res == pageVC) {
                BDPLogInfo(@"TMAPlayerView page switch, isLeaving: %@, state: %@", @(isLeaving), @(self.state));
                if (isLeaving && (self.state == TMAPlayerStatePlaying || self.state == TMAPlayerStateBuffering)) {
                    [self pauseByUser:NO];
                    self.forcePausedBySwitch = YES;
                } else {
                    if (self.forcePausedBySwitch) {
                        [self play];
                        self.forcePausedBySwitch = NO;
                    }
                }
                return;
            }
            res = res.nextResponder;
        }
    }
}

#pragma mark - Player Helper

- (void)destroyVideoEngine {
    if (self.videoEngine == nil) {
        return;
    }
    self.playerModel.seekTime = 0;
    [self stopTimer];
    [self.videoEngine close];
    [self.playerView removeFromSuperview];
    self.playerView = nil;
    self.videoEngine = nil;

    if (self.playDidEnd == NO) {
        self.state = TMAPlayerStateBreak;
        [self.controlView tma_playerResetControlView];
    }
    [self leaveAudioSession];
}

- (void)configPlayDataSource
{
    [self configPlayURL:_playerModel.videoURL];
    if (!BDPIsEmptyString(_playerModel.encryptToken)) {
        self.videoEngine.decryptionKey = _playerModel.encryptToken;
    }
}

- (void)configPlayURL:(NSURL *)url {
    if ([url isFileURL]) {
        [self.videoEngine setLocalURL:url.absoluteString];
    } else {
        NSString *cacheFile = [self cacheFileFor:url.absoluteString];
        [self.videoEngine setDirectPlayURL:url.absoluteString cacheFile:cacheFile];
    }
}

- (void)setupPlayerView {
    if (self.playerView == self.videoEngine.playerView) {
        return;
    }
    [self.playerView removeFromSuperview];
    self.playerView = self.videoEngine.playerView;

    [self insertSubview:self.playerView belowSubview:self.posterImageView];
}

- (NSString *)cacheFileFor:(NSString *)videoURL {
    if (self.playerModel.cacheDir == nil || self.playerModel.cacheDir.length == 0) {
        return nil;
    }
    NSString *videoCacheDir = [self.playerModel.cacheDir stringByAppendingPathComponent:@"video"];
    NSFileManager *file = [NSFileManager defaultManager];
    if (![file fileExistsAtPath:videoCacheDir]) {
        NSError *error = nil;
        [file createDirectoryAtPath:videoCacheDir
        withIntermediateDirectories:YES
                         attributes:nil
                              error:&error];
        if (error) {
            return nil;
        }
    }
    NSString *filename = [videoURL ema_md5];
    return [videoCacheDir stringByAppendingPathComponent:filename];
}

// 播放失败UI展示
- (void)playFailed {
    [self.controlView tma_playerItemStatusFailed];
    [self.controlView tma_playerStartBtnState:NO];
    // 失败时也需要隐藏居中按钮
    [self.controlView tma_playerHideCenterButton];
}

// 初始化配置
- (NSDictionary<VEKKeyType, id> *)setupOptions {
    TTVideoEngineScalingMode mode = TTVideoEngineScalingModeAspectFill;
    if ([self.playerModel.objectFit isEqualToString:@"contain"]) {
        mode = TTVideoEngineScalingModeAspectFit;
    } else if ([self.playerModel.objectFit isEqualToString:@"cover"]) {
        mode = TTVideoEngineScalingModeAspectFill;
    } else if ([self.playerModel.objectFit isEqualToString:@"fill"]) {
        mode = TTVideoEngineScalingModeFill;
    }
    NSMutableDictionary *options = @{
        VEKKEY(VEKKeyViewScaleMode_ENUM): @(mode),
        VEKKEY(VEKKeyPlayerHardwareDecode_BOOL): @(YES),
        VEKKEY(VEKKeyCacheCacheEnable_BOOL): @(YES)
    }.mutableCopy;
    if ([EEFeatureGating boolValueForKey: EEFeatureGatingKeyGadgetVideoMetalEnable defaultValue:NO]
        && [TTVideoEngine isSupportMetal]) {
        [options btd_setObject:@(YES) forKey:VEKKEY(VEKKeyPlayerMetalVideoiOSurface)];
        [options btd_setObject:@(TTVideoEngineRenderEngineMetal) forKey:VEKKEY(VEKKeyViewRenderEngine_ENUM)];
    }
    if ([EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetVideoEnableCorrentRealClock defaultValue:NO]) {
        [options btd_setObject:@(YES) forKey:VEKKEY(VEKKeyIsEnableCorrectRealClock_BOOL)];
    }
    
    [options addEntriesFromDictionary:[self getDynamicEngineConfig]];
    
    return options.copy;
}

- (NSDictionary<VEKKeyType, id> *)getDynamicEngineConfig {
    NSMutableDictionary<VEKKeyType, id> *config = [NSMutableDictionary dictionary];
    NSArray<NSDictionary<NSString *, id> *> *dynamicConfig = [ECOSetting gadgetVideoComponentDynamicEngineConfig];
    [dynamicConfig btd_forEach:^(NSDictionary<NSString *,id> * _Nonnull obj) {
        NSInteger key = [obj btd_integerValueForKey:@"key"];
        [config btd_setObject:[obj btd_objectForKey:@"option" default:nil] forKey:VEKKEY(key)];
    }];
    
    return config.copy;
}

// 设置初始化进度条UI
- (void)setupInitailProgressBar:(TMAPlayerModel *)model {
    if (model.seekTime < CGFLOAT_MIN ||
        model.seekTime > model.totalTime ||
        model.totalTime < CGFLOAT_MIN) {
        return;
    }
    NSTimeInterval duration = model.totalTime;
    NSTimeInterval curTime = model.seekTime;
    CGFloat progress = curTime / duration;
    [self.controlView tma_playerCurrentTime:curTime totalTime:duration sliderValue:progress];
    [self.controlView tma_playerSetProgress:progress];
}

// Update Progress With Engine
- (void)updateProgressWithEngine:(TTVideoEngine *)engine isFinished:(BOOL) finished
{
    NSTimeInterval duration = engine.duration;
    NSTimeInterval curTime = engine.currentPlaybackTime;
    NSTimeInterval playableDuration = engine.playableDuration;
    if (duration < CGFLOAT_MIN && self.playerModel.totalTime > 0) {
        return;
    }
    CGFloat progress = curTime / duration;
    CGFloat cacheProgress = playableDuration / duration;
    self.playerModel.seekTime = curTime;
    self.playerModel.totalTime = duration;
    if (finished) {
        progress = 1.0;
        curTime = duration;
        cacheProgress = 1.0;
    }
    [self.controlView tma_playerCurrentTime:curTime totalTime:duration sliderValue:progress];
    [self.controlView tma_playerSetProgress:cacheProgress];
}

// 根据视频Asset获取视频横竖屏方向
- (UIInterfaceOrientation)orientationFrom:(AVURLAsset *)asset {
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (track == nil) {
        return UIInterfaceOrientationLandscapeRight;
    }
    CGSize dimensions = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
    return [self orientationWithWidth:dimensions.width height:dimensions.height];
}

// 从VideoEngine获取视频宽高返回横竖屏默认方向
- (UIInterfaceOrientation)orientationWithEngine:(TTVideoEngine *)engine {
    CGFloat width = [engine getVideoWidth];
    CGFloat height = [engine getVideoHeight];
    return [self orientationWithWidth:width height:height];
}

- (UIInterfaceOrientation)orientationWithWidth:(CGFloat) width height:(CGFloat) height {
    if (width == 0 && height == 0) {
        return UIInterfaceOrientationLandscapeRight;
    }
    if (width > height) {
        return UIInterfaceOrientationLandscapeRight;
    } else {
        return UIInterfaceOrientationPortrait;
    }
}

// 将选择角度转换成InterfaceOrientation
- (UIInterfaceOrientation)orientaionFromDirection:(NSNumber *)direction {
    NSInteger angle = direction.integerValue;
    switch (angle) {
        case 0:
            return UIInterfaceOrientationPortrait;
        case 90:
            return UIInterfaceOrientationLandscapeRight;
        case -90:
            return UIInterfaceOrientationLandscapeLeft;
        default:
            return self.defaultOrientation;
    }
}

- (UIImage *)getSnapShotImage {
    CVPixelBufferRef pixelBuf = [self.videoEngine copyPixelBuffer];
    if (pixelBuf) {
        BDPLogInfo(@"TMAPlayerView snapshot hardware decoding");
        CGImageRef cgImage;
        VTCreateCGImageFromCVPixelBuffer(pixelBuf, nil, &cgImage);
        UIImage *snapShotImage = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        CVPixelBufferRelease(pixelBuf);
        return snapShotImage;
    }
    BDPLogInfo(@"TMAPlayerView snapshot software decoding");
    CGRect frame = self.videoEngine.playerView.bounds;
    UIGraphicsBeginImageContext(frame.size);
    [self.videoEngine.playerView drawViewHierarchyInRect:frame afterScreenUpdates:YES];
    UIImage *snapShotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapShotImage;
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    BDPLogInfo(@"video snapshot, error: %@", error);
    [self.snapshotSavingToast remove];
    if (error) {
        [UDToastForOC showFailureWith:BDPI18n.LittleApp_VideoCompt_SaveFailed on:self.window];
    } else {
        [UDToastForOC showSuccessWith:BDPI18n.LittleApp_VideoCompt_Saved on:self.window];
    }
}

- (void)notifyUserAction:(BDPVideoUserAction)action value:(BOOL)value {
    if ([self.delegate respondsToSelector:@selector(tma_playerViewUserAction:value:)]) {
        [self.delegate tma_playerViewUserAction:action value:value];
    }
}

#pragma clang diagnostic pop

@end
