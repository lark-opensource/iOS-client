//
//  BDXAwemeVideoCore.m
//  BDXElement
//
//  Created by yuanyiyang on 2020/4/23.
//

#import "BDXLVVideoCore.h"
#import "BDXVideoPlayerConfiguration.h"
#import "BDXVideoPlayerVideoModel.h"
#import <TTVideoEngine/TTVideoEngineHeader.h>
#import <ByteDanceKit/BTDMacros.h>

@interface BDXLVVideoCore ()<TTVideoEngineDelegate>
@property (nonatomic, strong) TTVideoEngine *videoEngine;
@property (nonatomic, strong) BDXVideoPlayerVideoModel *videoModel;
@property (nonatomic, strong) BDXVideoPlayerConfiguration *configuration;
@property (nonatomic, assign) BDXVideoPlayState currentPlayState;
       
@end


@implementation BDXLVVideoCore

@synthesize delegate;

- (instancetype)initWithFrame:(CGRect)frame configuration:(BDXVideoPlayerConfiguration *)configuration
{
    if (self = [super init]) {
        _configuration = configuration;
        _videoEngine = [self __createPlayerWithFrame:frame configuration:configuration];
        _currentPlayState = BDXVideoPlayStateStop;
        _videoEngine.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    if ([self.videoEngine respondsToSelector:@selector(removeTimeObserver)]) {
        [self.videoEngine removeTimeObserver];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (TTVideoEngine *)__createPlayerWithFrame:(CGRect)frame configuration:(BDXVideoPlayerConfiguration *)configuration;
{
    TTVideoEngine *player = [[TTVideoEngine alloc] initWithOwnPlayer: YES];
    player.hardwareDecode = configuration.enableHardDecode;
    player.cacheEnable = YES;
    player.looping = configuration.repeated;
    player.muted = configuration.mute;
    player.playerView.backgroundColor = [UIColor blackColor];
    if(configuration.backUIColor){
        player.playerView.backgroundColor = configuration.backUIColor;
    }
    player.playerView.clipsToBounds = YES;
    player.playerView.frame = frame;
    return player;
}

#pragma mark - BDXVideoCorePlayerProtocol

- (UIView *)view
{
    return self.videoEngine.playerView;
}

- (void)setMute:(BOOL)mute
{
    self.videoEngine.muted = mute;
}

- (BOOL)mute
{
    return self.videoEngine.muted;
}

- (void)setRepeat:(BOOL)repeat
{
    self.videoEngine.looping = repeat;
}

- (BOOL)repeat
{
    return self.videoEngine.looping;
}

- (void)setVolume:(CGFloat)volume
{
    self.videoEngine.volume = volume;
}

- (CGFloat)volume
{
    return self.videoEngine.volume;
}

- (void)setEnableHardDecode:(BOOL)enableHardDecode
{
    self.videoEngine.hardwareDecode = enableHardDecode;
}

- (BOOL)enableHardDecode
{
    return self.videoEngine.hardwareDecode;
}

- (void)addPeriodicTimeObserverForInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(void))block
{
    [self.videoEngine addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:block];
}

- (void)setStartPlayTime:(NSTimeInterval)startTime
{
    self.videoEngine.startTime = startTime;
}

- (void)seekToTime:(NSTimeInterval)timeInSeconds completion:(void (^)(BOOL))completion
{
    
    [self.videoEngine prepareToPlay];
    [self.videoEngine setCurrentPlaybackTime:timeInSeconds complete:completion];
}

- (void)play
{
    if (self.currentPlayState == BDXVideoPlayStatePlay) {
        return;
    }
    if (self.currentPlayState == BDXVideoPlayStateStop) {
        [self.videoEngine prepareToPlay];
    }
    [self.videoEngine play];
    self.currentPlayState = BDXVideoPlayStatePlay;
}

- (void)pause
{
    if (self.currentPlayState == BDXVideoPlayStatePlay) {
        [self.videoEngine pause];
        self.currentPlayState = BDXVideoPlayStatePause;
    }
}

- (void)stop
{
    [self.videoEngine stop];
    self.currentPlayState = BDXVideoPlayStateStop;
}

- (CVPixelBufferRef)currentPixelBuffer
{
    return self.videoEngine.copyPixelBuffer;
}

- (NSTimeInterval)currPlaybackTime
{
    return self.videoEngine.currentPlaybackTime;
}

- (NSTimeInterval)videoDuration
{
    return self.videoEngine.duration;
}

- (NSTimeInterval)currPlayableDuration
{
    return self.videoEngine.playableDuration;
}

- (void)refreshVideoModel:(BDXVideoPlayerVideoModel *)videoModel
{
    if (!videoModel) {
        return;
    }
    if (videoModel.itemID.length == 0 && videoModel.playUrlString.length == 0) {
        //TODO: hanzheng
//        [AWEToast show:@"视频操作失败，请稍后再试"];
        return;
    }
    self.videoModel = videoModel;
    @try {
        [self.videoEngine setDirectPlayURL:videoModel.playUrlString];
        if (!BTD_isEmptyString(videoModel.itemID) ) {
            [self.videoEngine setVideoID: videoModel.itemID];
        }
    } @catch (NSException *exceptxion) {
        
    }
    [self.videoEngine prepareToPlay];

}

#pragma mark - TTVideoEngineDelegate
/**
 playback state change callback

 @param videoEngine videoEngine
 @param playbackState playbackState
 */
- (void)videoEngine:(TTVideoEngine *)videoEngine playbackStateDidChanged:(TTVideoEnginePlaybackState)playbackState {
    BDXVideoPlaybackAction action = BDXVideoPlaybackActionStart;
    switch (playbackState) {
        case TTVideoEnginePlaybackStatePlaying:
            break;
        case TTVideoEnginePlaybackStatePaused:
            action = BDXVideoPlayStatePause;
            break;
        case TTVideoEnginePlaybackStateError:
            action = BDXVideoPlaybackActionPause;
            break;
        case TTVideoEnginePlaybackStateStopped:
            action = BDXVideoPlaybackActionPause;
            break;
        default:
            break;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:didChangePlaybackStateWithAction:)]) {
        [self.delegate bdx_player:self didChangePlaybackStateWithAction:action];
    }
}

- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine error:(nullable NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:playbackFailedWithError:)]) {
        [self.delegate bdx_player:self playbackFailedWithError:error];
    }
    //TODO: hanzheng
//    if (!BTDNetworkConnected()) {
//        [AWEToast showError:@"当前网络不可用"];
//    }
}

- (void)videoEngineReadyToPlay:(TTVideoEngine *)videoEngine {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_playerDidReadyForDisplay:)]) {
        [self.delegate bdx_playerDidReadyForDisplay:self];
    }
}

- (void)videoEngineStalledExcludeSeek:(TTVideoEngine *)videoEngine {
    //TODO: hanzheng
//    if (!BTDNetworkConnected()) {
//        [AWEToast showError:@"当前网络不可用"];
//    }
}


@end
