//
//  BDXAwemeVideoCore.m
//  BDXElement
//
//  Created by yuanyiyang on 2020/4/23.
//

#import "BDXAwemeVideoCore.h"
#import <AWERTL/UIView+AWERTL.h>
#import "BDXVideoPlayerConfiguration.h"
#import "BDXVideoPlayerVideoModel.h"
#import "BDXVideoManager.h"
#import <AWEBaseLib/AWEMacros.h>
#import <AWEVideoPlayerWrapper/IESVideoPlayer.h>
#import <AWEVideoPlayer/AWEVideoLogger.h>
#import "BDXElementAdapter.h"
#import "BDXElementToastDelegate.h"
#import "BDXElementVolumeDelegate.h"
#import "BDXElementReportDelegate.h"
#import "BDXElementNetworkDelegate.h"
#import <ByteDanceKit/BTDNetworkUtilities.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import "BDXElementResourceManager.h"
#import <BDWebKit/IESFalconManager.h>
#import "BDXAweVideoPlayerWrapper.h"
#import <IESVideoBitrateSelection/IESVideoBSController.h>

@interface BDXAwemeVideoCore ()<BDXAweVideoPlayerWrapperDelegate>

@property (nonatomic, strong) BDXAweVideoPlayerWrapper *player;
@property (nonatomic, strong) BDXVideoPlayerVideoModel *videoModel;
@property (nonatomic, assign) BDXVideoPlayState currentPlayState;
@property (nonatomic, assign) NSTimeInterval stallStartTimestamp;  // The video is stuck at the point in time. Used to calculate the length of the card
@property (nonatomic, copy) NSString *networkTypeString;

@end

@implementation BDXAwemeVideoCore

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

- (BDXAweVideoPlayerWrapper *)__createPlayerWithFrame:(CGRect)frame configuration:(BDXVideoPlayerConfiguration *)configuration;
{
    BDXAweVideoPlayerWrapper *player = [[BDXAweVideoPlayerWrapper alloc] playerWithOwnPlayer:configuration.enableTTPlayer];
    player.netWorkType = configuration.useTTNetUtility ? IESVideoPlayerNetWorkTypeTTNet : IESVideoPlayerNetWorkTypeUrlSession;
    player.enableHardDecode = configuration.enableHardDecode;
//    player.enableBytevc1Decode = configuration.enableBytevc1Decode;
    player.useCache = YES;
    if (configuration.enableTTPlayer) {
        player.ownPlayerPlayWithURLs = YES;
    }
    player.repeated = configuration.repeated;
    player.mute = configuration.mute;
    player.truncateTailWhenRepeated = YES;
    player.playingWithCache = NO;
    player.useCache = NO;
    player.view.backgroundColor = [UIColor blackColor];
    if(configuration.backUIColor){
        player.view.backgroundColor = configuration.backUIColor;
    }
    player.view.awertl_viewType = AWERTLViewTypeNormal;
    player.view.clipsToBounds = YES;
    player.view.frame = frame;
    [player setTTVideoEngineRenderEngine:TTVideoEngineRenderEngineOpenGLES];
    return player;
}

#pragma mark - BDXVideoCorePlayerProtocol

- (BOOL)isPlaying
{
    return self.currentPlayState == BDXVideoPlayStatePlay;
}

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

- (void)setRepeat:(BOOL)repeat
{
    self.player.repeated = repeat;
}

- (BOOL)repeat
{
    return self.player.repeated;
}

- (void)setVolume:(CGFloat)volume
{
    if ([[BDXElementAdapter sharedInstance].volumeDelegate respondsToSelector:@selector(volumeDidChange:)]) {
        [[BDXElementAdapter sharedInstance].volumeDelegate volumeDidChange:volume];
    }
    self.player.volume = volume;
}

- (CGFloat)volume
{
    return self.player.volume;;
}

- (void)setEnableHardDecode:(BOOL)enableHardDecode
{
    self.player.enableHardDecode = enableHardDecode;
}

- (BOOL)enableHardDecode
{
    return self.player.enableHardDecode;
}

- (void)addPeriodicTimeObserverForInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(void))block
{
    [self.player addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:block];
}

- (void)setStartPlayTime:(NSTimeInterval)startTime
{
    [self.player setStartPlayTime:startTime];
}

- (void)seekToTime:(NSTimeInterval)timeInSeconds completion:(void (^)(BOOL))completion
{
    [self.player prepareToPlay];
    [self.player seekToTime:timeInSeconds completion:completion];
}

- (void)play
{
    if (self.currentPlayState == BDXVideoPlayStatePlay) {
        return;
    }

    if (self.currentPlayState != BDXVideoPlayStatePause) {
        if ([[BDXElementAdapter sharedInstance].reportDelegate respondsToSelector:@selector(startTimingForKey:)]) {
            [[BDXElementAdapter sharedInstance].reportDelegate startTimingForKey:@"%p-FirstFrame"];
        }
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
    return self.player.currentPixelBuffer;
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
    if (videoModel.itemID.length == 0 && videoModel.playUrlString.length == 0) {
        [[BDXElementAdapter sharedInstance].toastDelegate show:BDXElementLocalizedString(BDXElementLocalizedStringKeyErrorOccurred, @"Error occurred. Please try again")];
        return;
    }
    self.videoModel = videoModel;
    self.player.scalingMode = [self __scaleModeForVideo];
    
    @try {
        NSString *md5String = videoModel.playUrlString.btd_md5String;
        if (videoModel.playUrlString.length > 0) {
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
                [self.player resetVideoID:videoModel.itemID ?: md5String andPlayURLs:@[url.absoluteString]];
            } else {
                [self.player resetVideoID:videoModel.itemID ?: md5String andPlayURLs:@[videoModel.playUrlString]];
            }
        } else {
            if (videoModel.apiVersion == BDXVideoPlayerAPIVersion1) {
                [self.player resetVideoID:videoModel.itemID ?: md5String andPlayURLs:@[]];
            } else if (videoModel.apiVersion == BDXVideoPlayerAPIVersion2) {
                [self.player resetVideoID:videoModel.itemID ?: md5String andPlayAuthToken:videoModel.playAutoToken hosts:videoModel.hosts];
            } else {
                [self.player resetVideoID:videoModel.itemID ?: md5String andPlayURLs:@[]];
            }
        }
    } @catch (NSException *exception) {
        
    }

    if ([[BDXElementAdapter sharedInstance].reportDelegate respondsToSelector:@selector(startTimingForKey:)]) {
        [[BDXElementAdapter sharedInstance].reportDelegate startTimingForKey:@"%p-PrepareToPlay"];
    }

    [self.player prepareToPlay];

    NSInteger preloadSize = self.player.cacheSize;
    NSMutableDictionary *video_request_params = [NSMutableDictionary dictionary];
    [video_request_params addEntriesFromDictionary:@{
        @"group_id":self.videoModel.itemID ?: @"",
        @"player_network": [self playerNetworkTypeString],
        @"preload_size" : @(preloadSize/1024)
    }];
    if (self.logExtraDict) {
        [video_request_params addEntriesFromDictionary:self.logExtraDict];
    }

    if ([[BDXElementAdapter sharedInstance].reportDelegate respondsToSelector:@selector(trackEventWithParams:params:)]) {
        [[BDXElementAdapter sharedInstance].reportDelegate trackEventWithParams:@"video_request" params:video_request_params];
    }
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

            NSTimeInterval duration = 0;
            NSTimeInterval prepareDuration = 0;
            if ([[BDXElementAdapter sharedInstance].reportDelegate respondsToSelector:@selector(timeIntervalForKey:)]) {
                duration = [[BDXElementAdapter sharedInstance].reportDelegate timeIntervalForKey:@"%p-FirstFrame"];
                prepareDuration = [[BDXElementAdapter sharedInstance].reportDelegate timeIntervalForKey:@"%p-PrepareToPlay"];
            }
            if ([[BDXElementAdapter sharedInstance].reportDelegate respondsToSelector:@selector(endTimingForKey:service:label:duration:)]) {
                [[BDXElementAdapter sharedInstance].reportDelegate endTimingForKey:@"%p-FirstFrame" service:@"aweme_movie_play" label:@"prepare_time" duration:&duration];
            }
            if ([[BDXElementAdapter sharedInstance].reportDelegate respondsToSelector:@selector(cancelTimingForKey:)]) {
                [[BDXElementAdapter sharedInstance].reportDelegate cancelTimingForKey:@"%p-PrepareToPlay"];
            }

            NSNumber *prepareToPlayDuration = [NSNumber numberWithInt:(prepareDuration - duration)];

            double play_bitrate = self.player.playBitrate;
            NSString *video_fps = [NSString stringWithFormat:@"%.1f",self.player.playFPS];
            NSNumber *durationInInt = [NSNumber numberWithInt:(int)(duration)];
            NSNumber *fe_duration = 0;
            if (self.actionTimestamp) {
                NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970]*1000.0;
                fe_duration = [NSNumber numberWithInt:(currentTimestamp - self.actionTimestamp)];
            }

            NSMutableDictionary *video_play_quality_params = [NSMutableDictionary dictionary];
            [video_play_quality_params addEntriesFromDictionary:@{
                                                                @"video_fps": video_fps,
                                                                @"playerType" : [self playerTypeString],
                                                                @"group_id" : self.videoModel.itemID ?: @"",
                                                                @"duration" : durationInInt,
                                                                @"prepare_duration" : prepareToPlayDuration,
                                                                @"cache_size" : player.cacheSize > 0 ? @(player.cacheSize/1024) : @(-1),
                                                                @"video_duration" : @(player.videoDuration),
                                                                @"play_bitrate" : [NSNumber numberWithInt:play_bitrate],
                                                                @"player_network": [self playerNetworkTypeString],
                                                                @"codec_name" : player.enableHardDecode ? @(1) : @(0),
                                                                @"access" : [self _getVideoPlayAccess],
                                                                @"video_quality" : @([player qualityType]).stringValue,
                                                                @"play_sess": @(player.sessionId),
                                                                @"internet_speed": [IESVideoBSController sharedInstance].enabled ? @([IESVideoBSNetworkProfiler bitrate]) : @(-1),
                                                              }];
            if (self.logExtraDict) {
                [video_play_quality_params addEntriesFromDictionary:self.logExtraDict];
            }
            if (self.actionTimestamp) {
                [video_play_quality_params addEntriesFromDictionary:@{
                    @"fe_duration": fe_duration
                }];
            }

            if ([[BDXElementAdapter sharedInstance].reportDelegate respondsToSelector:@selector(trackEventWithParams:params:)]) {
                [[BDXElementAdapter sharedInstance].reportDelegate trackEventWithParams:@"video_play_quality" params:video_play_quality_params];
            }
        }
            break;
        case IESVideoPlaybackActionStop:
        {
            action = BDXVideoPlaybackActionStop;
            self.currentPlayState = BDXVideoPlayStateStop;
//            [self seekToTime:0 completion:nil];

            NSMutableDictionary *video_play_end_params = [NSMutableDictionary dictionary];
            [video_play_end_params addEntriesFromDictionary:@{
                                                              @"group_id": self.videoModel.itemID ?: @"",
                                                              @"video_duration": @(player.videoDuration * 1000) ?: @(0),
                                                              @"play_duration": @(player.currPlaybackTime * 1000) ?: @(0),
                                                              @"cur_cache_duration": @(player.currPlayableDuration * 1000) ?: @(0),
                                                              @"cache_size": player.cacheSize > 0 ? @(player.cacheSize/1024) : @(-1),
                                                              @"access": [self _getVideoPlayAccess],
                                                              @"player_type": [self playerTypeString]
                                                              }];
            if (self.logExtraDict) {
                [video_play_end_params addEntriesFromDictionary:self.logExtraDict];
            }

            if ([[BDXElementAdapter sharedInstance].reportDelegate respondsToSelector:@selector(trackEventWithParams:params:)]) {
                [[BDXElementAdapter sharedInstance].reportDelegate trackEventWithParams:@"video_play_end" params:video_play_end_params];
            }
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

- (void)playerWillLoopPlaying:(id<IESVideoPlayerProtocol>)player
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_playerWillLoopPlaying:)]) {
        [self.delegate bdx_playerWillLoopPlaying:self];
    }
}

- (void)player:(id<IESVideoPlayerProtocol>)player playbackFailedWithError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:playbackFailedWithError:)]) {
        [self.delegate bdx_player:self playbackFailedWithError:error];
    }
    if (!BTDNetworkConnected()) {
        [[BDXElementAdapter sharedInstance].toastDelegate showError:BDXElementLocalizedString(BDXElementLocalizedStringKeyNetworkError, @"Network error")];
    }

    NSMutableDictionary *video_play_failed_params = [NSMutableDictionary dictionary];
    [video_play_failed_params addEntriesFromDictionary:@{
        @"service"    : @"play_error_detail",
        @"errorCode"  : @(error.code),
        @"errorDesc"  : error.localizedDescription ? : @"",
        @"playerType" : [self playerTypeString],
        @"playURL"    : player.currPlayURL ?: @"",
        @"cache_size" : player.cacheSize > 0 ? @(player.cacheSize/1024) : @(-1),
        @"group_id"   : self.videoModel.itemID ?: @"",
        @"player_network": [self playerNetworkTypeString],
        @"video_quality" : @([player qualityType]).stringValue,
        @"play_sess": @(player.sessionId),
        @"internet_speed": [IESVideoBSController sharedInstance].enabled ? @([IESVideoBSNetworkProfiler bitrate]) : @(-1),
    }];
    if (self.logExtraDict) {
        [video_play_failed_params addEntriesFromDictionary:self.logExtraDict];
    }

    if ([[BDXElementAdapter sharedInstance].reportDelegate respondsToSelector:@selector(trackEventWithParams:params:)]) {
        [[BDXElementAdapter sharedInstance].reportDelegate trackEventWithParams:@"video_play_failed" params:video_play_failed_params];
    }
}

- (void)player:(id<IESVideoPlayerProtocol>)player playbackFailedForURL:(NSString *)URL error:(NSError *)error
{
    AWE_VIDEO_INFO(@"%@ play fail for URL: %@", self.videoModel.itemID, URL);

    NSMutableDictionary *video_play_failed_params = [NSMutableDictionary dictionary];
    [video_play_failed_params addEntriesFromDictionary:@{
        @"service"     : @"play_error_detail_per_url",
        @"errorCode"   : @(error.code),
        @"errorDomain" : error.domain ?: @"",
        @"errorDesc"   : error.description ?: @"",
        @"playerType"  : [self playerTypeString],
        @"playURL"     : URL ?: @"",
        @"cache_size"  : player.cacheSize > 0 ? @(player.cacheSize/1024) : @(-1),
        @"currPlayURL" : player.currPlayURL ?: @"",
        @"group_id"    : self.videoModel.itemID ?: @"",
        @"player_network": [self playerNetworkTypeString],
        @"video_quality" : @([player qualityType]).stringValue,
        @"play_sess": @(player.sessionId),
        @"internet_speed": [IESVideoBSController sharedInstance].enabled ? @([IESVideoBSNetworkProfiler bitrate]) : @(-1),
    }];
    if (self.logExtraDict) {
        [video_play_failed_params addEntriesFromDictionary:self.logExtraDict];
    }

    if ([[BDXElementAdapter sharedInstance].reportDelegate respondsToSelector:@selector(trackEventWithParams:params:)]) {
        [[BDXElementAdapter sharedInstance].reportDelegate trackEventWithParams:@"video_play_failed" params:video_play_failed_params];
    }
}

- (void)playerDidReadyForDisplay:(id<IESVideoPlayerProtocol>)player
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_playerDidReadyForDisplay:)]) {
        [self.delegate bdx_playerDidReadyForDisplay:self];
    }
}

- (void)player:(id<IESVideoPlayerProtocol>)player didChangeStallState:(IESVideoStallAction)stallState
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:didChangeStallState:)]) {
        [self.delegate bdx_player:self didChangeStallState:(BDXVideoStallAction)stallState];
    }
    
    if (stallState == IESVideoStallActionBegin) {
        if (!BTDNetworkConnected()) {
            [[BDXElementAdapter sharedInstance].toastDelegate showError:BDXElementLocalizedString(BDXElementLocalizedStringKeyNetworkError, @"Network error")];
        }

        self.stallStartTimestamp = CACurrentMediaTime();
    }

    if (stallState == IESVideoStallActionEnd) {
        if (self.stallStartTimestamp) {
            NSMutableDictionary *video_block_params = [NSMutableDictionary dictionary];
            [video_block_params addEntriesFromDictionary:@{
                @"duration": @((int)((CACurrentMediaTime() - self.stallStartTimestamp) * 1000)),
                @"end_type": @"resume",
                @"playerType": [self playerTypeString],
                @"group_id": self.videoModel.itemID ?: @"",
                @"cache_size": player.cacheSize > 0 ? @(player.cacheSize/1024) : @(-1),
                @"video_quality" : @([player qualityType]).stringValue,
                @"play_sess": @(player.sessionId),
                @"internet_speed": [IESVideoBSController sharedInstance].enabled ? @([IESVideoBSNetworkProfiler bitrate]) : @(-1),
            }];
            if (self.logExtraDict) {
                [video_block_params addEntriesFromDictionary:self.logExtraDict];
            }

            if ([[BDXElementAdapter sharedInstance].reportDelegate respondsToSelector:@selector(trackEventWithParams:params:)]) {
                [[BDXElementAdapter sharedInstance].reportDelegate trackEventWithParams:@"video_block" params:video_block_params];
            }
            self.stallStartTimestamp = 0;
        }
    }
}

- (void)rereshPlayerScale:(BDXVideoPlayerConfiguration *)config
{
    self.configuration = config;
    self.player.scalingMode = [self __scaleModeForVideo];
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

- (NSString *)playerTypeString
{
    return self.player.playerType == IESVideoPlayerTypeTTOwn ? @"TTPlayer" : @"AVPlayer";
}

- (NSString *)playerNetworkTypeString
{
    if (self.networkTypeString) {
        return self.networkTypeString;
    }

    if ([[BDXElementAdapter sharedInstance].networkDelegate respondsToSelector:@selector(networkTypeString)]) {
        self.networkTypeString = [[BDXElementAdapter sharedInstance].networkDelegate networkTypeString];
    }
    return self.networkTypeString ?: @"";
}

#pragma mark - util

- (NSNumber *)_getVideoPlayAccess
{
    NSInteger accessFlag = 0;
    if (BTDNetworkWifiConnected()) {
        accessFlag = 5;
    } else if (BTDNetwork4GConnected()) {
        accessFlag = 4;
    } else if (BTDNetwork3GConnected()) {
        accessFlag = 3;
    } else if (BTDNetwork2GConnected()) {
        accessFlag = 2;
    } else if (BTDNetworkCellPhoneConnected()) {
        accessFlag = 1;
    }
    return @(accessFlag);
}

@end
