//Copyright © 2021 Bytedance. All rights reserved.

#import "BDXAweVideoPlayerWrapper.h"
#import <TTVideoEngine/TTVideoEngine.h>
#import <AWEVideoPlayerWrapper/IESOwnPlayerVideoEngineTTNet.h>
#import <AWEVideoPlayerWrapper/IESOwnPlayerApiParser.h>
#import <mach/mach_time.h>

@interface BDXAweVideoPlayerWrapper () <TTVideoEngineDelegate>

@property (nonatomic, strong) TTVideoEngine *player;
@property (nonatomic, assign) NSInteger playbackState;

@property (nonatomic, assign) BOOL isPaused;
@property (nonatomic, assign) BOOL isStalling;
@property (nonatomic, assign) BOOL hasPlayedOnce;
@property (nonatomic, assign) BOOL isURLChanged;
@property (nonatomic, copy) NSArray<NSString *> *videoPlayURLs;
@property (nonatomic, copy) NSString *currPlayURL;

@property (nonatomic, copy) NSString *videoID;
@property (nonatomic, copy) NSString *pToken;
@property (nonatomic, copy) NSString *playAuth;
@property (nonatomic, copy) NSArray<NSString *> *hosts;
@property (nonatomic, copy) NSString *videoRequestUrl;

@property (nonatomic, assign) int playVersion;

@end

@implementation BDXAweVideoPlayerWrapper

- (instancetype)playerWithOwnPlayer:(BOOL)isOwnPlayer {
    _hasPlayedOnce = NO;
    _useCache = YES;
    _playVersion = 1;
    TTVideoEngine *player = [[TTVideoEngine alloc] initWithOwnPlayer:isOwnPlayer];
    player.delegate = self;
    player.looping = YES;
    player.cacheEnable = YES;
    player.dataSource = self;
    player.delegate = self;
    player.internalDelegate = self;
    player.hardwareDecode = YES;
    [player configResolution:TTVideoEngineResolutionTypeFullHD];
    self.player = player;
    return self;
}

- (UIView *)view
{
    return self.player.playerView;
}

- (void)setNetWorkType:(IESVideoPlayerNetWorkType)netWorkType
{
    _netWorkType = netWorkType;

    if (netWorkType == IESVideoPlayerNetWorkTypeUrlSession) {
        _player.netClient = nil;

    } else if (netWorkType == IESVideoPlayerNetWorkTypeTTNet) {
        _player.netClient = [[IESOwnPlayerVideoEngineTTNet alloc] init];
    } else if (netWorkType == IESVideoPlayerNetWorkTypeDashTTNet) {
        _player.netClient = [[IESOwnPlayerDashVideoNetClient alloc] init];
    }
}


- (BOOL)playingWithCache
{
    return self.cacheSize > 0;
}

- (void)setEnableHardDecode:(BOOL)enableHardDecode
{
    self.player.hardwareDecode = enableHardDecode;
}

- (BOOL)enableHardDecode
{
    return self.player.hardwareDecode;
}

- (void)setRepeated:(BOOL)repeated
{
    self.player.looping = repeated;
}

- (void)setMute:(BOOL)mute
{
    self.player.muted = mute;
}

- (void)setTTVideoEngineRenderEngine:(NSUInteger)renderEngineType;
{
   [self.player setOptions:@{VEKKEY(VEKKeyViewRenderEngine_ENUM):@(renderEngineType)}];
}

- (void)removeTimeObserver
{
    [self.player removeTimeObserver];
}

- (void)setScalingMode:(IESVideoScaleMode)scalingMode
{
    _scalingMode = scalingMode;

    switch (scalingMode) {
        case IESVideoScaleModeFill:
            self.player.scaleMode = TTVideoEngineScalingModeFill;
            break;
        case IESVideoScaleModeAspectFit:
            self.player.scaleMode = TTVideoEngineScalingModeAspectFit;
            break;
        case IESVideoScaleModeAspectFill:
            self.player.scaleMode = TTVideoEngineScalingModeAspectFill;
            break;
        default:
            self.player.scaleMode = TTVideoEngineScalingModeNone;
            break;
    }
}

- (void)play
{
    [self prepareToPlay];
    [self.player play];
}


- (void)pause
{
    [self.player pause:YES];
}

- (void)stop
{
    [self.player stop];
    self.hasPlayedOnce = NO;
}

- (void)seekToTime:(NSTimeInterval)timeInSeconds completion:(void(^)(BOOL finished))completion
{
    [self.player setCurrentPlaybackTime:timeInSeconds complete:completion];
}

- (void)addPeriodicTimeObserverForInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(void))block
{
    if (!block) {
        return;
    }

    [self.player addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:block];
}

- (void)setStartPlayTime:(float)time
{
    [self.player setOptionForKey:VEKKeyPlayerStartTime_CGFloat value:@(time)];
}

- (CVPixelBufferRef)currentPixelBuffer
{
    return [self.player copyPixelBuffer];
}

- (NSTimeInterval)currPlaybackTime
{
    return self.player.currentPlaybackTime;
}

- (NSTimeInterval)videoDuration
{
    return self.player.duration;
}

- (NSTimeInterval)currPlayableDuration
{
    return self.player.playableDuration;
}

- (double)playBitrate
{
    NSNumber *num = [self.player getOptionBykey:@(VEKGetKeyPlayerBitrate_LongLong)];
    return num.doubleValue;
}

- (double)playFPS
{
    NSNumber *num = [self.player getOptionBykey:@(VEKGetKeyPlayerVideoOutputFPS_CGFloat)];
    return num.doubleValue;
}

- (NSInteger)qualityType
{
    return [[self.player getOptionBykey:@(VEKKeyCurrentVideoQualityType_NSInteger)] integerValue];
}

- (IESVideoPlayerType)playerType
{
    return IESVideoPlayerTypeTTOwn;
}

- (void)resetVideoID:(NSString *)videoID andPlayURLs:(NSArray<NSString *> *)playURLs
{
    self.isURLChanged = videoID && ![self.videoID isEqualToString:videoID];

    self.videoID = videoID;
    self.videoPlayURLs = playURLs;
    self.currPlayURL = nil;

    if (videoID.length > 0) {
        self.videoRequestUrl = [IESOwnPlayerApiParser urlWithVideoId:videoID];
    }
}

- (void)resetVideoID:(NSString *)videoID andPlayAuthToken:(NSString *)playAuthToken hosts:(NSArray *)hosts {
    self.playAuth = playAuthToken;
    self.videoID = videoID;
    self.hosts = hosts;
    self.playVersion = 2;
}

- (NSArray<NSString *> *)playURLs
{
    return self.videoPlayURLs;
}

- (NSString *)currPlayURL
{
    return self.videoRequestUrl;
}

#pragma mark - Player Actions

- (void)prepareToPlay
{
    [self.player setOptionForKey:VEKKeyPlayerDashEnabled_BOOL value:@(NO)];
    [self.player setOptionForKey:VEKKeyPlayerBashEnabled_BOOL value:@(NO)];
    [self.player setOptionForKey:VEKKeyPlayerCheckHijack_BOOL value:@(NO)];
    
    if (self.playVersion == 1) {
        BOOL wrapperNeedPrepare = self.isURLChanged;
        BOOL valid = self.ownPlayerPlayWithURLs ? (self.videoPlayURLs.count > 0 || self.currPlayURL.length > 0) : (self.videoID.length > 0 || self.currPlayURL.length > 0);
        if (!wrapperNeedPrepare || !valid) {
            return;
        }
        
        self.sessionId = mach_absolute_time();
        
        if (!self.ownPlayerPlayWithURLs) { // use video_id to play
            if (self.videoID.length > 0) {
                if (self.pToken && self.playAuth) {
                    
                    [self.player setOptionForKey:VEKKeyPlayerDashEnabled_BOOL value:@(YES)];
                    [self.player configResolution:TTVideoEngineResolutionTypeFullHD];
                    
                    [self.player setPlayAPIVersion:TTVideoEnginePlayAPIVersion1 auth:self.playAuth];
                }
                self.player.medialoaderEnable = YES;
                self.player.cacheVideoInfoEnable = YES;
                [self.player setVideoID:self.videoID];

                self.isURLChanged = NO;
                [TTVideoEngine ls_getCacheSizeByKey:self.videoID result:^(int64_t size) {
                    self.cacheSize = size;
                }];
                [self.player prepareToPlay];
            }
        } else if (self.ownPlayerPlayWithURLs) { // use urls to play
            if (self.videoPlayURLs.count > 0) {
                self.player.medialoaderEnable = YES;
                self.player.cacheVideoInfoEnable = YES;
                NSString *key = self.videoID;
                [TTVideoEngine ls_getCacheSizeByKey:key result:^(int64_t size) {
                    self.cacheSize = size;
                }];
                [self.player ls_setDirectURLs:self.videoPlayURLs key:key];
                self.isURLChanged = NO;
                [self.player prepareToPlay];
            }
        } else if (self.currPlayURL.length > 0) {
            [self.player setLocalURL:self.currPlayURL];
            self.isURLChanged = NO;
            [self.player prepareToPlay];
        } else {
            // exception
        }
    } else if (self.playVersion == 2) {
        if (self.playAuth.length) {
            // v2
            [self.player setPlayAPIVersion:TTVideoEnginePlayAPIVersion2 auth:nil];
            self.player.medialoaderEnable = YES;
            [self.player setVideoID:self.videoID];
            self.isURLChanged = NO;
            [self.player prepareToPlay];
        }
    }
}


#pragma mark - TTVideoEngineDataSource

- (NSString *)apiForFetcher
{
    return self.videoRequestUrl;
}

- (NSString *)apiForFetcher:(TTVideoEnginePlayAPIVersion)apiVersion
{
    if (apiVersion == TTVideoEnginePlayAPIVersion0) {
    } else if (apiVersion == TTVideoEnginePlayAPIVersion1) {
        return [NSString stringWithFormat:@"%@/video/openapi/v1/?action=GetPlayInfo&video_id=%@&ptoken=%@", nil, self.videoID, self.pToken];
        
    } else if (apiVersion == TTVideoEnginePlayAPIVersion2) {
        return [NSString stringWithFormat:@"https://%@/?%@", self.hosts.firstObject,self.playAuth];;
    }
    
    return self.videoRequestUrl;
}

#pragma mark - TTVideoEngineDelegate

- (void)videoEngine:(TTVideoEngine *)videoEngine playbackStateDidChanged:(TTVideoEnginePlaybackState)playbackState {
    if (!self.isPaused && playbackState == TTVideoEnginePlaybackStatePaused) {
        self.isPaused = YES;
        if ([self.delegate respondsToSelector:@selector(player:didChangePlaybackStateWithAction:)]) {
            [self.delegate player:self didChangePlaybackStateWithAction:IESVideoPlaybackActionPause];
        }
    } else if (self.isPaused && playbackState == TTVideoEnginePlaybackStatePlaying) {
        self.isPaused = NO;
        if ([self.delegate respondsToSelector:@selector(player:didChangePlaybackStateWithAction:)]) {
            [self.delegate player:self didChangePlaybackStateWithAction:IESVideoPlaybackActionResume];
        }
    }
}

- (void)videoEngineReadyToPlay:(TTVideoEngine *)videoEngine {
    if (self.hasPlayedOnce) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(player:didChangePlaybackStateWithAction:)]) {
        [self.delegate player:self didChangePlaybackStateWithAction:IESVideoPlaybackActionStart];
    }
}

- (void)videoEngineUserStopped:(TTVideoEngine *)videoEngine {
    if ([self.delegate respondsToSelector:@selector(player:didChangePlaybackStateWithAction:)]) {
        [self.delegate player:self didChangePlaybackStateWithAction:IESVideoPlaybackActionStop];
    }
}

- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine error:(NSError *)error {
    if (error) {
        // -9990 and -9969 indicate that the dash token is abnormal and needs to be updated and retried at the business layer
        if ((self.playAuth && self.pToken && self.videoID && error.code == TTVideoEngineErrorInvalidRequest) || error.code == TTVideoEngineErrorAuthFail || (self.playAuth && self.pToken && self.videoID && error.code == TTVideoEngineErrorHTTPNot200)) {
            if ([self.delegate respondsToSelector:@selector(player:playbackFailedWithError:)]) {
                [self.delegate player:self playbackFailedWithError:error];
            }
            return;
        }
    }
    
    if (error) {
        if ([self.delegate respondsToSelector:@selector(player:playbackFailedWithError:)]) {
            [self.delegate player:self playbackFailedWithError:error];
        }
    } else {
        if (self.player.looping) {
            if ([self.delegate respondsToSelector:@selector(playerWillLoopPlaying:)]) {
                [self.delegate playerWillLoopPlaying:self];
            }
            self.hasPlayedOnce = YES;
        } else {
            if ([self.delegate respondsToSelector:@selector(player:didChangePlaybackStateWithAction:)]) {
                [self.delegate player:self didChangePlaybackStateWithAction:IESVideoPlaybackActionStop];
            }
        }
    }
}

- (void)videoEngineCloseAysncFinish:(TTVideoEngine *)videoEngine {
    if ([self.delegate respondsToSelector:@selector(player:didChangePlaybackStateWithAction:)]) {
        [self.delegate player:self didChangePlaybackStateWithAction:IESVideoPlaybackActionStop];
    }
}

- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine videoStatusException:(NSInteger)status {
    if ([self.delegate respondsToSelector:@selector(player:playbackFailedWithError:)]) {
        [self.delegate player:self playbackFailedWithError:[self errorWithStatusCode:status]];
    }
}

- (void)videoEngine:(TTVideoEngine *)videoEngine playFailWithURL:(NSString *)URL error:(NSError *)error;
{
    if ([self.delegate respondsToSelector:@selector(player:playbackFailedForURL:error:)]) {
        [self.delegate player:self playbackFailedForURL:URL error:error];
    }
}

- (void)videoEngine:(TTVideoEngine *)videoEngine playFailWithURL:(NSString *)URL statusException:(NSInteger)status;
{
    if ([self.delegate respondsToSelector:@selector(player:playbackFailedForURL:error:)]) {
        [self.delegate player:self playbackFailedForURL:URL error:[self errorWithStatusCode:status]];
    }
}

- (void)videoEngineReadyToDisPlay:(TTVideoEngine *)videoEngine
{
    if (self.hasPlayedOnce) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(playerDidReadyForDisplay:)]) {
        [self.delegate playerDidReadyForDisplay:self];
    }
}

- (void)videoEngine:(TTVideoEngine *)videoEngine loadStateDidChanged:(TTVideoEngineLoadState)loadState
{
    if (!self.isStalling && loadState == TTVideoEngineLoadStateStalled) {
        self.isStalling = YES;
        if ([self.delegate respondsToSelector:@selector(player:didChangeStallState:)]) {
            [self.delegate player:self didChangeStallState:IESVideoStallActionBegin];
        }
    } else if (self.isStalling && loadState == TTVideoEngineLoadStatePlayable) {
        self.isStalling = NO;
        if ([self.delegate respondsToSelector:@selector(player:didChangeStallState:)]) {
            [self.delegate player:self didChangeStallState:IESVideoStallActionEnd];
        }
    }
}


- (NSError *)errorWithStatusCode:(NSInteger)statusCode
{
    NSString *prompts = @"";
    switch (statusCode) {
        case IESOwnPlayerWrapperErrorSucceed:
            return nil;
            break;
        case IESOwnPlayerWrapperErrorWaitForUploading:
            prompts = @"com_video_converting";
            break;
        case IESOwnPlayerWrapperErrorUploadSucceed:
            prompts = @"com_video_converting";
            break;
        case IESOwnPlayerWrapperErrorEncodeFailed:
            prompts = @"com_video_converting";
            break;
        case IESOwnPlayerWrapperErrorEncoding:
            prompts = @"com_video_converting";
            break;
        case IESOwnPlayerWrapperErrorNotExist:
            prompts = @"com_video_deleted_unavailable";
            break;
        case IESOwnPlayerWrapperErrorNotAudited:
            prompts = @"com_video_converting";
            break;
        case IESOwnPlayerWrapperErrorDeleted:
            prompts = @"com_video_deleted_unavailable";
            break;
        default:
            prompts = @"com_mig_unknown_error";
            break;
    }
    return [NSError errorWithDomain:@"com.IESVideoPlayer.TTOwn.ErrorDomain" code:statusCode userInfo:@{@"message":prompts?:@"", @"prompts":prompts?:@""}];
}

#pragma mark - Properties In Protocol

@synthesize useCache = _useCache;
@synthesize ownPlayerPlayWithURLs = _ownPlayerPlayWithURLs;
@synthesize playingWithCache = _playingWithCache;
@synthesize scalingMode = _scalingMode;

@end
