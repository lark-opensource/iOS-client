//
//  BDXLynxVideoPlayerPro.m
//
// Copyright 2022 The Lynx Authors. All rights reserved.
//

#import "BDXLynxVideoPlayerPro.h"
#import <ByteDanceKit/BTDNetworkUtilities.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <TTVideoEngine/TTVideoEngineHeader.h>
#import <BDWebImage/BDWebImage.h>
#import <BDALog/BDAgileLog.h>
#import <Lynx/LynxUI.h>

@implementation BDXLynxVideoProModel

- (instancetype)copy {
  BDXLynxVideoProModel *cp = [[BDXLynxVideoProModel alloc] init];
  cp.propsSrc = _propsSrc;
  cp.propsPoster = _propsPoster;
  cp.propsAutoplay = _propsAutoplay;
  cp.propsLoop = _propsLoop;
  cp.propsInitTime = _propsInitTime;
  cp.propsRate = _propsRate;
  cp.propsAutoLifeCycle = _propsAutoLifeCycle;
  cp.propsTag = _propsTag;
  cp.propsCacheSize = _propsCacheSize;
  cp.initMuted = _initMuted;
  cp.objectfit = _objectfit;
  cp.preloadKey = _preloadKey;
  cp.header = _header;
// not copy them
//  cp.playAuthToken = _playAuthToken;
//  cp.itemID = _itemID;
//  cp.playUrlString = _playUrlString;
//  cp.videoModel = videoModel;

  return cp;
}

@end

@interface BDXLynxVideoPlayerPro () <TTVideoEngineDelegate, TTVideoEngineDataSource>
@property (nonatomic, strong) TTVideoEngine *videoEngine;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, assign) BOOL inBackground;
@property (nonatomic, assign) BOOL willResumeWhileActive;
@property (nonatomic, assign) BOOL inListReusePool;

@end

@implementation BDXLynxVideoPlayerPro

- (instancetype)init {
  if (self = [super init]) {
    self.createEngineEveryTime = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerBecomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerEnterBackground) name: UIApplicationDidEnterBackgroundNotification object:nil];
  }
  return self;
}

- (void)dealloc {
  // stop videoEngine directly, do not create any new ref of self pointer, [self stop] is forbidden
  [self.videoEngine removeTimeObserver];
  if (self.asyncClose) {
    [self.videoEngine closeAysnc];
  } else {
    [self.videoEngine stop];
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setFrame:(CGRect)frame {
  [super setFrame:frame];
  self.videoEngine.playerView.frame = self.bounds;
  self.coverImageView.frame = self.bounds;
}

- (void)didMoveToWindow {
  [super didMoveToWindow];
  if (self.window) {
    [self playerBecomeActive];
  } else {
    [self playerEnterBackground];
  }
}


- (void)playerBecomeActive {
  self.inBackground = NO;
  if (self.playingModel.propsAutoLifeCycle && self.willResumeWhileActive) {
    self.willResumeWhileActive = NO;
    [self play];
  }
}

- (void)playerEnterBackground {
  self.inBackground = YES;
  if (self.playingModel.propsAutoLifeCycle && self.videoEngine.playbackState == TTVideoEnginePlaybackStatePlaying) {
    [self pause];
    self.willResumeWhileActive = YES;
  }
}

- (TTVideoEngine *)videoEngine {
  if (!_videoEngine) {
    _videoEngine = [[TTVideoEngine alloc] initWithOwnPlayer:YES];
    _videoEngine.playerView.backgroundColor = UIColor.clearColor;
    _videoEngine.playerView.clipsToBounds = YES;
    _videoEngine.netClient = nil;
    _videoEngine.hardwareDecode = YES;
    _videoEngine.delegate = self;
    _videoEngine.dataSource = self;
    [_videoEngine configResolution:TTVideoEngineResolutionTypeFullHD];
    [_videoEngine setOptions:@{VEKKEY(VEKKeyViewRenderEngine_ENUM) : @(TTVideoEngineRenderEngineOpenGLES),
                               VEKKEY(VEKKeyPlayerSeekEndEnabled_BOOL): @(YES),
                               VEKKEY(VEKKEYPlayerKeepFormatAlive_BOOL): @(YES),
                               VEKKEY(VEKKeyPlayerDashEnabled_BOOL) : @(NO),
                               VEKKEY(VEKKeyPlayerBashEnabled_BOOL):@(NO),
                               VEKKEY(VEKKeyPlayerCheckHijack_BOOL):@(NO)
                             }];
    // Notice: AudioUnitPoolEnable must be true
    [_videoEngine setOptionForKey:VEKKeyPlayerAudioUnitPoolEnable_BOOL value:@(YES)];
    
    [self addSubview:_videoEngine.playerView];
  }
  return _videoEngine;
}

- (void)setRenderByMetal:(BOOL)renderByMetal {
  [self.videoEngine setOptionForKey:VEKKeyViewRenderEngine_ENUM value:@(renderByMetal ? TTVideoEngineRenderEngineMetal: TTVideoEngineRenderEngineOpenGLES)];
}

- (UIImageView *)coverImageView {
  if (!_coverImageView) {
    [self videoEngine];
    _coverImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [_coverImageView setClipsToBounds:YES];
    _coverImageView.bd_isOpenDownsample = YES;
    [self addSubview:_coverImageView];
  }
  return _coverImageView;
}


- (void)setPlayingModel:(BDXLynxVideoProModel *)playingModel {
  if (_playingModel != playingModel) {
    if (_playingModel && self.createEngineEveryTime) {
      // create a new video engine
      [self stop];
      [_videoEngine.playerView removeFromSuperview];
      [self.videoEngine removeTimeObserver];
      _videoEngine = nil;
      self.videoEngine.playerView.frame = self.bounds;
      [self insertSubview:self.videoEngine.playerView atIndex:0];
    }
    
    _playingModel = playingModel;
    
    [self.videoEngine setTag:_playingModel.propsTag ? : @"x-video-pro"];
    
    self.videoEngine.looping = _playingModel.propsLoop;
    self.videoEngine.muted = _playingModel.initMuted;
    
    
    if ([_playingModel.objectfit isEqualToString:@"contain"]) {
      self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
      self.videoEngine.scaleMode = TTVideoEngineScalingModeAspectFit;

    } else if ([_playingModel.objectfit isEqualToString:@"cover"]) {
      self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
      self.videoEngine.scaleMode = TTVideoEngineScalingModeAspectFill;

    } else if ([_playingModel.objectfit isEqualToString:@"fill"]) {
      self.coverImageView.contentMode = UIViewContentModeScaleToFill;
      self.videoEngine.scaleMode = TTVideoEngineScalingModeFill;;
    }
    if (_playingModel.propsPoster) {
      __weak __typeof(self) weakSelf = self;
      NSURL *url = [NSURL URLWithString:_playingModel.propsPoster];
      if (url) {
        self.coverImageView.hidden = NO;
        self.coverImageView.image = nil;
        [self.coverImageView bd_setImageWithURL:url
                                    placeholder:nil
                                        options:BDImageRequestDefaultPriority
                                     completion:^(BDWebImageRequest * _Nonnull request, UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BDWebImageResultFrom from) {
          if (error) {
            [weakSelf.uiDelegate didError:@(2) msg:[NSString stringWithFormat:@"poster load failed: %@", error.description] url:url.absoluteString];
          }
        }];
      } else {
        [self.uiDelegate didError:@(2) msg:@"poster load failed" url:_playingModel.propsPoster];
      }
    }
    
    [self.videoEngine removeTimeObserver];
    __weak __typeof(self) weakSelf = self;
    [self.videoEngine addPeriodicTimeObserverForInterval:_playingModel.propsRate / 1000.0
                                               queue:dispatch_get_main_queue()
                                          usingBlock:^{
      if (weakSelf.videoEngine.playbackState == TTVideoEnginePlaybackStatePlaying) {
        NSTimeInterval totalDuration =
        weakSelf.videoEngine.duration;
        NSTimeInterval playedDuration =
        weakSelf.videoEngine.currentPlaybackTime;
        
        [weakSelf.uiDelegate playerDidTimeUpdate:@{
          @"total" : @(totalDuration * 1000),
          @"current" : @(playedDuration * 1000),
          @"progress" : @(playedDuration / totalDuration)
        }];
      }
    }];
    
    [self tryFetchVideo];
  }
}

- (void)tryFetchVideo {
  
  if (_playingModel.videoModel || _playingModel.itemID) {
    [self prepareVideo:NO];
  } else {
    __weak __typeof(self) weakSelf = self;
    BDXLynxVideoProModel *playingModel = _playingModel;
    
    [self.uiDelegate fetchByResourceManager:[NSURL URLWithString:_playingModel.playUrlString]
                          completionHandler:^(NSURL * _Nonnull localUrl, NSURL * _Nonnull remoteUrl, NSError * _Nullable error) {
      if (playingModel == weakSelf.playingModel) {
        if (localUrl) {
          playingModel.playUrlString = localUrl.absoluteString;
          [weakSelf prepareVideo:YES];
        } else if (remoteUrl) {
          playingModel.playUrlString = remoteUrl.absoluteString;
          [weakSelf prepareVideo:NO];
        } else {
          [weakSelf prepareVideo:NO];
        }
      }
    }];
  }
}

- (void)prepareVideo:(BOOL)isLocal {
  self.videoEngine.medialoaderEnable = YES;
  self.videoEngine.cacheVideoInfoEnable = YES;
  
  if (self.playingModel.propsCacheSize > 0) {
    // Limit the download size if needed.
    [self.videoEngine setOptionForKey:VEKKeyCacheLimitSingleMediaCacheSize_NSInteger value:@(self.playingModel.propsCacheSize)];
  }
  
  if (isLocal) {
    [self.videoEngine setPlayAPIVersion:TTVideoEnginePlayAPIVersion0 auth:nil];
    [self.videoEngine setLocalURL:self.playingModel.playUrlString];
  } else if (self.playingModel.videoModel) {
    [self.videoEngine setVideoModel:[TTVideoEngineModel videoModelWithDict:self.playingModel.videoModel]];
    [self.videoEngine setOptionForKey:VEKKeyProxyServerEnable_BOOL value:@(YES)];
  } else if (self.playingModel.itemID && !self.playingModel.playUrlString) {
    [self.videoEngine setPlayAPIVersion:TTVideoEnginePlayAPIVersion2 auth:nil];
    [self.videoEngine setOptionForKey:VEKKeyProxyServerEnable_BOOL value:@(YES)];
    [self.videoEngine setVideoID:self.playingModel.itemID];
  } else {
    [self.videoEngine setPlayAPIVersion:TTVideoEnginePlayAPIVersion0 auth:nil];
    [self.videoEngine ls_setDirectURL:self.playingModel.playUrlString key:self.playingModel.preloadKey ? : self.playingModel.playUrlString.btd_md5String];
  }
  
  [self.playingModel.header enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
    [self.videoEngine setCustomHeaderValue:obj forKey:key];
  }];
  
  [self.videoEngine setOptionForKey:VEKKeyPlayerStartTime_CGFloat value:@(self.playingModel.propsInitTime)];

  [self.videoEngine prepareToPlay];
  
  [self.uiDelegate markReady];
  
  if (self.playingModel.propsAutoplay) {
    [self play];
  }

}


#pragma mark - BDXLynxVideoProPlayerProtocol

- (void)play {
  BDALOG_INFO_TAG(@"x-video-pro", @"%@", @"play internal");
  if (self.inBackground && self.playingModel.propsAutoLifeCycle) {
    self.willResumeWhileActive = YES;
    return;
  }
  if (self.inListReusePool) {
    return;
  }
  __weak __typeof(self) weakSelf = self;
  [UIView animateWithDuration:0.1
                   animations:^{
    weakSelf.coverImageView.hidden = YES;
  } completion:^(BOOL finished) {
    weakSelf.coverImageView.image = nil;
  }];
  [self.uiDelegate markPlay];
  [self.videoEngine play];
}

- (void)stop {
  BDALOG_INFO_TAG(@"x-video-pro", @"%@", @"stop internal");
  [self.uiDelegate markStop];
  __weak __typeof(self) weakSelf = self;
  [self.videoEngine setCurrentPlaybackTime:0 complete:^(BOOL success) {
  } renderComplete:^{
    [weakSelf.videoEngine stop];
  }];
  if (self.inBackground && self.playingModel.propsAutoLifeCycle) {
    self.willResumeWhileActive = NO;
  }
}

- (void)pause {
  BDALOG_INFO_TAG(@"x-video-pro", @"%@", @"pause internal");
  [self.uiDelegate markStop];
  [self.videoEngine pause];
  if (self.inBackground && self.playingModel.propsAutoLifeCycle) {
    self.willResumeWhileActive = NO;
  }
}

- (void)mute:(BOOL)muted {
  BDALOG_INFO_TAG(@"x-video-pro", @"%@", @"mute internal");
  self.videoEngine.muted = muted;
}

- (void)seek:(NSTimeInterval)timeInSeconds completion:(void (^)(BOOL))completion {
  BDALOG_INFO_TAG(@"x-video-pro", @"%@", @"seek internal");
  [self.videoEngine setCurrentPlaybackTime:timeInSeconds complete:completion];
}

#pragma mark - TTVideoEngineDataSource


- (NSString *)apiForFetcher:(TTVideoEnginePlayAPIVersion)apiVersion {
    if (apiVersion == TTVideoEnginePlayAPIVersion2) {
      return [NSString stringWithFormat:@"https://%@/?%@", self.playingModel.playAuthDomain, self.playingModel.playAuthToken];
    }
    return nil;
}

#pragma mark - TTVideoEngineDelegate

/// Using media loader,the size of hit cache.
/// @param videoEngine Engine instance
/// @param key The task key of using media loader
/// @param cacheSize hit cache size.
- (void)videoEngine:(TTVideoEngine *)videoEngine mdlKey:(NSString *)key hitCacheSze:(NSInteger)cacheSize {
  if (videoEngine != self.videoEngine) {
    return;
  }
  if (cacheSize != 0) {
    [self.uiDelegate playerDidHitCache:@{
      @"key" : (key ? : @"undefined"),
      @"cacheSize" : @(cacheSize),
    }];
  }
}

/**
 playback state change callback

 @param videoEngine videoEngine
 @param playbackState playbackState
 */
- (void)videoEngine:(TTVideoEngine *)videoEngine playbackStateDidChanged:(TTVideoEnginePlaybackState)playbackState {
  BDALOG_INFO_TAG(@"x-video-pro", @"playbackState %@", @(playbackState));

  if (videoEngine != self.videoEngine) {
    return;
  }
  switch (playbackState) {
    case TTVideoEnginePlaybackStateStopped:
      // TTVideoEnginePlaybackStateStopped is not equal to loop end, but we can only get this call back from TTVideoEngine
      break;
    case TTVideoEnginePlaybackStatePlaying:
      [self.uiDelegate playerDidPlay:nil];
      break;
    case TTVideoEnginePlaybackStatePaused:
      [self.uiDelegate playerDidPause:nil];
      break;
    default:
      break;
  }
}

/**
 video engine will retry

 @param videoEngine videoengine
 @param error error info
 */
- (void)videoEngine:(TTVideoEngine *)videoEngine retryForError:(NSError *)error {
  BDALOG_INFO_TAG(@"x-video-pro", @"retryForError %@", error.description);

  if (videoEngine != self.videoEngine) {
    return;
  }
  [self.uiDelegate didError:@(error.code) msg:[NSString stringWithFormat:@"RetryForError :%@", error.description] url:self.playingModel.propsSrc];
}


/**
 load state change callback

 @param videoEngine videoEngine
 @param loadState loadState
 */
- (void)videoEngine:(TTVideoEngine *)videoEngine loadStateDidChanged:(TTVideoEngineLoadState)loadState {
  BDALOG_INFO_TAG(@"x-video-pro", @"loadState %@", @(loadState));

  
  if (videoEngine != self.videoEngine) {
    return;
  }
  switch (loadState) {
    case TTVideoEngineLoadStatePlayable:
      [self.uiDelegate playerBuffering:@{@"buffer" : @(1)}];
      break;
    case TTVideoEngineLoadStateStalled:
      [self.uiDelegate playerBuffering:@{@"buffer" : @(0)}];
      break;;
    case TTVideoEngineLoadStateError:
      [self.uiDelegate didError:@(loadState) msg:@"LoadStateDidChanged error" url:self.playingModel.propsSrc];
      break;
    default:
      break;
  }
}

///**
// video engine is prepared
//
// @param videoEngine videoengine
// */
- (void)videoEnginePrepared:(TTVideoEngine *)videoEngine {
  BDALOG_INFO_TAG(@"x-video-pro", @"prepared %@", nil);
  
  if (videoEngine != self.videoEngine) {
    return;
  }
  __weak __typeof(self) weakSelf = self;
  [UIView animateWithDuration:0.1
                   animations:^{
    weakSelf.coverImageView.hidden = YES;
  } completion:^(BOOL finished) {
    weakSelf.coverImageView.image = nil;
  }];
  [self.uiDelegate playerDidReady:nil];
}


/**
 user stopped
 
 @param videoEngine videoengine
 */
- (void)videoEngineUserStopped:(TTVideoEngine *)videoEngine {
  // called when the stop action works, do nothing here
}

/**
 video engine finished

 @param videoEngine videoengine
 @param error error info
 */
- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine error:(nullable NSError *)error {
  BDALOG_INFO_TAG(@"x-video-pro", @"finished %@", error.description);

  if (videoEngine != self.videoEngine) {
    return;
  }
  if (error) {
    [self.uiDelegate didError:@(error.code) msg:[NSString stringWithFormat:@"VideoEngineDidFinish :%@", error.description] url:self.playingModel.propsSrc];
  } else {
    [self.uiDelegate playerDidStop:nil];
  }
}


/**
 video engine finished because of bad video status

 @param videoEngine videoengine
 @param status video status code
 */
- (void)videoEngineDidFinish:(TTVideoEngine *)videoEngine videoStatusException:(NSInteger)status {
  if (videoEngine != self.videoEngine) {
    return;
  }
  [self.uiDelegate didError:@(status) msg:@"VideoEngineDidFinish error" url:self.playingModel.propsSrc];
}

/**
video engine close async complete

@param videoEngine videoengine
*/
- (void)videoEngineCloseAysncFinish:(TTVideoEngine *)videoEngine {
}

/**
 Video engine ready to display, show the first frame.

 @param videoEngine engine
 */
- (void)videoEngineReadyToDisPlay:(TTVideoEngine *)videoEngine {
  [self.uiDelegate playerDidRenderFirstFrame:nil];
}


#pragma mark - ListLifeCycle

- (void)onListCellAppear:(NSString *)itemKey withList:(LynxUICollection *)list {
  self.inListReusePool = NO;
}

- (void)onListCellDisappear:(NSString *)itemKey exist:(BOOL)isExist withList:(LynxUICollection *)list {
  self.inListReusePool = YES;
  [self pause];
}

- (void)onListCellPrepareForReuse:(NSString *)itemKey withList:(LynxUICollection *)list {
  self.inListReusePool = NO;
}


@end
