// Copyright 2021 The Lynx Authors. All rights reserved.

#import "BDXLynxFlowerVideoCore.h"
#import <ByteDanceKit/BTDNetworkUtilities.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <TTVideoEngine/TTVideoEngineHeader.h>
#import "BDXElementAdapter.h"
#import "BDXElementNetworkDelegate.h"
#import "BDXElementReportDelegate.h"
#import "BDXElementResourceManager.h"
#import "BDXElementToastDelegate.h"
#import "BDXElementVolumeDelegate.h"
#import "BDXLynxFlowerVideoDefines.h"
#import "BDXLynxFlowerVideoPlayerConfiguration.h"
#import "BDXLynxFlowerVideoPlayerVideoModel.h"

@interface BDXLynxFlowerVideoCore () <TTVideoEngineDataSource, TTVideoEngineDelegate>

@property(nonatomic, strong) TTVideoEngine *player;
@property(nonatomic, strong) BDXLynxFlowerVideoPlayerVideoModel *videoModel;
@property(nonatomic, assign) BDXLynxFlowerVideoPlayState currentPlayState;
@property(nonatomic, assign)
    NSTimeInterval stallStartTimestamp;  // The video is stuck at the point in time. Used to
                                         // calculate the length of the card
@property(nonatomic, copy) NSString *networkTypeString;

// player
@property(nonatomic, assign) BOOL ownPlayerPlayWithURLs;
@property(nonatomic, assign) BOOL isPaused;
@property(nonatomic, assign) BOOL isStalling;
@property(nonatomic, assign) BOOL hasPlayedOnce;
@property(nonatomic, assign) BOOL isURLChanged;
@property(nonatomic, copy) NSArray<NSString *> *videoPlayURLs;
@property(nonatomic, copy) NSString *currPlayURL;

@property(nonatomic, copy) NSString *videoID;
@property(nonatomic, copy) NSString *pToken;
@property(nonatomic, copy) NSString *playAuth;
@property(nonatomic, copy) NSArray<NSString *> *hosts;
@property(nonatomic, assign) NSInteger cacheSize;
@property(nonatomic, assign) int playVersion;

@end

@implementation BDXLynxFlowerVideoCore

@synthesize delegate;

- (instancetype)initWithFrame:(CGRect)frame
                configuration:(BDXLynxFlowerVideoPlayerConfiguration *)configuration {
  if (self = [super init]) {
    _configuration = configuration;
    if (configuration.enableTTPlayer) {
      _ownPlayerPlayWithURLs = YES;
    }
    _hasPlayedOnce = NO;
    _playVersion = 1;
    _player = [self __createPlayerWithFrame:frame configuration:configuration];
    _currentPlayState = BDXLynxFlowerVideoPlayStateStop;
    _player.delegate = self;
  }
  return self;
}

- (void)dealloc {
  if ([self.player respondsToSelector:@selector(removeTimeObserver)]) {
    [self.player removeTimeObserver];
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (TTVideoEngine *)__createPlayerWithFrame:(CGRect)frame
                             configuration:(BDXLynxFlowerVideoPlayerConfiguration *)configuration;
{
  TTVideoEngine *player = [[TTVideoEngine alloc] initWithOwnPlayer:configuration.enableTTPlayer];
  player.netClient = nil;
  player.hardwareDecode = YES;
  player.playerView.backgroundColor = [UIColor blackColor];
  player.looping = YES;
  player.cacheEnable = YES;
  player.dataSource = self;
  player.delegate = self;
  [player configResolution:TTVideoEngineResolutionTypeFullHD];
  player.playerView.frame = frame;
  player.looping = configuration.repeated;
  player.muted = configuration.mute;
  if (configuration.backUIColor) {
    player.playerView.backgroundColor = configuration.backUIColor;
  }
  player.playerView.clipsToBounds = YES;
  [player setOptions:@{VEKKEY(VEKKeyViewRenderEngine_ENUM) : @(TTVideoEngineRenderEngineOpenGLES)}];
  return player;
}

#pragma mark - Player Actions

- (void)prepareToPlay {
  [self.player setOptionForKey:VEKKeyPlayerDashEnabled_BOOL value:@(NO)];
  [self.player setOptionForKey:VEKKeyPlayerBashEnabled_BOOL value:@(NO)];
  [self.player setOptionForKey:VEKKeyPlayerCheckHijack_BOOL value:@(NO)];

  if (self.playVersion == 1) {
    BOOL wrapperNeedPrepare = self.isURLChanged;
    BOOL valid = self.ownPlayerPlayWithURLs
                     ? (self.videoPlayURLs.count > 0 || self.currPlayURL.length > 0)
                     : (self.videoID.length > 0 || self.currPlayURL.length > 0);
    if (!wrapperNeedPrepare || !valid) {
      return;
    }

    if (self.ownPlayerPlayWithURLs) {  // use urls to play
      if (self.videoPlayURLs.count > 0) {
        self.player.medialoaderEnable = YES;
        self.player.cacheVideoInfoEnable = YES;
        NSString *key = self.videoID;
        [TTVideoEngine ls_getCacheSizeByKey:key
                                     result:^(int64_t size) {
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

- (void)resetVideoID:(NSString *)videoID andPlayURLs:(NSArray<NSString *> *)playURLs {
  self.isURLChanged = videoID && ![self.videoID isEqualToString:videoID];

  self.videoID = videoID;
  self.videoPlayURLs = playURLs;
  self.currPlayURL = nil;
}

- (void)resetVideoID:(NSString *)videoID
    andPlayAuthToken:(NSString *)playAuthToken
               hosts:(NSArray *)hosts {
  self.playAuth = playAuthToken;
  self.videoID = videoID;
  self.hosts = hosts;
  self.playVersion = 2;
}

#pragma mark - BDXVideoCorePlayerProtocol

- (BOOL)isPlaying {
  return self.currentPlayState == BDXLynxFlowerVideoPlayStatePlay;
}

- (UIView *)view {
  return self.player.playerView;
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
  if ([[BDXElementAdapter sharedInstance].volumeDelegate
          respondsToSelector:@selector(volumeDidChange:)]) {
    [[BDXElementAdapter sharedInstance].volumeDelegate volumeDidChange:volume];
  }
  self.player.volume = volume;
}

- (CGFloat)volume {
  return self.player.volume;
  ;
}

- (void)setEnableHardDecode:(BOOL)enableHardDecode {
  self.player.hardwareDecode = enableHardDecode;
}

- (BOOL)enableHardDecode {
  return self.player.hardwareDecode;
}

- (void)addPeriodicTimeObserverForInterval:(NSTimeInterval)interval
                                     queue:(dispatch_queue_t)queue
                                usingBlock:(void (^)(void))block {
  [self.player addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:block];
}

- (void)setStartPlayTime:(NSTimeInterval)startTime {
  [self.player setOptionForKey:VEKKeyPlayerStartTime_CGFloat value:@(startTime)];
}

- (void)seekToTime:(NSTimeInterval)timeInSeconds completion:(void (^)(BOOL))completion {
  [self prepareToPlay];
  [self.player setCurrentPlaybackTime:timeInSeconds complete:completion];
}

- (void)play {
  if (self.currentPlayState == BDXLynxFlowerVideoPlayStatePlay) {
    return;
  }

  if (self.currentPlayState != BDXLynxFlowerVideoPlayStatePause) {
    if ([[BDXElementAdapter sharedInstance].reportDelegate
            respondsToSelector:@selector(startTimingForKey:)]) {
      [[BDXElementAdapter sharedInstance].reportDelegate startTimingForKey:@"%p-FirstFrame"];
    }
  }

  [self.player play];
  self.currentPlayState = BDXLynxFlowerVideoPlayStatePlay;
}

- (void)pause {
  if (self.currentPlayState == BDXLynxFlowerVideoPlayStatePlay) {
    [self.player pause];
    self.currentPlayState = BDXLynxFlowerVideoPlayStatePause;
  }
}

- (void)stop {
  [self.player stop];
  self.currentPlayState = BDXLynxFlowerVideoPlayStateStop;
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

- (void)refreshVideoModel:(BDXLynxFlowerVideoPlayerVideoModel *)videoModel {
  if (!videoModel) {
    return;
  }
  if (videoModel.itemID.length == 0 && videoModel.playUrlString.length == 0) {
    [[BDXElementAdapter sharedInstance].toastDelegate
        show:BDXElementLocalizedString(BDXElementLocalizedStringKeyErrorOccurred,
                                       @"Error occurred. Please try again")];
    return;
  }
  self.videoModel = videoModel;
  self.player.scaleMode = [self __scaleModeForVideo];

  @try {
    NSString *md5String = videoModel.playUrlString.btd_md5String;
    if (videoModel.playUrlString.length > 0) {
      __weak __typeof(self) weakSelf = self;
      void (^block)(void) = ^(void) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }
        [strongSelf resetVideoID:videoModel.itemID ?: md5String
                     andPlayURLs:@[ videoModel.playUrlString ]];
      };

      if ([self.delegate respondsToSelector:@selector(bdx_player:
                                                fetchByResourceManager:completionHandler:)]) {
        [self.delegate bdx_player:self
            fetchByResourceManager:[NSURL URLWithString:videoModel.playUrlString]
                 completionHandler:^(NSURL *_Nonnull localUrl, NSURL *_Nonnull remoteUrl,
                                     NSError *_Nullable error) {
                   __strong __typeof(weakSelf) strongSelf = weakSelf;
                   if (error) {
                     block();
                     return;
                   }
                   if (localUrl) {
                     [strongSelf resetVideoID:videoModel.itemID ?: md5String
                                  andPlayURLs:@[ localUrl.absoluteString ]];
                   } else if (remoteUrl) {
                     [strongSelf resetVideoID:videoModel.itemID ?: md5String
                                  andPlayURLs:@[ remoteUrl.absoluteString ]];
                   } else {
                     block();
                   }
                 }];
      } else {
        block();
      }
    } else {
      if (videoModel.apiVersion == BDXLynxFlowerVideoPlayerAPIVersion1) {
        [self resetVideoID:videoModel.itemID ?: md5String andPlayURLs:@[]];
      } else if (videoModel.apiVersion == BDXLynxFlowerVideoPlayerAPIVersion2) {
        [self resetVideoID:videoModel.itemID ?: md5String
            andPlayAuthToken:videoModel.playAutoToken
                       hosts:videoModel.hosts];
      } else {
        [self resetVideoID:videoModel.itemID ?: md5String andPlayURLs:@[]];
      }
    }
  } @catch (NSException *exception) {
  }

  if ([[BDXElementAdapter sharedInstance].reportDelegate
          respondsToSelector:@selector(startTimingForKey:)]) {
    [[BDXElementAdapter sharedInstance].reportDelegate startTimingForKey:@"%p-PrepareToPlay"];
  }

  [self prepareToPlay];

  NSInteger preloadSize = self.cacheSize;
  NSMutableDictionary *video_request_params = [NSMutableDictionary dictionary];
  [video_request_params addEntriesFromDictionary:@{
    @"group_id" : self.videoModel.itemID ?: @"",
    @"player_network" : [self playerNetworkTypeString],
    @"preload_size" : @(preloadSize / 1024)
  }];
  if (self.logExtraDict) {
    [video_request_params addEntriesFromDictionary:self.logExtraDict];
  }

  if ([[BDXElementAdapter sharedInstance].reportDelegate
          respondsToSelector:@selector(trackEventWithParams:params:)]) {
    [[BDXElementAdapter sharedInstance].reportDelegate trackEventWithParams:@"video_request"
                                                                     params:video_request_params];
  }
}

#pragma mark - TTVideoEngineDataSource

- (NSString *)apiForFetcher:(TTVideoEnginePlayAPIVersion)apiVersion {
  if (apiVersion == TTVideoEnginePlayAPIVersion0) {
  } else if (apiVersion == TTVideoEnginePlayAPIVersion1) {
    return
        [NSString stringWithFormat:@"%@/video/openapi/v1/?action=GetPlayInfo&video_id=%@&ptoken=%@",
                                   nil, self.videoID, self.pToken];

  } else if (apiVersion == TTVideoEnginePlayAPIVersion2) {
    return [NSString stringWithFormat:@"https://%@/?%@", self.hosts.firstObject, self.playAuth];
    ;
  }

  return nil;
}

#pragma mark - TTVideoEngineDelegate

- (void)videoEngine:(TTVideoEngine *)videoEngine
    playbackStateDidChanged:(TTVideoEnginePlaybackState)playbackState {
  if (!self.isPaused && playbackState == TTVideoEnginePlaybackStatePaused) {
    self.isPaused = YES;
    [self player:videoEngine
        didChangePlaybackStateWithAction:BDXLynxFlowerVideoPlaybackActionPause];
  } else if (self.isPaused && playbackState == TTVideoEnginePlaybackStatePlaying) {
    self.isPaused = NO;
    [self player:videoEngine
        didChangePlaybackStateWithAction:BDXLynxFlowerVideoPlaybackActionResume];
  }
}

- (void)videoEngineReadyToPlay:(TTVideoEngine *)videoEngine {
  if (self.hasPlayedOnce) {
    return;
  }
  [self player:videoEngine didChangePlaybackStateWithAction:BDXLynxFlowerVideoPlaybackActionStart];
}

- (void)videoEngineUserStopped:(TTVideoEngine *)videoEngine {
  [self player:videoEngine didChangePlaybackStateWithAction:BDXLynxFlowerVideoPlaybackActionStop];
}

- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine error:(NSError *)error {
  if (error) {
    // -9990 and -9969 indicate that the dash token is abnormal and needs to be updated and retried
    // at the business layer
    if ((self.playAuth && self.pToken && self.videoID &&
         error.code == TTVideoEngineErrorInvalidRequest) ||
        error.code == TTVideoEngineErrorAuthFail ||
        (self.playAuth && self.pToken && self.videoID &&
         error.code == TTVideoEngineErrorHTTPNot200)) {
      [self player:videoEngine playbackFailedWithError:error];
      return;
    }
  }

  if (error) {
    [self player:videoEngine playbackFailedWithError:error];
  } else {
    if (self.player.looping) {
      [self playerWillLoopPlaying:videoEngine];
      self.hasPlayedOnce = YES;
    } else {
      [self player:videoEngine
          didChangePlaybackStateWithAction:BDXLynxFlowerVideoPlaybackActionStop];
    }
  }
}

- (void)videoEngineCloseAysncFinish:(TTVideoEngine *)videoEngine {
  [self player:videoEngine didChangePlaybackStateWithAction:BDXLynxFlowerVideoPlaybackActionStop];
}

- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine videoStatusException:(NSInteger)status {
  [self player:videoEngine playbackFailedWithError:[self errorWithStatusCode:status]];
}

- (void)videoEngine:(TTVideoEngine *)videoEngine
    playFailWithURL:(NSString *)URL
              error:(NSError *)error;
{ [self player:videoEngine playbackFailedForURL:URL error:error]; }

- (void)videoEngine:(TTVideoEngine *)videoEngine
    playFailWithURL:(NSString *)URL
    statusException:(NSInteger)status;
{ [self player:videoEngine playbackFailedForURL:URL error:[self errorWithStatusCode:status]]; }

- (void)videoEngineReadyToDisPlay:(TTVideoEngine *)videoEngine {
  if (self.hasPlayedOnce) {
    return;
  }
  [self playerDidReadyForDisplay:videoEngine];
}

- (void)videoEngine:(TTVideoEngine *)videoEngine
    loadStateDidChanged:(TTVideoEngineLoadState)loadState {
  if (!self.isStalling && loadState == TTVideoEngineLoadStateStalled) {
    self.isStalling = YES;
    [self player:videoEngine didChangeStallState:BDXLynxFlowerVideoStallActionBegin];
  } else if (self.isStalling && loadState == TTVideoEngineLoadStatePlayable) {
    self.isStalling = NO;
    [self player:videoEngine didChangeStallState:BDXLynxFlowerVideoStallActionEnd];
  }
}

- (NSError *)errorWithStatusCode:(NSInteger)statusCode {
  NSString *prompts = @"";
  switch (statusCode) {
    case BDXLynxFlowerVideoErrorSucceed:
      return nil;
      break;
    case BDXLynxFlowerVideoErrorWaitForUploading:
      prompts = @"com_video_converting";
      break;
    case BDXLynxFlowerVideoErrorUploadSucceed:
      prompts = @"com_video_converting";
      break;
    case BDXLynxFlowerVideoErrorEncodeFailed:
      prompts = @"com_video_converting";
      break;
    case BDXLynxFlowerVideoErrorEncoding:
      prompts = @"com_video_converting";
      break;
    case BDXLynxFlowerVideoErrorNotExist:
      prompts = @"com_video_deleted_unavailable";
      break;
    case BDXLynxFlowerVideoErrorNotAudited:
      prompts = @"com_video_converting";
      break;
    case BDXLynxFlowerVideoErrorDeleted:
      prompts = @"com_video_deleted_unavailable";
      break;
    default:
      prompts = @"com_mig_unknown_error";
      break;
  }
  return [NSError errorWithDomain:@"com.lynxxvideo.flower.ErrorDomain"
                             code:statusCode
                         userInfo:@{@"message" : prompts ?: @"", @"prompts" : prompts ?: @""}];
}

#pragma mark - TTVideoEngine

- (void)player:(TTVideoEngine *)player
    didChangePlaybackStateWithAction:(BDXLynxFlowerVideoPlaybackAction)playbackAction {
  BDXLynxFlowerVideoPlaybackAction action = BDXLynxFlowerVideoPlaybackActionStart;
  switch (playbackAction) {
    case BDXLynxFlowerVideoPlaybackActionStart: {
      action = BDXLynxFlowerVideoPlaybackActionStart;
      self.currentPlayState = BDXLynxFlowerVideoPlayStatePlay;

      NSTimeInterval duration = 0;
      NSTimeInterval prepareDuration = 0;
      if ([[BDXElementAdapter sharedInstance].reportDelegate
              respondsToSelector:@selector(timeIntervalForKey:)]) {
        duration =
            [[BDXElementAdapter sharedInstance].reportDelegate timeIntervalForKey:@"%p-FirstFrame"];
        prepareDuration = [[BDXElementAdapter sharedInstance].reportDelegate
            timeIntervalForKey:@"%p-PrepareToPlay"];
      }
      if ([[BDXElementAdapter sharedInstance].reportDelegate
              respondsToSelector:@selector(endTimingForKey:service:label:duration:)]) {
        [[BDXElementAdapter sharedInstance].reportDelegate endTimingForKey:@"%p-FirstFrame"
                                                                   service:@"aweme_movie_play"
                                                                     label:@"prepare_time"
                                                                  duration:&duration];
      }
      if ([[BDXElementAdapter sharedInstance].reportDelegate
              respondsToSelector:@selector(cancelTimingForKey:)]) {
        [[BDXElementAdapter sharedInstance].reportDelegate cancelTimingForKey:@"%p-PrepareToPlay"];
      }

      NSNumber *prepareToPlayDuration = [NSNumber numberWithInt:(prepareDuration - duration)];

      NSNumber *play_bitrateNum = [self.player getOptionBykey:@(VEKGetKeyPlayerBitrate_LongLong)];
      NSNumber *playFPSNum = [self.player getOptionBykey:@(VEKGetKeyPlayerVideoOutputFPS_CGFloat)];
      double play_bitrate = [play_bitrateNum doubleValue];
      NSString *video_fps = [NSString stringWithFormat:@"%.1f", playFPSNum.doubleValue];
      NSNumber *durationInInt = [NSNumber numberWithInt:(int)(duration)];
      NSNumber *fe_duration = 0;
      if (self.actionTimestamp) {
        NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970] * 1000.0;
        fe_duration = [NSNumber numberWithInt:(currentTimestamp - self.actionTimestamp)];
      }

      NSMutableDictionary *video_play_quality_params = [NSMutableDictionary dictionary];
      [video_play_quality_params addEntriesFromDictionary:@{
        @"video_fps" : video_fps,
        @"playerType" : [self playerTypeString],
        @"group_id" : self.videoModel.itemID ?: @"",
        @"duration" : durationInInt,
        @"prepare_duration" : prepareToPlayDuration,
        @"cache_size" : self.cacheSize > 0 ? @(self.cacheSize / 1024) : @(-1),
        @"video_duration" : @(self.videoDuration),
        @"play_bitrate" : [NSNumber numberWithInt:play_bitrate],
        @"player_network" : [self playerNetworkTypeString],
        @"codec_name" : self.enableHardDecode ? @(1) : @(0),
        @"access" : [self _getVideoPlayAccess]
      }];
      if (self.logExtraDict) {
        [video_play_quality_params addEntriesFromDictionary:self.logExtraDict];
      }
      if (self.actionTimestamp) {
        [video_play_quality_params addEntriesFromDictionary:@{@"fe_duration" : fe_duration}];
      }

      if ([[BDXElementAdapter sharedInstance].reportDelegate
              respondsToSelector:@selector(trackEventWithParams:params:)]) {
        [[BDXElementAdapter sharedInstance].reportDelegate
            trackEventWithParams:@"video_play_quality"
                          params:video_play_quality_params];
      }
    } break;
    case BDXLynxFlowerVideoPlaybackActionStop: {
      action = BDXLynxFlowerVideoPlaybackActionStop;
      self.currentPlayState = BDXLynxFlowerVideoPlayStateStop;
      //            [self seekToTime:0 completion:nil];

      NSMutableDictionary *video_play_end_params = [NSMutableDictionary dictionary];
      [video_play_end_params addEntriesFromDictionary:@{
        @"group_id" : self.videoModel.itemID ?: @"",
        @"video_duration" : @(self.videoDuration * 1000) ?: @(0),
        @"play_duration" : @(self.currPlaybackTime * 1000) ?: @(0),
        @"cur_cache_duration" : @(self.currPlayableDuration * 1000) ?: @(0),
        @"cache_size" : self.cacheSize > 0 ? @(self.cacheSize / 1024) : @(-1),
        @"access" : [self _getVideoPlayAccess],
        @"player_type" : [self playerTypeString]
      }];
      if (self.logExtraDict) {
        [video_play_end_params addEntriesFromDictionary:self.logExtraDict];
      }

      if ([[BDXElementAdapter sharedInstance].reportDelegate
              respondsToSelector:@selector(trackEventWithParams:params:)]) {
        [[BDXElementAdapter sharedInstance].reportDelegate
            trackEventWithParams:@"video_play_end"
                          params:video_play_end_params];
      }
    } break;
    case BDXLynxFlowerVideoPlaybackActionPause: {
      action = BDXLynxFlowerVideoPlaybackActionPause;
      self.currentPlayState = BDXLynxFlowerVideoPlayStatePause;
    } break;
    case BDXLynxFlowerVideoPlaybackActionResume: {
      action = BDXLynxFlowerVideoPlaybackActionResume;
      self.currentPlayState = BDXLynxFlowerVideoPlayStatePlay;
    } break;
    default:
      // enum doesn't match, ignore it.
      return;
  }
  if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:
                                                             didChangePlaybackStateWithAction:)]) {
    [self.delegate bdx_player:self didChangePlaybackStateWithAction:playbackAction];
  }
}

- (void)playerWillLoopPlaying:(TTVideoEngine *)player {
  if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_playerWillLoopPlaying:)]) {
    [self.delegate bdx_playerWillLoopPlaying:self];
  }
}

- (void)player:(TTVideoEngine *)player playbackFailedWithError:(NSError *)error {
  if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:
                                                             playbackFailedWithError:)]) {
    [self.delegate bdx_player:self playbackFailedWithError:error];
  }
  if (!BTDNetworkConnected()) {
    [[BDXElementAdapter sharedInstance].toastDelegate
        showError:BDXElementLocalizedString(BDXElementLocalizedStringKeyNetworkError,
                                            @"Network error")];
  }

  NSMutableDictionary *video_play_failed_params = [NSMutableDictionary dictionary];
  [video_play_failed_params addEntriesFromDictionary:@{
    @"service" : @"play_error_detail",
    @"errorCode" : @(error.code),
    @"errorDesc" : error.localizedDescription ?: @"",
    @"playerType" : [self playerTypeString],
    @"playURL" : self.currPlayURL ?: @"",
    @"cache_size" : self.cacheSize > 0 ? @(self.cacheSize / 1024) : @(-1),
    @"group_id" : self.videoModel.itemID ?: @"",
    @"player_network" : [self playerNetworkTypeString]
  }];
  if (self.logExtraDict) {
    [video_play_failed_params addEntriesFromDictionary:@{
      @"enter_from" : self.logExtraDict[@"enter_from"] ?: @"",
      @"bundle" : self.logExtraDict[@"bundle"] ?: @""
    }];
  }

  if ([[BDXElementAdapter sharedInstance].reportDelegate
          respondsToSelector:@selector(trackEventWithParams:params:)]) {
    [[BDXElementAdapter sharedInstance].reportDelegate
        trackEventWithParams:@"video_play_failed"
                      params:video_play_failed_params];
  }
}

- (void)player:(TTVideoEngine *)player playbackFailedForURL:(NSString *)URL error:(NSError *)error {
  NSMutableDictionary *video_play_failed_params = [NSMutableDictionary dictionary];
  [video_play_failed_params addEntriesFromDictionary:@{
    @"service" : @"play_error_detail_per_url",
    @"errorCode" : @(error.code),
    @"errorDomain" : error.domain ?: @"",
    @"errorDesc" : error.description ?: @"",
    @"playerType" : [self playerTypeString],
    @"playURL" : URL ?: @"",
    @"cache_size" : self.cacheSize > 0 ? @(self.cacheSize / 1024) : @(-1),
    @"currPlayURL" : self.currPlayURL ?: @"",
    @"group_id" : self.videoModel.itemID ?: @"",
    @"player_network" : [self playerNetworkTypeString]
  }];
  if (self.logExtraDict) {
    [video_play_failed_params addEntriesFromDictionary:@{
      @"enter_from" : self.logExtraDict[@"enter_from"] ?: @"",
      @"bundle" : self.logExtraDict[@"bundle"] ?: @""
    }];
  }

  if ([[BDXElementAdapter sharedInstance].reportDelegate
          respondsToSelector:@selector(trackEventWithParams:params:)]) {
    [[BDXElementAdapter sharedInstance].reportDelegate
        trackEventWithParams:@"video_play_failed"
                      params:video_play_failed_params];
  }
}

- (void)playerDidReadyForDisplay:(TTVideoEngine *)player {
  if (self.delegate &&
      [self.delegate respondsToSelector:@selector(bdx_playerDidReadyForDisplay:)]) {
    [self.delegate bdx_playerDidReadyForDisplay:self];
  }
}

- (void)player:(TTVideoEngine *)player
    didChangeStallState:(BDXLynxFlowerVideoStallAction)stallState {
  if (self.delegate && [self.delegate respondsToSelector:@selector(bdx_player:
                                                             didChangeStallState:)]) {
    [self.delegate bdx_player:self didChangeStallState:stallState];
  }

  if (stallState == BDXLynxFlowerVideoStallActionBegin) {
    if (!BTDNetworkConnected()) {
      [[BDXElementAdapter sharedInstance].toastDelegate
          showError:BDXElementLocalizedString(BDXElementLocalizedStringKeyNetworkError,
                                              @"Network error")];
    }

    self.stallStartTimestamp = CACurrentMediaTime();
  }

  if (stallState == BDXLynxFlowerVideoStallActionEnd) {
    if (self.stallStartTimestamp) {
      NSMutableDictionary *video_block_params = [NSMutableDictionary dictionary];
      [video_block_params addEntriesFromDictionary:@{
        @"duration" : @((int)((CACurrentMediaTime() - self.stallStartTimestamp) * 1000)),
        @"end_type" : @"resume",
        @"playerType" : [self playerTypeString],
        @"group_id" : self.videoModel.itemID ?: @"",
        @"cache_size" : self.cacheSize > 0 ? @(self.cacheSize / 1024) : @(-1)
      }];
      if (self.logExtraDict) {
        [video_block_params addEntriesFromDictionary:@{
          @"enter_from" : self.logExtraDict[@"enter_from"] ?: @"",
          @"bundle" : self.logExtraDict[@"bundle"] ?: @""
        }];
      }

      if ([[BDXElementAdapter sharedInstance].reportDelegate
              respondsToSelector:@selector(trackEventWithParams:params:)]) {
        [[BDXElementAdapter sharedInstance].reportDelegate trackEventWithParams:@"video_block"
                                                                         params:video_block_params];
      }
      self.stallStartTimestamp = 0;
    }
  }
}

- (void)rereshPlayerScale:(BDXLynxFlowerVideoPlayerConfiguration *)config {
  self.configuration = config;
  self.player.scaleMode = [self __scaleModeForVideo];
}

#pragma mark - Private methods

- (TTVideoEngineScalingMode)__scaleModeForVideo {
  BDXLynxFlowerVideoCustomScaleMode customScaleMode = self.configuration.customScaleMode;
  TTVideoEngineScalingMode scaleMode = TTVideoEngineScalingModeNone;
  switch (customScaleMode) {
    case BDXLynxFlowerVideoCustomScaleModeAspectFit:
      scaleMode = TTVideoEngineScalingModeAspectFit;
      break;
    case BDXLynxFlowerVideoCustomScaleModeAspectFill:
      scaleMode = TTVideoEngineScalingModeAspectFill;
      break;
    case BDXLynxFlowerVideoCustomScaleModeScaleFill:
      scaleMode = TTVideoEngineScalingModeFill;
      break;
    case BDXLynxFlowerVideoCustomScaleModeAuto:
      scaleMode = TTVideoEngineScalingModeNone;
      break;
  }
  return scaleMode;
}

- (NSString *)playerTypeString {
  return @"TTPlayer";
}

- (NSString *)playerNetworkTypeString {
  if (self.networkTypeString) {
    return self.networkTypeString;
  }

  if ([[BDXElementAdapter sharedInstance].networkDelegate
          respondsToSelector:@selector(networkTypeString)]) {
    self.networkTypeString = [[BDXElementAdapter sharedInstance].networkDelegate networkTypeString];
  }
  return self.networkTypeString ?: @"";
}

#pragma mark - util

- (NSNumber *)_getVideoPlayAccess {
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
