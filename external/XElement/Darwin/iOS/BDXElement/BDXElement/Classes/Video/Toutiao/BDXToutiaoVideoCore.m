//
//  BDXToutiaoVideoCore.m
//  TTLynxAdapter
//
//  Created by jiayuzun on 2020/9/28.
//

#import "BDXToutiaoVideoCore.h"
#import <TTVPlayerPod/TTVPlayer.h>
#import <TTVPlayerPod/TTVPlayer+Engine.h>
#import <TTVPlayerPod/TTVPlayer+Part.h>
#import <TTVPlayerPod/TTVPlayPart.h>
#import <TTVPlayerPod/TTVSeekPart.h>
#import <XElement/BDXVideoPlayerConfiguration.h>
#import <XElement/BDXElementAdapter.h>
#import <XElement/BDXVideoPlayerVideoModel.h>
#import <XElement/BDXElementResourceManager.h>
#import <BDWebKit/IESFalconManager.h>

@interface BDXToutiaoVideoCoreNetworkPart : NSObject <TTVPlayerPartProtocol>

@end

@implementation BDXToutiaoVideoCoreNetworkPart

- (TTVPlayerPartKey)key {
    return TTVPlayerPartKey_NetworkMonitor;
}

@end

@interface BDXToutiaoVideoCore () <TTVPlayerDelegate, TTVPlayerDoubleTapGestureDelegate, TTVPlayerCustomPartDelegate>

@property (nonatomic, strong) TTVPlayer *player;
@property (nonatomic, strong) BDXVideoPlayerVideoModel *videoModel;
@property (nonatomic, assign) BDXVideoPlayState currentPlayState;

//为了适配BDXVideoCorePlayerProtocol添加的属性
@property (nonatomic, assign) BOOL playerEnableHardDecode;
@property (nonatomic, copy) void (^periodicTimeObserverBlock)(void);
@property (nonatomic, strong) dispatch_queue_t periodicTimeObserverQueue;
@property (nonatomic, assign) TTVPlaybackState playbackState;
@property (nonatomic, assign) BOOL hasPlayedOnce;
@property (nonatomic, assign) BOOL isStalling; // 自研播放器在开始播放和卡顿停止时均会改变load state为TTVideoEngineLoadStatePlayable

@end

@implementation BDXToutiaoVideoCore

@synthesize delegate;

- (instancetype)initWithFrame:(CGRect)frame configuration:(BDXVideoPlayerConfiguration *)configuration {
    if (self = [super init]) {
        _configuration = configuration;
        _player = [self __createPlayerWithFrame:frame configuration:configuration];
        _currentPlayState = BDXVideoPlayStateStop;
        _player.delegate = self;
        _hasPlayedOnce = NO;
        _isStalling = NO;
    }
    return self;
}

- (void)dealloc {
    [_player removeTimeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (NSBundle *)resourceBundle {
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundlePath = [[NSBundle bundleForClass:self].resourcePath stringByAppendingPathComponent:@"ToutiaoPlayerResource.bundle"];
        bundle = [NSBundle bundleWithPath:bundlePath];
    });
    return bundle;
}


- (TTVPlayer *)__createPlayerWithFrame:(CGRect)frame configuration:(BDXVideoPlayerConfiguration *)configuration {
    TTVPlayer *player =
        [[TTVPlayer alloc] initWithOwnPlayer:configuration.enableTTPlayer configFileName:@"TTVPlayerStyle-XVideo.plist" bundle:[BDXToutiaoVideoCore resourceBundle]];
    player.customDoubleGestureDelegate = self;
    player.customPartDelegate = self;
    player.enableAudioSession = YES;
    player.showPlaybackControlsOnViewFirstLoaded = NO;
    player.showPlaybackControlsOnVideoFinished = NO;
    player.startPlayFromLastestCache = YES;
    player.supportSeekAfterPlayerFinish = NO;
    player.enableNoPlaybackStatus = YES;
    [player setOptionForKey:VEKKeyCacheCacheEnable_BOOL value:@(YES)];

    //设置硬解
    [player setOptionForKey:VEKKeyPlayerHardwareDecode_BOOL value:@(configuration.enableHardDecode)];
    self.playerEnableHardDecode = configuration.enableHardDecode;

    //设置h265
    [player setOptionForKey:VEKKeyPlayerByteVC1Enabled_BOOL value:@(configuration.enableBytevc1Decode)];
    [player setOptionForKey:VEKKeyPlayerKsyByteVC1Decode_BOOL value:@(configuration.enableBytevc1Decode)];

    //设置循环播放
    [player setOptionForKey:VEKKeyPlayerLooping_BOOL value:@(configuration.repeated)];

    player.muted = configuration.mute;

    player.view.backgroundColor = [UIColor blackColor];
    if (configuration.backUIColor) {
        player.view.backgroundColor = configuration.backUIColor;
    }
    player.view.clipsToBounds = YES;
    player.view.frame = frame;

    //设置渲染方式
    [player setOptionForKey:VEKKeyViewRenderEngine_ENUM value:@(TTVideoEngineRenderEngineMetal)];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopCurrent:)
                                                 name:@"kExploreNeedStopAllMovieViewPlaybackNotification"
                                               object:nil];

    //    [player.playerStore subscribe:self];
    return player;
}

#pragma mark - BDXVideoCorePlayerProtocol

- (BOOL)isPlaying {
    return self.currentPlayState == BDXVideoPlayStatePlay;
}

- (UIView *)view {
    return self.player.view;
}

- (void)setMute:(BOOL)mute {
    self.player.muted = mute;
}

- (BOOL)mute {
    return self.player.muted;
}

- (void)setRepeat:(BOOL)repeat {
    self.player.looping = repeat;
}

- (BOOL)repeat {
    return self.player.looping;
}

- (void)setVolume:(CGFloat)volume {
    if ([[BDXElementAdapter sharedInstance].volumeDelegate respondsToSelector:@selector(volumeDidChange:)]) {
        [[BDXElementAdapter sharedInstance].volumeDelegate volumeDidChange:volume];
    }
    self.player.volume = volume;
}

- (CGFloat)volume {
    return self.player.volume;
}

- (void)setEnableHardDecode:(BOOL)enableHardDecode {
    [self.player setOptionForKey:VEKKeyPlayerHardwareDecode_BOOL value:@(enableHardDecode)];
    self.playerEnableHardDecode = enableHardDecode;
}

- (BOOL)enableHardDecode {
    return self.playerEnableHardDecode;
}

- (void)addPeriodicTimeObserverForInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(void))block {
    // playbackTimeChanged 回调中调用
    self.periodicTimeObserverQueue = queue;
    self.periodicTimeObserverBlock = block;
    [self.player setPlaybackTimeCallbackInterval:interval];
}

- (void)setStartPlayTime:(NSTimeInterval)startTime {
    self.player.startTime = startTime;
}

- (void)seekToTime:(NSTimeInterval)timeInSeconds completion:(void (^)(BOOL))completion {
    [self.player setCurrentPlaybackTime:timeInSeconds complete:completion];
}

- (void)play {
    if (self.currentPlayState == BDXVideoPlayStatePlay) {
        return;
    }
    self.currentPlayState = BDXVideoPlayStatePlay;
    [self.player play];
}

- (void)pause {
    if (self.currentPlayState == BDXVideoPlayStatePlay) {
        self.currentPlayState = BDXVideoPlayStatePause;
        [self.player pause];
    }
}

- (void)stop {
    self.hasPlayedOnce = NO;
    self.currentPlayState = BDXVideoPlayStateStop;
    [self.player stop];
}

- (CVPixelBufferRef)currentPixelBuffer {
    return [self.player copyPixelBuffer];
}

- (NSTimeInterval)currPlaybackTime {
    return self.player.currentPlaybackTime;
}

- (NSTimeInterval)videoDuration {
    return self.player.duration;
}

- (NSTimeInterval)currPlayableDuration {
    return self.player.playableDuration;
}

- (void)refreshVideoModel:(BDXVideoPlayerVideoModel *)videoModel {
    if (!videoModel) {
        return;
    }
    if (videoModel.itemID.length == 0 && videoModel.playUrlString.length == 0) {
        [[BDXElementAdapter sharedInstance].toastDelegate
            show:BDXElementLocalizedString(BDXElementLocalizedStringKeyErrorOccurred, @"Error occurred. Please try again")];
        return;
    }
    self.videoModel = videoModel;
    TTVideoEngineScalingMode scaleMode = [self scaleModeForVideo];
    [self.player setOptions:@{ VEKKEY(VEKKeyViewScaleMode_ENUM) : @(scaleMode) }];
    if (videoModel.itemID) {
        [self.player setVideoID:videoModel.itemID host:nil commonParameters:nil];
    } else if (videoModel.playUrlString.length > 0) {
        NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:videoModel.playUrlString]];
        NSString *localPath = nil;
        if (urlRequest) {
            id<IESFalconMetaData> metaData = [IESFalconManager falconMetaDataForURLRequest:urlRequest];
            SEL filePathsSelector = NSSelectorFromString(@"filePaths");
            if (metaData.falconData.length > 0 && [metaData respondsToSelector:filePathsSelector]) {
                localPath = [(NSArray *)[metaData performSelector:filePathsSelector] firstObject];
            }
        }
        
        if (localPath) {
            NSURL *url = [NSURL fileURLWithPath:localPath];
            [self.player setLocalURL:url.absoluteString];
        } else {
            [self.player setDirectPlayURL:videoModel.playUrlString];
        }
    }
    [self prepareToPlay];
    [self.player prepareToPlay];
}

- (void)rereshPlayerScale:(BDXVideoPlayerConfiguration *)config {
    self.configuration = config;
    TTVideoEngineScalingMode scaleMode = [self scaleModeForVideo];
    [self.player setOptions:@{ VEKKEY(VEKKeyViewScaleMode_ENUM) : @(scaleMode) }];
}

- (BOOL)player:(TTVPlayer*)playerVC didActionDoubleTappedWithState:(TTVPlayerState *)state gesture:(UITapGestureRecognizer *)gesture {
    return YES;
}

#pragma mark - TTVPlayerDelegate

- (void)playerReadyToPlay:(TTVPlayer *)player {
    if (self.hasPlayedOnce) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:didChangePlaybackStateWithAction:)]) {
        [self.delegate bdx_player:self didChangePlaybackStateWithAction:BDXVideoPlaybackActionStart];
    }
}

- (void)player:(TTVPlayer *)player playbackStateDidChanged:(TTVPlaybackState)playbackState {
    switch (playbackState) {
    case TTVPlaybackState_Playing: {
        self.currentPlayState = BDXVideoPlayStatePlay;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kExploreNeedStopAllMovieViewPlaybackNotification" object:self];
        if (self.playbackState == TTVPlaybackState_Paused) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:didChangePlaybackStateWithAction:)]) {
                [self.delegate bdx_player:self didChangePlaybackStateWithAction:BDXVideoPlaybackActionResume];
            }
        }
    } break;
    case TTVPlaybackState_Paused: {
        self.currentPlayState = BDXVideoPlaybackActionPause;
        if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:didChangePlaybackStateWithAction:)]) {
            [self.delegate bdx_player:self didChangePlaybackStateWithAction:BDXVideoPlaybackActionPause];
        }
    } break;
    case TTVPlaybackState_Stopped: { //不能作为判断依据，只用来记录播放器状态
        if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:didChangePlaybackStateWithAction:)]) {
            [self.delegate bdx_player:self didChangePlaybackStateWithAction:BDXVideoPlaybackActionStop];
        }
        self.currentPlayState = BDXVideoPlayStateStop;
    } break;
    default:
        break;
    }
    self.playbackState = playbackState;
}

- (void)player:(TTVPlayer *)player didFinishedWithStatus:(TTVPlayFinishStatus *)finishStatus {
    if (finishStatus.playError || ![finishStatus noErrorStatus]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:playbackFailedWithError:)]) {
            [self.delegate bdx_player:self playbackFailedWithError:finishStatus.playError];
        }
    }
    if (finishStatus.type == TTVPlayFinishStatusType_Finish) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:didChangePlaybackStateWithAction:)]) {
            [self.delegate bdx_player:self didChangePlaybackStateWithAction:BDXVideoPlaybackActionStop];
        }
    }
    if (self.player.looping && finishStatus.type != TTVPlayFinishStatusType_UserFinish) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_playerWillLoopPlaying:)]) {
            [self.delegate bdx_playerWillLoopPlaying:self];
        }
        self.hasPlayedOnce = YES;
    }
}

- (void)player:(TTVPlayer *)player playbackTimeChanged:(TTVPlaybackTime *)playbackTime {
    if (self.periodicTimeObserverQueue && self.periodicTimeObserverBlock) {
        dispatch_async(self.periodicTimeObserverQueue, self.periodicTimeObserverBlock);
    }
}

- (void)playerReadyToDisplay:(TTVPlayer *)player {
    if (self.hasPlayedOnce) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_playerDidReadyForDisplay:)]) {
        [self.delegate bdx_playerDidReadyForDisplay:self];
    }
}

- (void)player:(TTVPlayer *)player loadStateDidChanged:(TTVPlayerDataLoadState)loadState {
    if (!self.isStalling && loadState == TTVPlayerLoadState_Stalled) {
        self.isStalling = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:didChangeStallState:)]) {
            [self.delegate bdx_player:self didChangeStallState:BDXVideoStallActionBegin];
        }
    } else if (self.isStalling && loadState == TTVPlayerLoadState_Playable) {
        self.isStalling = NO;
        if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:didChangeStallState:)]) {
            [self.delegate bdx_player:self didChangeStallState:BDXVideoStallActionBegin];
        }
    }
}

- (void)playerViewDidLayoutSubviews:(TTVPlayer *)player state:(TTVPlayerState *)state {
//    if (!state.fullScreenState.isFullScreen) {
//        [self playerContorlViewNormalStyleNoFull];
//    } else {
//        [self playerContorlViewNormalStyleFull];
//    }
}

- (void)playerDidStartLoading:(TTVPlayer *)player {
    UIView *playCenter = [player partControlForKey:TTVPlayerPartControlKey_PlayCenterToggledButton]; //播放按钮
    playCenter.alpha = 0;
}

- (void)playerDidStopLoading:(TTVPlayer *)player {
    UIView *playCenter = [player partControlForKey:TTVPlayerPartControlKey_PlayCenterToggledButton]; //播放按钮
    playCenter.alpha = 1;
}

- (void)playerWillEnterFullscreen:(TTVPlayer *)player {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:fullScreenAlone:)]) {
        [self.delegate bdx_player:self fullScreenAlone:YES];
    }
}

- (void)playerDidExitFullscreen:(TTVPlayer *)player {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:fullScreenAlone:)]) {
        [self.delegate bdx_player:self fullScreenAlone:NO];
    }
}

- (BOOL)playerPanGesture:(UIPanGestureRecognizer *)panGesture shouldBeginForDirection:(TTVPlayerPanGestureDirection)direction {
    return NO;
}

#pragma mark - TTVPlayerCustomPartDelegate

- (NSObject<TTVPlayerPartProtocol> *)customPartForKey:(TTVPlayerPartKey)key {
    if (key == TTVPlayerPartKey_NetworkMonitor) {
        return [[BDXToutiaoVideoCoreNetworkPart alloc] init];
    }
    return nil;
}

#pragma mark - Private methods

- (void)prepareToPlay {
//    [self configControlViewShadow];

//    TTVPlayPart *playPart = (TTVPlayPart *) [self.player partForKey:TTVPlayerPartKey_Play];
//    UIView<TTVToggledButtonProtocol> *centerPlayButton = playPart.centerPlayButton;
//    [centerPlayButton setAccessibilityLabel:@"播放" forStatus:TTVToggledButtonStatus_Normal];
//    [centerPlayButton setAccessibilityLabel:@"暂停" forStatus:TTVToggledButtonStatus_Toggled];
//    [centerPlayButton setImage:[TTVDemandPlayer playerBundleImageName:@"Play"] forStatus:TTVToggledButtonStatus_Normal];
//    [centerPlayButton setImage:[TTVDemandPlayer playerBundleImageName:@"Pause"] forStatus:TTVToggledButtonStatus_Toggled];
//    [centerPlayButton setFullImage:[TTVDemandPlayer playerBundleImageName:@"Play"] forStatus:TTVToggledButtonStatus_Normal];
//    [centerPlayButton setFullImage:[TTVDemandPlayer playerBundleImageName:@"Pause"] forStatus:TTVToggledButtonStatus_Toggled];
//    ((UIButton *) centerPlayButton).contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
//    ((UIButton *) centerPlayButton).contentVerticalAlignment = UIControlContentVerticalAlignmentFill;

    [self.player.playerAction disableCenterPlayButton:YES];
    [self.player.playerAction showCenterButtonOnFull:NO];
    [self.player.playerAction showBottomBar:NO withAnimation:NO];
    [self.player.playerAction showControlView:NO withAnimation:NO];
    [self.player.playerStore dispatch:[self.player.playerAction enableAutoRotate:NO]];
    [self.player.playerStore dispatch:[self.player.playerAction supportsPortaitFullScreenAction:NO]];
}

//- (void)configControlViewShadow {
//    self.player.controlView.topBar.backgroundImageView.image =
//        [UIImage baselibPlayerBundleClassName:@"TTVPlayerView" bundleName:@"BDTBasePlayerResource" ImageName:@"TopShadow"];
//    self.player.controlView.bottomBar.backgroundImageView.image =
//        [UIImage baselibPlayerBundleClassName:@"TTVPlayerView" bundleName:@"BDTBasePlayerResource" ImageName:@"BottomShadow"];
//}

- (void)stopCurrent:(NSNotification *)notice {
    if (notice.object) {
        if (self == notice.object) {
            return;
        }
    }
    [self pause];
}

- (TTVideoEngineScalingMode)scaleModeForVideo {
    BDXVideoCustomScaleMode customScaleMode = self.configuration.customScaleMode;
    TTVideoEngineScalingMode scaleMode = TTVideoEngineScalingModeAspectFit;
    switch (customScaleMode) {
    case BDXVideoCustomScaleModeAspectFit:
        scaleMode = TTVideoEngineScalingModeAspectFit;
        break;
    case BDXVideoCustomScaleModeAspectFill:
        scaleMode = TTVideoEngineScalingModeAspectFill;
        break;
    case BDXVideoCustomScaleModeScaleFill:
        scaleMode = TTVideoEngineScalingModeFill;
        break;
    case BDXVideoCustomScaleModeAuto:
        scaleMode = TTVideoEngineScalingModeAspectFit;
        break;
    }
    return scaleMode;
}

@end
