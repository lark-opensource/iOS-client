//
//  TMAVIdeoView.m
//  OPPluginBiz
//
//  Created by muhuai on 2017/12/10.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "TMAVideoView.h"
#import "TMAPlayerModel.h"
#import "TMAPlayerScreenIdleManager.h"
#import "TMAPlayerView.h"
#import <OPFoundation/EEFeatureGating.h>
#import <Masonry/Masonry.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/NSTimer+BDPWeakTarget.h>

@interface TMAVideoView()<TMAPlayerViewDelegate>

@property (nonatomic, strong, readwrite) BDPVideoViewModel *model;
@property (nonatomic, strong) TMAPlayerView *player;
@property (nonatomic, strong) NSTimer *screenAppearenceCheckTimer;

@end

@implementation TMAVideoView

- (void)dealloc
{
    [self.player close];
    [self stopTimer];
}

#pragma mark - BDPVideoViewDelegate

- (instancetype)initWithModel:(BDPVideoViewModel *)model componentID:(NSString *)componentID
{
    self = [super initWithFrame:model.frame];
    if (self) {
        BDPLogInfo(@"initWithModel");
        self.componentID = componentID.copy;
        self.backgroundColor = UIColor.blackColor;

        [self setupViews];
        [self updateWithModel:model];
        [self startTimer];
    }

    return self;
}

- (void)updateWithModel:(BDPVideoViewModel *)model {
    BDPLogInfo(@"updateWithModel, model=%@", [self logParamsWithModel:model]);
    self.hidden = model.hide;
    if (!CGRectIsNull(model.frame)) {
        BDPLogInfo(@"updateWithModel, model.frame is null");
        self.frame = model.frame;
    }

    BOOL autoPlay = !CGRectIsEmpty(model.frame) && model.autoplay;
    if (!BDPIsEmptyString(model.filePath) && ![self.model.filePath isEqualToString:model.filePath]) {
        // 更新了视频
        BDPLogInfo(@"updateWithModel, model.filePath is empty or not equalto ever");
        TMAPlayerModel *playerModel = [self playerModelWithModel:model];
        BOOL changedDataSource = !BDPIsEmptyString(model.filePath);
        [self.player updateWithPlayerModel:playerModel changedDataSource:changedDataSource autoPlay:autoPlay];
        self.model = model;
    } else {
        // 更新了其他属性
        BDPLogInfo(@"updateWithModel, update other property");
        self.model = model;
        self.player.playerModel = [self playerModelWithModel:self.model];
        if (autoPlay) {
            BDPLogInfo(@"updateWithModel, set auto play");
            [self autoPlay];
        }
    }
}

- (CGFloat)currentTime
{
    if (self.player) {
        return self.player.currentSeekTime;
    }
    return 0.f;
}

- (CGFloat)duration
{
    if (self.player) {
        return self.player.totalDuration;
    }
    return 0.f;
}

- (BOOL)fullScreen
{
    return self.player.isFullScreen;
}

- (NSString *)direction
{
    return self.player.fullScreenDirection;
}

- (NSInteger)videoWidth
{
    return self.player.videoWidth;
}

- (NSInteger)videoHeight
{
    return self.player.videoHeight;
}

- (BOOL)muted
{
    return self.player.muted;
}

- (CGFloat)playbackSpeed
{
    return self.player.playbackSpeed;
}

/// 播放
- (void)play {
    BDPLogInfo(@"TMAVideoView play");
    BDPExecuteOnMainQueue(^{
        [self.player play];
    });
}

/// 暂停
- (void)pause
{
    BDPLogInfo(@"TMAVideoView pause");
    [self.player pauseByUser:YES];
}

/// 停止
- (void)stop
{
    BDPLogInfo(@"TMAVideoView stop");
    [self.player pauseByUser:YES];
    WeakSelf;
    [self.player seekToTime:0 completionHandler:^(BOOL success) {
        StrongSelfIfNilReturn
        BDPLogInfo(@"TMAVideoView seek time to zero success %@", @(success));
        if (success && self.delegate && [self.delegate respondsToSelector:@selector(bdp_videoPlayerStateChange:videoPlayer:)]) {
            [self.delegate bdp_videoPlayerStateChange:BDPVideoPlayerStateTimeUpdate videoPlayer:self];
        }
    }];
}

/// 继续
- (void)resume
{
    BDPLogInfo(@"TMAVideoView resume");
    [self.player play];
}

//点播
- (void)seek:(CGFloat)time completion:(void (^)(BOOL))completion
{
    BDPLogInfo(@"TMAVideoView seek time %@", @(time));
    [self.player seekToTime:time completionHandler:^(BOOL success) {
        !completion ?: completion(success);
    }];
}

/// 进入全屏
- (void)enterFullScreen
{
    BDPLogInfo(@"TMAVideoView enterFullScreen");
    [self.player enterFullScreen:YES];
}

/// 退出全屏
- (void)exitFullScreen
{
    BDPLogInfo(@"TMAVideoView exitFullScreen");
    [self.player enterFullScreen:NO];
}

- (void)setPlaybackRate:(CGFloat)rate
{
    BDPLogInfo(@"TMAVideoView setPlaybackRate: %@", @(rate));
    [self.player setPlaybackRate:rate];
}

- (void)viewDidAppear {
    [self startTimer];
}

- (void)viewWillDisappear {
    [self stopTimer];
}

#pragma mark -

- (void)autoPlay
{
    BDPLogInfo(@"TMAVideoView autoPlay");
    // 确保 onVideoPlay 事件在 insertVideoPlayer 之后触发
    dispatch_async(dispatch_get_main_queue(), ^{
        [self play];
    });
}

- (void)setupViews {
    _player = [[TMAPlayerView alloc] init];
    _player.delegate = self;
    _player.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_player];
    [_player mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_offset(UIEdgeInsetsZero);
    }];
}

// buffering and playing are both  state of start playing state
- (BOOL)isStartPlayState:(TMAPlayerState)state {
    BDPLogInfo(@"TMAVideoView isStartPlayState state = %@", @(state));
    return (state == TMAPlayerStateBuffering || state == TMAPlayerStatePlaying);
}

#pragma mark - TMAPlayerViewDelegate

- (void)tma_playerView:(TMAPlayerView *)player playStatuChanged:(TMAPlayerState)state {
    BDPLogInfo(@"TMAVideoView playStatuChanged state = %@", @(state));
    [self notifyEvent:state];
    [self configScreenIdleWith:state];
}

- (void)tma_playerViewFullScreenChanged:(TMAPlayerView *)player
{
    if ([self.delegate respondsToSelector:@selector(bdp_videoPlayerStateChange:videoPlayer:)]) {
        [self.delegate bdp_videoPlayerStateChange:BDPVideoPlayerStateFullScreenChange videoPlayer:self];
    }

    /**
     解决视屏开始播放后, 手动点击全屏按钮进入全屏播放时,会自动息屏问题;
     原因: BDPBaseContainerController的willViewDisapper将UIApplication的IdleTimerDisabled设置了false;
     */
    if (self.fullScreen) {
        BDPExecuteOnMainQueue(^{
            [[TMAPlayerScreenIdleManager shared] idleDisableIfNeed];
        });
    }
}

- (void)tma_playerViewSeekComplete
{
    if ([self.delegate respondsToSelector:@selector(bdp_videoPlayerStateChange:videoPlayer:)]) {
        [self.delegate bdp_videoPlayerStateChange:BDPVideoPlayerStateSeekComplete videoPlayer:self];
    }
}

- (void)tma_playerViewTimeUpdate
{
    if ([self.delegate respondsToSelector:@selector(bdp_videoPlayerStateChange:videoPlayer:)]) {
        [self.delegate bdp_videoPlayerStateChange:BDPVideoPlayerStateTimeUpdate videoPlayer:self];
    }
}

- (void)tma_playerViewControlsToggle:(BOOL)show
{
    if ([self.delegate respondsToSelector:@selector(bdp_videoControlsToggle:)]) {
        [self.delegate bdp_videoControlsToggle:show];
    }
}

- (void)tma_playerViewLoadedMetaData
{
    if ([self.delegate respondsToSelector:@selector(bdp_videoPlayerStateChange:videoPlayer:)]) {
        [self.delegate bdp_videoPlayerStateChange:BDPVideoPlayerStateLoadedMetaData videoPlayer:self];
    }
}

- (void)tma_playerViewError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(bdp_videoError:)]) {
        [self.delegate bdp_videoError:error];
    }
}

- (void)tma_playerViewErrorString:(nonnull NSString *)errorInfo
{
    if ([self.delegate respondsToSelector:@selector(bdp_videoErrorString:)]) {
        [self.delegate bdp_videoErrorString:errorInfo];
    }
}

- (void)tma_playerViewPlaybackRateChanged
{
    if ([self.delegate respondsToSelector:@selector(bdp_videoPlayerStateChange:videoPlayer:)]) {
        [self.delegate bdp_videoPlayerStateChange:BDPVideoPlayerStatePlaybackRateChange videoPlayer:self];
    }
}

- (void)tma_playerViewMuteChanged
{
    if ([self.delegate respondsToSelector:@selector(bdp_videoPlayerStateChange:videoPlayer:)]) {
        [self.delegate bdp_videoPlayerStateChange:BDPVideoPlayerStateMuteChange videoPlayer:self];
    }
}

- (void)tma_playerViewUserAction:(BDPVideoUserAction)action value:(BOOL)value
{
    if ([self.delegate respondsToSelector:@selector(bdp_videoUserAction:value:)]) {
        [self.delegate bdp_videoUserAction:action value:value];
    }
}

#pragma mark - Helper
// 日志
- (NSDictionary *)logParamsWithModel:(BDPVideoViewModel *)model {
    if (model == nil) {
        return [NSDictionary new];
    }
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"filePath"] = model.filePath;
    params[@"videoID"] = [NSString stringWithFormat:@"%@", self.componentID];
    params[@"poster"] = model.poster;

    if (!CGRectIsNull(model.frame)) {
        params[@"frame"] = NSStringFromCGRect(model.frame);;
    }
    return [params copy];
}

- (void)notifyEvent:(TMAPlayerState)state {
    BDPLogInfo(@"TMAVideoView notifyEvent %@", @(state));
    // 播放状态改变触发回调
    BDPVideoPlayerState bdpState = BDPVideoPlayerStateUnknow;
    switch (state) {
        case TMAPlayerStateEnd:
            bdpState = BDPVideoPlayerStateFinished;
            break;
        case TMAPlayerStatePlaying:
            bdpState = BDPVideoPlayerStatePlaying;
            break;
        case TMAPlayerStatePause:
            bdpState = BDPVideoPlayerStatePaused;
            break;
        case TMAPlayerStateBreak:
            bdpState = BDPVideoPlayerStateBreak;
            break;
        case TMAPlayerStateFailed:
            bdpState = BDPVideoPlayerStateError;
            break;
        case TMAPlayerStateBuffering:
            bdpState = BDPVideoPlayerStateWaiting;
            break;
        default:
            break;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdp_videoPlayerStateChange:videoPlayer:)]) {
        [self.delegate bdp_videoPlayerStateChange:bdpState videoPlayer:self];
    }
    // 播放结束延时移除播放器
    if (state == TMAPlayerStateEnd) {
        BDPLogInfo(@"TMAVideoView state == TMAPlayerStateEnd");
        if (_model.loop) {
            [self autoPlay];
        } else {
            WeakSelf;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself.player close];
            });
        }
    }
    
    if (state == TMAPlayerStatePlaying || state == TMAPlayerStateBuffering) {
        [self startTimer];
    } else {
        [self stopTimer];
    }
}

- (void)configScreenIdleWith:(TMAPlayerState)state {
    BDPLogInfo(@"TMAVideoView configScreenIdleWith %@", @(state));
    switch (state) {
        case TMAPlayerStateBuffering:
        case TMAPlayerStatePlaying:
            [[TMAPlayerScreenIdleManager shared] startPlay:self.componentID];
            break;
        case TMAPlayerStateFailed:
        case TMAPlayerStateEnd:
        case TMAPlayerStatePause:
            [[TMAPlayerScreenIdleManager shared] stopPlay:self.componentID];
        default:
            break;
    }
}

- (TMAPlayerModel *)playerModelWithModel:(BDPVideoViewModel *)model {
    TMAPlayerModel *playerModel = [[TMAPlayerModel alloc] init];
    if(!BDPIsEmptyString(model.filePath)) {
        playerModel.videoURL = [NSURL URLWithString:model.filePath];
    }
    playerModel.encryptToken = model.encryptToken;
    playerModel.fatherView = self;
    playerModel.cacheDir = model.cacheDir;
    playerModel.seekTime = model.initialTime;
    playerModel.totalTime = model.duration;
    playerModel.direction = model.direction;
    playerModel.objectFit = model.objectFit;
    playerModel.poster = model.poster;
    playerModel.controls = model.controls;
    playerModel.loop = model.loop;
    playerModel.muted = model.muted;
    playerModel.autoFullscreen = model.autoFullscreen;
    playerModel.showMuteBtn = model.showMuteBtn;
    playerModel.showPlayBtn = model.showPlayBtn;
    playerModel.showFullscreenBtn = model.showFullscreenBtn;
    playerModel.playBtnPosition = model.playBtnPosition;
    playerModel.header = model.header;
    playerModel.title = model.title;
    playerModel.showProgress = model.showProgress;
    playerModel.showBottomProgress = model.showBottomProgress;
    playerModel.showScreenLockButton = model.showScreenLockButton;
    playerModel.showSnapshotButton = model.showSnapshotButton;
    playerModel.showRateButton = model.showRateButton;
    playerModel.enablePlayGesture = model.enablePlayGesture;
    playerModel.enableProgressGesture = model.enableProgressGesture;
    return playerModel;
}

- (void)startTimer {
    if ([EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetVideoDisableAutoPause defaultValue:NO]) {
        return;
    }
    
    BDPLogInfo(@"TMAVideoView start autopause timer");
    [self stopTimer];
    WeakSelf;
    self.screenAppearenceCheckTimer = [NSTimer bdp_scheduledRepeatedTimerWithInterval:0.5 target:self block:^(NSTimer * _Nonnull timer) {
        StrongSelf;
        [self pauseVideoIfOutofScreen];
    }];
}

- (void)stopTimer {
    [self.screenAppearenceCheckTimer invalidate];
    self.screenAppearenceCheckTimer = nil;
}

- (void)pauseVideoIfOutofScreen {
    if (!self.model.autoPauseIfOutsideScreen) {
        return;
    }
    CGRect videoRect = [self convertRect:self.frame toView:nil];
    CGRect screenRect = [UIScreen mainScreen].bounds;
    if (!CGRectIntersectsRect(videoRect, screenRect)) {
        [self pause];
    }
}

@end
