// Copyright 2021 The Lynx Authors. All rights reserved.

#import "BDXLynxFlowerVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <BDWebImage/BDWebImage.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/BTDWeakProxy.h>
#import "BDXLynxFlowerPixelBufferTransformer.h"
#import "BDXLynxFlowerVideoPlayerConfiguration.h"
#import "BDXLynxFlowerVideoPlayerProtocol.h"
#import "BDXLynxFlowerVideoPlayerVideoModel.h"

#import "BDXLynxFlowerVideoCore.h"

typedef NSString *BDXLynxFlowerVideoPlaybackState;

BDXLynxFlowerVideoPlaybackState const BDXLynxFlowerVideoPlaybackStatePaused = @"onPause";
BDXLynxFlowerVideoPlaybackState const BDXLynxFlowerVideoPlaybackStatePlayed = @"onPlay";
BDXLynxFlowerVideoPlaybackState const BDXLynxFlowerVideoPlaybackStateStopped = @"onStop";

@interface BDXLynxFlowerVideoPlayer () <BDXLynxFlowerVideoCorePlayerDelegate,
                                        BDXLynxFlowerVideoPlayProgressDelegate> {
  BOOL _playerMuted;
}

@property(nonatomic, strong) BDXLynxFlowerVideoPlayerConfiguration *configuration;
@property(nonatomic, strong) id<BDXLynxFlowerVideoCorePlayerProtocol> corePlayer;
@property(nonatomic, weak) id<BDXLynxFlowerVideoFullScreenPlayer> fullScreenPlayer;
@property(nonatomic, copy) BDXLynxFlowerVideoPlaybackState playbackState;
@property(nonatomic, strong) UIImageView *coverImageView;
@property(nonatomic, copy) NSString *posterImageURL;
@property(nonatomic, assign) NSInteger playedTimes;
@property(nonatomic, strong) NSTimer *progressTimer;
@property(nonatomic, assign) NSTimeInterval seekTime;  // s

@property(nonatomic, assign) BOOL shouldResumePlay;
@property(nonatomic, assign) BOOL isFullScreenAloneNow;
@property(nonatomic, weak) UIView *originalSuperView;
@property(nonatomic, assign) CGRect originRect;

@end

@implementation BDXLynxFlowerVideoPlayer

- (void)didMoveToWindow {
  [super didMoveToWindow];
  if (self.autoLifecycle) {
    if (!self.window && [self.corePlayer isPlaying]) {
      [self pause];
      self.shouldResumePlay = YES;
    } else {
      if (self.shouldResumePlay) {
        [self play];
        self.shouldResumePlay = NO;
      }
    }
  }
}

- (void)dealloc {
  [self __destroyPlayer];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame {
  return [self initWithDelegate:nil];
}

- (instancetype)initWithDelegate:(id<BDXLynxFlowerVideoPlayerDelegate>)delegate {
  if (self = [super initWithFrame:CGRectZero]) {
    _delegate = delegate;
    _fitMode = @"contain";
    _isFullScreenAloneNow = NO;
    self.coverImageView.hidden = NO;
    self.currentPlayState = BDXLynxFlowerVideoPlayStatePause;
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.coverImageView.frame = self.bounds;
  if (!self.isFullScreenAloneNow) {
    [self __currentPlayer].view.frame = self.bounds;
  }
}

- (void)removeFromSuperview {
  if (self.progressTimer) {
    [self.progressTimer invalidate];
    self.progressTimer = nil;
  }
  [super removeFromSuperview];
}

#pragma mark - Public

- (void)setupPlayer {
  if (!self.videoModel) {
    return;
  }
  [self __createPlayerIfPossible];
  [self __currentPlayer].view.hidden = NO;
  self.coverImageView.hidden = NO;
  if (self.autoPlay) {
    [self __currentPlayer].repeat = self.isLoop;
    [self play];
  }
}

- (void)pause {
  [[self __currentPlayer] pause];
}

- (void)play {
  [[self __currentPlayer] play];
}

- (void)stop {
  [[self __currentPlayer] stop];
}

- (void)zoom {
  CVPixelBufferRef pixelBuffer = [[self __currentPlayer] currentPixelBuffer];
  UIImage *image;
  if (pixelBuffer) {
    image =
        [BDXLynxFlowerPixelBufferTransformer bdx_imageFromCVPixelBufferRefForTTPlayer:pixelBuffer];
  }
  [self pause];
  Class fullScreenPlayerClz = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  if ([self.delegate.class respondsToSelector:@selector(fullScreenPlayerClz)]) {
    fullScreenPlayerClz = [self.delegate.class performSelector:@selector(fullScreenPlayerClz)];
  }
#pragma clang diagnostic pop

  if (!fullScreenPlayerClz) {
    return;
  }
  id<BDXLynxFlowerVideoFullScreenPlayer> fullScreenPlayer =
      [[fullScreenPlayerClz alloc] initWithCoverImage:image];
  fullScreenPlayer.playerDelegate = self;
  fullScreenPlayer.video = self.videoModel;
  fullScreenPlayer.playerView = self;
  fullScreenPlayer.repeated = self.isLoop;
  fullScreenPlayer.autoLifecycle = self.autoLifecycle;
  fullScreenPlayer.initPlayTime = self.playTime;

  self.originalSuperView = self.superview;
  self.originRect = self.frame;
  self.fullScreenPlayer = fullScreenPlayer;

  @weakify(self);
  [fullScreenPlayer show:^{
    @strongify(self);
    [self play];

    if ([self.delegate respondsToSelector:@selector(didFullscreenChange:)]) {
      [self.delegate didFullscreenChange:@{@"zoom" : @1}];
    }
  }];

  [fullScreenPlayer setDismissBlock:^{
    @strongify(self);
    self.frame = self.originRect;
    [self.originalSuperView insertSubview:self atIndex:0];
    [self play];

    if ([self.delegate respondsToSelector:@selector(didFullscreenChange:)]) {
      [self.delegate didFullscreenChange:@{@"zoom" : @0}];
    }
  }];
}

- (void)exitFullScreen {
  [self.fullScreenPlayer dismiss];
}

- (void)setEnableHardDecode:(BOOL)enableHardDecode {
  [self __currentPlayer].enableHardDecode = enableHardDecode;
}

- (BOOL)enableHardDecode {
  return [self __currentPlayer].enableHardDecode;
}

- (void)refreshBDXVideoModel:(BDXLynxFlowerVideoPlayerVideoModel *)videoModel
                      params:(NSDictionary *)params {
  self.videoModel = videoModel;
  if ([params objectForKey:@"logExtraDict"]) {
    self.logExtraDict = params[@"logExtraDict"];
  }
  if ([self __currentPlayer]) {
    [self stop];
    [[self __currentPlayer] refreshVideoModel:videoModel];
    if (self.startTime > 0) {
      @weakify(self);
      [self seekToTime:(self.startTime / 1000)
            completion:^(BOOL finished) {
              @strongify(self);
              if (self.autoPlay) {
                [self play];
              }
            }];
    } else {
      if (self.autoPlay) {
        [self play];
      }
    }
  } else {
    [self setupPlayer];
  }
}

- (void)refreshLogExtraDict:(NSDictionary *)logExtraDict {
  if ([self __currentPlayer]) {
    [self __currentPlayer].logExtraDict = logExtraDict;
  }
}

- (void)refreshActionTimestamp:(NSNumber *)actionTimestamp {
  if ([self __currentPlayer] && actionTimestamp) {
    [self __currentPlayer].actionTimestamp = (NSTimeInterval)actionTimestamp.doubleValue;
  }
}

- (void)seekToTime:(NSTimeInterval)timeInSeconds completion:(void (^)(BOOL))completion {
  [[self __currentPlayer] seekToTime:timeInSeconds completion:completion];
}

#pragma mark - Private

- (void)__destroyPlayer {
  [self.corePlayer stop];
  [self.corePlayer.view removeFromSuperview];
  self.corePlayer = nil;
}

- (void)__createPlayerIfPossible {
  if ([self __currentPlayer]) {
    return;
  }
  [self setClipsToBounds:YES];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playerBecomeActive)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playerEnterBackground)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(audioRouteChangeListenerCallback:)
                                               name:AVAudioSessionRouteChangeNotification
                                             object:nil];

  self.playedTimes = 0;

  [self __createPlayer];
}

- (id<BDXLynxFlowerVideoCorePlayerProtocol>)__createCorePlayer {
  BDXLynxFlowerVideoCore *corePlayer =
      [[BDXLynxFlowerVideoCore alloc] initWithFrame:self.bounds configuration:self.configuration];
  [self __addPeriodicTimeObserver:corePlayer];
  return corePlayer;
}

- (void)__createPlayer {
  if (!self.videoModel) {
    return;
  }

  [self __destroyPlayer];

  id<BDXLynxFlowerVideoCorePlayerProtocol> player = [self __createCorePlayer];

  if (self.startTime > 0) {
    // seek 采用startTime的方式，seek时不需要显示封面
    [player setStartPlayTime:self.startTime / 1000];
    self.startTime = 0;
  }
  player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  player.delegate = self;
  if (self.logExtraDict) {
    player.logExtraDict = self.logExtraDict;
  }
  [self addSubview:player.view];

  [player refreshVideoModel:self.videoModel];

  [self __configPoster];

  // demaciaPlayer has its own setHidden: which also set IESVideoPlayerProtocol's view.hidden
  player.view.hidden = YES;

  self.corePlayer = player;
  [self bringSubviewToFront:self.coverImageView];
}

- (void)__configPoster {
  if (BTD_isEmptyString(self.posterURL) || !self.posterURL) return;
  if (![self.posterImageURL isEqualToString:self.posterURL]) {
    self.posterImageURL = self.posterURL;
    NSURL *url = [NSURL URLWithString:self.posterURL];
    if (url) {
      [self.coverImageView bd_setImageWithURL:url options:BDImageRequestSetAnimationFade];
    }

    if (!BTD_isEmptyString(self.posterURL)) {
      [self.coverImageView setHidden:NO];
    } else {
      [self.coverImageView setHidden:YES];
    }
  }
}

- (void)setStartPlayTime:(NSTimeInterval)startTime {
  [[self __currentPlayer] setStartPlayTime:startTime];
}

- (BDXLynxFlowerVideoPlayerConfiguration *)configuration {
  if (!_configuration) {
    BDXLynxFlowerVideoPlayerConfiguration *configuration =
        [BDXLynxFlowerVideoPlayerConfiguration new];
    configuration.repeated = NO;
    if (self.mute) {
      configuration.mute = self.mute;
    }
    if (self.isLoop) {
      configuration.repeated = self.isLoop;
    }

    configuration.disableTracker = YES;

    if ([self.fitMode isEqualToString:@"contain"]) {
      configuration.customScaleMode = BDXLynxFlowerVideoCustomScaleModeAspectFit;
    } else if ([self.fitMode isEqualToString:@"cover"]) {
      configuration.customScaleMode = BDXLynxFlowerVideoCustomScaleModeAspectFill;
    } else if ([self.fitMode isEqualToString:@"fill"]) {
      configuration.customScaleMode = BDXLynxFlowerVideoCustomScaleModeScaleFill;
    }
    configuration.enableTTPlayer = YES;
    _configuration = configuration;
  }
  return _configuration;
}

- (void)__addPeriodicTimeObserver:(id<BDXLynxFlowerVideoCorePlayerProtocol>)player {
  __weak typeof(self) weakSelf = self;
  [player addPeriodicTimeObserverForInterval:0.5
                                       queue:dispatch_get_main_queue()
                                  usingBlock:^{
                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                    NSTimeInterval totalDuration =
                                        [strongSelf __currentPlayer].videoDuration;
                                    NSTimeInterval playedDuration =
                                        [strongSelf __currentPlayer].currPlaybackTime;
                                    NSTimeInterval cachedPlayDuration =
                                        [strongSelf __currentPlayer].currPlayableDuration;
                                    [strongSelf bdxPlayerPlayTime:playedDuration
                                                      canPlayTime:cachedPlayDuration
                                                        totalTime:totalDuration];
                                  }];
}

- (id<BDXLynxFlowerVideoCorePlayerProtocol>)__currentPlayer {
  return self.corePlayer;
}

- (void)__configFitMode {
  if ([self.fitMode isEqualToString:@"contain"]) {
    _coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.configuration.customScaleMode = BDXLynxFlowerVideoCustomScaleModeAspectFit;
  } else if ([self.fitMode isEqualToString:@"cover"]) {
    _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.configuration.customScaleMode = BDXLynxFlowerVideoCustomScaleModeAspectFill;
  } else if ([self.fitMode isEqualToString:@"fill"]) {
    self.configuration.customScaleMode = BDXLynxFlowerVideoCustomScaleModeScaleFill;
  }
  [[self __currentPlayer] rereshPlayerScale:self.configuration];
}

- (void)__startProgressTimer {
  if (self.progressTimer) {
    return;
  }
  NSTimeInterval interval = (self.rate / 1000);
  BTDWeakProxy *proxy = [BTDWeakProxy proxyWithTarget:self];
  self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                        target:proxy
                                                      selector:@selector(__progressTimerFired)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)__progressTimerFired {
  // TODO: progress timer triggered
  if ([self.delegate respondsToSelector:@selector(didOnProgressChange:)] &&
      ![self.playbackState isEqualToString:BDXLynxFlowerVideoPlaybackStatePaused]) {
    if (self.seekTime > 0) {
    } else {
      [self.delegate didOnProgressChange:@{
        @"progress" : [NSString stringWithFormat:@"%lf", self.playTime * 1000] ?: @""
      }];
    }
  }
}

- (void)onSeeked:(NSTimeInterval)seekProgress {
  if ([self.delegate respondsToSelector:@selector(didSeek:)]) {
    [self.delegate didSeek:seekProgress];
  }
}

- (void)__cancelProgressTimer {
  if (self.progressTimer) {
    [self.progressTimer invalidate];
    self.progressTimer = nil;
  }
}

- (void)__checkPlayingViewState {
  if (self.coverImageView.hidden == NO) {
    [self.coverImageView setHidden:YES];
  }
  if ([self __currentPlayer].view.hidden == YES) {
    [[self __currentPlayer].view setHidden:NO];
  }
}

#pragma mark - Notification

- (void)playerBecomeActive {
  if (self.autoLifecycle && self.shouldResumePlay) {
    self.shouldResumePlay = NO;
    [self play];
  }
}

- (void)playerEnterBackground {
  if (self.autoLifecycle && [self.corePlayer isPlaying]) {
    self.shouldResumePlay = YES;
    [self pause];
  }
}

- (void)audioRouteChangeListenerCallback:(NSNotification *)notification {
  NSDictionary *interuptionDict = notification.userInfo;
  NSInteger routeChangeReason =
      [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
  switch (routeChangeReason) {
    case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
      if ([self.delegate respondsToSelector:@selector(didDeviceChange:)]) {
        [self.delegate didDeviceChange:@{@"headphone" : @1}];
      }
      break;
    case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
      if (self.autoLifecycle) {
        [self pause];
      }
      if ([self.delegate respondsToSelector:@selector(didDeviceChange:)]) {
        [self.delegate didDeviceChange:@{@"headphone" : @0}];
      }
      break;
    case AVAudioSessionRouteChangeReasonCategoryChange:
      // called at start - also when other audio wants to play
      break;
    default:
      break;
  }
}

#pragma mark - BDXVideoPlayProgressDelegate

- (void)playerDidPlayAtProgress:(NSTimeInterval)progress {
  @weakify(self);
  if (progress < 0 || progress > [self __currentPlayer].videoDuration) {
    return;
  }
  [self seekToTime:progress
        completion:^(BOOL finished) {
          @strongify(self);
          if (self.autoLifecycle) {
            [self play];
          }
          if ([self.delegate respondsToSelector:@selector(didFullscreenChange:)]) {
            [self.delegate didFullscreenChange:@{@"zoom" : @0}];
          }
        }];
}

#pragma mark - Getter & Setter

- (UIImageView *)coverImageView {
  if (!_coverImageView) {
    // 初始使用视频封面
    _coverImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [_coverImageView setClipsToBounds:YES];
    [self __configFitMode];
    [self addSubview:_coverImageView];
  }
  return _coverImageView;
}

- (void)setPlaybackState:(NSString *)playbackState {
  if (playbackState && !isEmptyString(playbackState) &&
      ![playbackState isEqualToString:_playbackState]) {
    _playbackState = [playbackState copy];
    if (![playbackState isEqualToString:@"onEnd"]) {
      if ([self.delegate respondsToSelector:@selector(didStateChange:)]) {
        [self.delegate didStateChange:@{@"state" : _playbackState ?: @""}];
      }
    }
  }
}

- (void)setPosterURL:(NSString *)posterURL {
  _posterURL = posterURL;
  if (_posterURL) {
    [self __configPoster];
  }
}

- (void)setFitMode:(NSString *)fitMode {
  if (![fitMode isEqualToString:_fitMode]) {
    _fitMode = fitMode;
    [self __configFitMode];
  }
}

- (void)setVolume:(CGFloat)volume {
  if (volume >= 0 && volume <= 1) {
    [self __currentPlayer].volume = volume;
  }
}

- (void)setHidden:(BOOL)hidden {
  [super setHidden:hidden];
  [self __currentPlayer].view.hidden = hidden;
}

- (void)setAlpha:(CGFloat)alpha {
  [super setAlpha:alpha];
  [self __currentPlayer].view.alpha = alpha;
}

- (void)setAutoPlay:(BOOL)autoPlay {
  if (_autoPlay != autoPlay) {
    _autoPlay = autoPlay;
    if (autoPlay) {
      [self setupPlayer];
    }
  }
}

- (void)setRate:(NSTimeInterval)rate {
  if (_rate != rate) {
    _rate = rate;
    if (rate > 0) {
      [self __startProgressTimer];
    }
  }
}

- (void)setIsLoop:(BOOL)isLoop {
  if (_isLoop != isLoop) {
    _isLoop = isLoop;
    self.configuration.repeated = isLoop;
    [self __currentPlayer].repeat = isLoop;
  }
}

- (void)setMute:(BOOL)mute {
  if (_playerMuted != mute) {
    _playerMuted = mute;
    self.configuration.mute = mute;
    [self __currentPlayer].mute = mute;
  }
}

- (BOOL)mute {
  return _playerMuted;
}

- (CGFloat)volume {
  return [self __currentPlayer].volume;
}

- (BDXLynxFlowerVideoPlayState)currentPlayState {
  if ([self.playbackState isEqualToString:BDXLynxFlowerVideoPlaybackStatePaused]) {
    return BDXLynxFlowerVideoPlayStatePause;
  } else if ([self.playbackState isEqualToString:BDXLynxFlowerVideoPlaybackStatePlayed]) {
    return BDXLynxFlowerVideoPlayStatePlay;
  } else {
    return BDXLynxFlowerVideoPlayStateStop;
  }
}

- (NSTimeInterval)duration {
  return [self __currentPlayer].videoDuration;
}

- (NSTimeInterval)currPlaybackTime {
  return [[self __currentPlayer] currPlaybackTime];
}

#pragma mark - BDXVideoCorePlayerDelegate

- (void)bdx_player:(id<BDXLynxFlowerVideoCorePlayerProtocol>)player
    didChangePlaybackStateWithAction:(BDXLynxFlowerVideoPlaybackAction)action {
  if (player != [self __currentPlayer]) {
    return;
  }

  switch (action) {
    case BDXLynxFlowerVideoPlaybackActionStart:
    case BDXLynxFlowerVideoPlaybackActionResume:
      self.playbackState = BDXLynxFlowerVideoPlaybackStatePlayed;
      [self __checkPlayingViewState];
      if ([self.delegate respondsToSelector:@selector(didPlay)]) {
        [self.delegate didPlay];
      }
      break;
    case BDXLynxFlowerVideoPlaybackActionStop:
      self.playedTimes++;
      self.playbackState = BDXLynxFlowerVideoPlaybackStateStopped;
      if (self.playedTimes == 1 && !self.isLoop) {
        self.needReplay = YES;
        if ([self.delegate respondsToSelector:@selector(didStateChange:)]) {
          [self.delegate didStateChange:@{
            @"state" : @"onCompleted",
            @"data" : @{@"times" : [NSString stringWithFormat:@"%ld", (long)self.playedTimes]}
          }];
        }
        self.playedTimes--;
      }
      if ([self.delegate respondsToSelector:@selector(didEnd)]) {
        [self.delegate didEnd];
      }
      break;
    case BDXLynxFlowerVideoPlaybackActionPause: {
      self.playbackState = BDXLynxFlowerVideoPlaybackStatePaused;
      if ([self.delegate respondsToSelector:@selector(didPause)]) {
        [self.delegate didPause];
      }
    } break;
  }
}

- (void)bdx_playerWillLoopPlaying:(id<BDXLynxFlowerVideoCorePlayerProtocol>)player {
  if (player != [self __currentPlayer]) {
    return;
  }
  self.playedTimes++;
  if ([self.delegate respondsToSelector:@selector(didStateChange:)]) {
    [self.delegate didStateChange:@{
      @"state" : @"onCompleted",
      @"data" : @{@"times" : [NSString stringWithFormat:@"%ld", (long)self.playedTimes]}
    }];
  }
}

- (void)bdx_player:(nonnull id<BDXLynxFlowerVideoCorePlayerProtocol>)player
    playbackFailedWithError:(nonnull NSError *)error {
  if (player != [self __currentPlayer]) {
    return;
  }
  if ([self.delegate respondsToSelector:@selector(didError)]) {
    [self.delegate didError];
  }
  self.playbackState = @"playFail";
}

- (void)bdx_playerDidReadyForDisplay:(nonnull id<BDXLynxFlowerVideoCorePlayerProtocol>)player {
  if (player != [self __currentPlayer]) {
    return;
  }
  if ([self.delegate respondsToSelector:@selector(didBufferChange)]) {
    [self.delegate didBufferChange];
  }
  [UIView animateWithDuration:0.1
                   animations:^{
                     // 首帧出现，准备播放时 隐藏封面
                     [self __checkPlayingViewState];
                   }];
}

- (void)bdx_player:(id<BDXLynxFlowerVideoCorePlayerProtocol>)player
    didChangeStallState:(BDXLynxFlowerVideoStallAction)stallState {
  if (player != [self __currentPlayer]) {
    return;
  }
  if ([self.delegate respondsToSelector:@selector(didBufferChangeWithInfo:)]) {
    [self.delegate didBufferChangeWithInfo:@{
      @"buffer" : stallState == BDXLynxFlowerVideoStallActionBegin ? @1 : @0
    }];
  }
}

- (void)bdxPlayerPlayTime:(NSTimeInterval)playTime
              canPlayTime:(NSTimeInterval)canPlayTime
                totalTime:(NSTimeInterval)totalTime {
  self.playTime = playTime;
  if ([self.delegate respondsToSelector:@selector(didTimeUpdate:)]) {
    [self.delegate didTimeUpdate:@{
      @"progress" : [NSString stringWithFormat:@"%lf", self.playTime * 1000] ?: @""
    }];
  }
}

- (void)bdx_player:(id<BDXLynxFlowerVideoCorePlayerProtocol>)player
    fullScreenAlone:(BOOL)isFullScreen {
  self.isFullScreenAloneNow = isFullScreen;
}

- (void)bdx_player:(id<BDXLynxFlowerVideoCorePlayerProtocol>)player
    fetchByResourceManager:(NSURL *)aURL
         completionHandler:
             (void (^)(NSURL *_Nonnull, NSURL *_Nonnull, NSError *_Nullable))completionHandler {
  if ([self.delegate respondsToSelector:@selector(fetchByResourceManager:completionHandler:)]) {
    [self.delegate fetchByResourceManager:aURL completionHandler:completionHandler];
  }
}

@end
