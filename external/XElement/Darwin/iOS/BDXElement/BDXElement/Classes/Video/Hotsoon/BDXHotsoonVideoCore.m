//
//  BDXHotsoonVideoCore.m
//  BDXElement
//
//  Created by yuanyiyang on 2020/4/23.
//

#import "BDXHotsoonVideoCore.h"
#import "BDXVideoPlayerConfiguration.h"
#import "BDXVideoPlayerVideoModel.h"
#import "BDXVideoManager.h"
#import "BDXLynxVideoView.h"
#import <IESVideoPlayer/IESVideoPlayer.h>

@interface BDXHotsoonVideoCore ()<IESVideoPlayerDelegate>

@property (nonatomic, strong) id<IESVideoPlayerProtocol> player;
@property (nonatomic, strong) BDXVideoPlayerVideoModel *videoModel;
@property (nonatomic, strong) BDXVideoPlayerConfiguration *configuration;
@property (nonatomic, assign) BDXVideoPlayState currentPlayState;

@end

@implementation BDXHotsoonVideoCore

@synthesize delegate;

- (instancetype)initWithFrame:(CGRect)frame configuration:(BDXVideoPlayerConfiguration *)configuration
{
    if (self = [super init]) {
        _configuration = configuration;
        _player = [self __createPlayerWithFrame:frame configuration:configuration];
        _currentPlayState = BDXVideoPlayStateStop;
        _player.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    if ([self.player respondsToSelector:@selector(removeTimeObserver)]) {
        [self.player removeTimeObserver];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id<IESVideoPlayerProtocol>)__createPlayerWithFrame:(CGRect)frame configuration:(BDXVideoPlayerConfiguration *)configuration;
{
    IESVideoPlayerType playerType = configuration.enableTTPlayer ? IESVideoPlayerTypeTTOwn : IESVideoPlayerTypeSystem;
    id<IESVideoPlayerProtocol> player = [IESVideoPlayer playerWithType:playerType];
    player.delegate = self;
    player.useCache = YES;
    player.repeated = configuration.repeated;
    player.mute = configuration.mute;
    player.truncateTailWhenRepeated = YES;
    player.view.backgroundColor = [UIColor blackColor];
    if(configuration.backUIColor){
        player.view.backgroundColor = configuration.backUIColor;
    }
    player.view.clipsToBounds = YES;
    player.view.frame = frame;
    return player;
}

#pragma mark - BDXVideoCorePlayerProtocol

- (UIView *)view
{
    return self.player.view;
}

- (void)setMute:(BOOL)mute
{
    self.player.mute = mute;
}

- (BOOL)mute
{
    return self.player.mute;
}

- (void)setVolume:(CGFloat)volume
{
    self.player.volume = volume;
}

- (CGFloat)volume
{
    return self.player.volume;;
}

- (void)setEnableHardDecode:(BOOL)enableHardDecode
{
    //Not support yet.
}

- (BOOL)enableHardDecode
{
    // Not support yet, return NO as default.
    return NO;
}

- (void)addPeriodicTimeObserverForInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(void))block
{
    [self.player addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:block];
}

- (void)setStartPlayTime:(NSTimeInterval)startTime
{
    // Not support yet.
}

- (void)seekToTime:(NSTimeInterval)timeInSeconds completion:(void (^)(BOOL))completion
{
    [self.player seekToTime:timeInSeconds completion:completion];
}

- (void)play
{
    if (self.currentPlayState == BDXVideoPlayStatePlay) {
        return;
    }
    if (self.currentPlayState == BDXVideoPlayStateStop && self.player.playerType == IESVideoPlayerTypeSystem) {
        [self.player prepareToPlay];
    }
    [self.player play];
    self.currentPlayState = BDXVideoPlayStatePlay;
}

- (void)pause
{
    if (self.currentPlayState == BDXVideoPlayStatePlay) {
        [self.player pause];
        self.currentPlayState = BDXVideoPlayStatePause;
    }
}

- (void)stop
{
    [self.player stop];
    self.currentPlayState = BDXVideoPlayStateStop;
}

- (CVPixelBufferRef)currentPixelBuffer
{
    // Not support yet.
    return NULL;
}

- (NSTimeInterval)currPlaybackTime
{
    return self.player.currPlaybackTime;
}

- (NSTimeInterval)videoDuration
{
    return self.player.videoDuration;
}

- (NSTimeInterval)currPlayableDuration
{
    return self.player.currPlayableDuration;
}

- (void)refreshVideoModel:(BDXVideoPlayerVideoModel *)videoModel
{
    if (!videoModel) {
        return;
    }
    if (videoModel.itemID.length == 0 || videoModel.playUrlString.length == 0) {
        return;
    }
    self.videoModel = videoModel;
    self.player.scalingMode = [self __scaleModeForVideo];
    [self.player resetVideoID:videoModel.itemID andPlayURLs:@[videoModel.playUrlString]];
}

#pragma mark - IESVideoPlayerDelegate

- (void)player:(id<IESVideoPlayerProtocol>)player didChangePlaybackStateWithAction:(IESVideoPlaybackAction)playbackAction
{
    BDXVideoPlaybackAction action = BDXVideoPlaybackActionStart;
    switch (playbackAction) {
        case IESVideoPlaybackActionStart:
        {
            action = BDXVideoPlaybackActionStart;
            self.currentPlayState = BDXVideoPlayStatePlay;
        }
            break;
        case IESVideoPlaybackActionStop:
        {
            action = BDXVideoPlaybackActionStop;
            self.currentPlayState = BDXVideoPlayStateStop;
        }
            break;
        case IESVideoPlaybackActionPause:
        {
            action = BDXVideoPlaybackActionPause;
            self.currentPlayState = BDXVideoPlayStatePause;
        }
            break;
        case IESVideoPlaybackActionResume:
        {
            action = BDXVideoPlaybackActionResume;
            self.currentPlayState = BDXVideoPlayStatePlay;
        }
            break;
        default:
            // enum doesn't match, ignore it.
            return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:didChangePlaybackStateWithAction:)]) {
        [self.delegate bdx_player:self didChangePlaybackStateWithAction:playbackAction];
    }
}

- (void)player:(id<IESVideoPlayerProtocol>)player playbackFailedWithError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:playbackFailedWithError:)]) {
        [self.delegate bdx_player:self playbackFailedWithError:error];
    }
}

- (void)playerDidReadyForDisplay:(id<IESVideoPlayerProtocol>)player
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_playerDidReadyForDisplay:)]) {
        [self.delegate bdx_playerDidReadyForDisplay:self];
    }
}

#pragma mark - Private methods

- (IESVideoScaleMode)__scaleModeForVideo
{
    BDXVideoCustomScaleMode customScaleMode = self.configuration.customScaleMode;
    IESVideoScaleMode scaleMode = IESVideoScaleModeAspectFit;
    switch (customScaleMode) {
        case BDXVideoCustomScaleModeAspectFit:
            scaleMode = IESVideoScaleModeAspectFit;
            break;
        case BDXVideoCustomScaleModeAspectFill:
            scaleMode = IESVideoScaleModeAspectFill;
            break;
        case BDXVideoCustomScaleModeScaleFill:
            scaleMode = IESVideoScaleModeFill;
            break;
        case BDXVideoCustomScaleModeAuto:
            scaleMode = IESVideoScaleModeAspectFit;
            break;
    }
    return scaleMode;
}

@end
