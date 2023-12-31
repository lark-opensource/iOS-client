// Copyright 2022 The Lynx Authors. All rights reserved.

#import "KryptonDefaultVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "KryptonLLog.h"
#import "LynxThreadManager.h"
#include "canvas/base/log.h"
#include "canvas/gpu/gl/gl_api.h"
#include "third_party/fml/synchronization/waitable_event.h"
#include "video_player_context_ios.h"

@interface KryptonVideoLifeCycleObserver : NSObject

@end

@implementation KryptonVideoLifeCycleObserver {
  uintptr_t _observedAddress;
}

- (void)observe:(id)object {
  if (!object) {
    return;
  }
  objc_setAssociatedObject(object, @selector(kryptonObserver), self,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  _observedAddress = (uintptr_t)object;
  KRYPTON_LLog(@"Player default observe: %p, object: %p", self, object);
}

- (void)dealloc {
  KRYPTON_LLog(@"Player default dealloc: %p, object: 0x%llx", self, _observedAddress);
}

@end

@interface KryptonDefaultVideoPlayer ()
@property(nonatomic, weak) id<KryptonVideoPlayerDelegate> delegate;
@property(nonatomic, assign) int width;
@property(nonatomic, assign) int height;
@property(nonatomic, assign) BOOL looping;
@property(nonatomic, assign) BOOL destroyed;
@property(nonatomic, assign) double duration;
@property(nonatomic, assign) KryptonVideoRotation rotation;
@end

@implementation KryptonDefaultVideoPlayerService
- (id<KryptonVideoPlayer>)createVideoPlayer {
  return [[KryptonDefaultVideoPlayer alloc] init];
}
@end

@implementation KryptonDefaultVideoPlayer {
  AVURLAsset* _asset;
  AVAssetTrack* _track;
  AVPlayerItem* _playItem;
  AVPlayer* _player;
  AVPlayerItemVideoOutput* _output;
  bool _playing;
  id _timeObserver;
  int64_t _timeObserverStartTime;
  __weak NSRunLoop* _runtimeLoop;
  double _volume;
  bool _audioOnly;
  double _currentTimeCache;
  AVAudioSession* _sessionInstance;
}

- (instancetype)init {
  if (self = [super init]) {
    _currentTimeCache = 0;
  }

  return self;
}

- (void)dealloc {
  KRYPTON_LLog(@"Player default dealloc: %p, thread: %@", self, [NSThread currentThread]);

  [self dispose];
}

- (void)setSource:(NSString*)url {
  [self clearPlayer];

  NSURL* URL = [NSURL URLWithString:url];
  _asset = [[AVURLAsset alloc] initWithURL:URL options:NULL];
  _runtimeLoop = [NSRunLoop currentRunLoop];

  __weak typeof(self) weakSelf = self;
  [_asset loadValuesAsynchronouslyForKeys:@[ @"playable", @"tracks" ]
                        completionHandler:^(void) {
                          __strong typeof(self) strongSelf = weakSelf;
                          [strongSelf performBlockOnThreadThatTirggerLoad:^{
                            __strong typeof(self) innerStrongSelf = weakSelf;
                            [innerStrongSelf onAssetLoadComplete];
                          }];
                        }];
}

- (void)onAssetLoadComplete {
  KRYPTON_LLog(@"Player default onAssetLoadComplete: %p", self);
  AVAssetTrack* videoTrack;
  NSError* error;
  if ([_asset statusOfValueForKey:@"playable" error:&error] != AVKeyValueStatusLoaded) {
    [self notifyPlayerState:kVideoStateError];
    return;
  }

  NSArray* videoTracks = [_asset tracksWithMediaType:AVMediaTypeVideo];
  videoTrack = videoTracks.firstObject;
  if (!videoTrack) {
    NSArray* audioTracks = [_asset tracksWithMediaType:AVMediaTypeAudio];
    if (!audioTracks) {
      [self notifyPlayerState:kVideoStateError];
      return;
    }
    self.width = self.height = 0;
    _audioOnly = true;
  } else {
    CGSize size = videoTrack.naturalSize;
    self.width = size.width;
    self.height = size.height;
    _audioOnly = false;
  }

  CMTime durationCM = [_asset duration];
  self.duration = durationCM.value * 1.0 / durationCM.timescale;
  CGAffineTransform t = videoTrack.preferredTransform;
  if (t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) {
    self.rotation = kVideoRotationCounterClockWise;
  } else if (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) {
    self.rotation = kVideoRotationClockWise;
  } else if (t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) {
    self.rotation = kVideoRotationNone;
  } else if (t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {
    self.rotation = kVideoRotation180;
  }

  _playItem = [AVPlayerItem playerItemWithAsset:_asset];
  _player = [AVPlayer playerWithPlayerItem:_playItem];
  [[KryptonVideoLifeCycleObserver new] observe:_asset];
  [[KryptonVideoLifeCycleObserver new] observe:_playItem];
  [[KryptonVideoLifeCycleObserver new] observe:_player];
  KRYPTON_LLog(@"Player default create player: %p, asset: %p, item: %p", _player, _asset,
               _playItem);
  _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;

  if (_currentTimeCache != 0.0) {
    [self setCurrentTime:_currentTimeCache];
  }

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(observePlayerItemDidReachEnd:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:_player.currentItem];

  if (_player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
    KRYPTON_LLog(@"Player default trigger canplay directly");
    [self notifyPlayerStateOnRuntimeThread:kVideoStateCanPlay];
    __weak typeof(self) weakSelf = self;
    [self performBlockOnThreadThatTirggerLoad:^{
      __strong typeof(self) strongSelf = weakSelf;
      [strongSelf onPlayerStatusChanged];
    }];
  } else {
    [_playItem addObserver:self
                forKeyPath:@"status"
                   options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                   context:nil];
  }

  NSDictionary* pixelBufferAttributes = @{
    (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
    (id)kCVPixelBufferWidthKey : @(_width),
    (id)kCVPixelBufferHeightKey : @(_height)
  };

  if (!_audioOnly) {
    _output = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixelBufferAttributes];
    if (_output == nil) {
      KRYPTON_LLog(@"Player default videoOutput init error width %d height %d ", _width, _height);
      [self notifyPlayerState:kVideoStateError];
      return;
    }

    [_playItem addOutput:_output];
  }

  [_player addObserver:self forKeyPath:@"rate" options:0 context:nil];
}

- (void)performBlockOnThreadThatTirggerLoad:(dispatch_block_t)block {
  if (_destroyed) {
    return;
  }

  if (@available(iOS 10.0, *)) {
    if (_runtimeLoop && block) {
      __weak typeof(self) weakSelf = self;
      [_runtimeLoop performBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf && !strongSelf.destroyed && block) {
          @autoreleasepool {
            block();
          }
        }
      }];
      return;
    }
  }
  KRYPTON_LLog(@"Player default performBlockOnCurrentThread: %p", self);
  if (block) {
    block();
  }
}

- (void)clearPlayer {
  KRYPTON_LLog(@"Player default clearPlayer: %p", self);

  [_player pause];
  _playing = false;

  @try {
    [_playItem removeObserver:self forKeyPath:@"status" context:NULL];
    [self tryToRemoveTimeObserver];
    [_player removeObserver:self forKeyPath:@"rate" context:NULL];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  } @catch (NSException* exception) {
    KRYPTON_LLogError(@"Player default clearPlayer error: %@", exception.description);
  }

  _playItem = nil;
  _player = nil;
  _timeObserver = nil;
}

- (void)dispose {
  if (_destroyed) {
    return;
  }

  _destroyed = true;

  [self clearPlayer];

  KRYPTON_LLog(@"Player default destroy: %p", self);
}

- (void)play {
  if (!_player) {
    return;
  }

  _playing = true;
  _player.volume = _volume;
  [_player play];

  _sessionInstance = [AVAudioSession sharedInstance];
  // enable video's sound in silent mode
  if (_sessionInstance.category != AVAudioSessionCategoryPlayback &&
      _sessionInstance.category != AVAudioSessionCategoryPlayAndRecord) {
    [_sessionInstance setCategory:AVAudioSessionCategoryPlayback error:nil];
  }
  NSTimeInterval bufferDuration = .01;
  [_sessionInstance setPreferredIOBufferDuration:bufferDuration error:nil];

  [self notifyPlayerStateOnRuntimeThread:kVideoStateStartPlay];
}

- (void)pause {
  [_player pause];
  _playing = false;
  [self notifyPlayerStateOnRuntimeThread:kVideoStatePaused];
}

- (double)getDuration {
  return _duration;
}

- (KryptonVideoRotation)getVideoRotation {
  return _rotation;
}

- (BOOL)getLooping {
  return _looping;
}

- (int)getVideoWidth {
  return _width;
}

- (int)getVideoHeight {
  return _height;
}

- (double)getCurrentTime {
  if (!_player || !_playing) {
    return 0;
  }

  CMTime currentTime = _player.currentItem.currentTime;
  if (currentTime.value < 0) {
    return 0;
  }
  return currentTime.value * 1.0 / currentTime.timescale;
}

- (void)setCurrentTime:(double)currentTime {
  _currentTimeCache = currentTime;
  CMTime time = CMTimeMake(_currentTimeCache * 30, 30);
  @try {
    __weak typeof(self) weakSelf = self;
    [_player seekToTime:time
          toleranceBefore:CMTimeMake(1, 1000)
           toleranceAfter:CMTimeMake(1, 1000)
        completionHandler:^(BOOL finished) {
          __strong typeof(self) strongSelf = weakSelf;
          if (finished) {
            [strongSelf notifyPlayerStateOnRuntimeThread:kVideoStateSeekEnd];
          }
        }];
  } @catch (NSException* exception) {
    [self notifyPlayerStateOnRuntimeThread:kVideoStateSeekEnd];
  }
}

- (void)setVolume:(double)volume {
  _volume = volume;
  [_player setVolume:volume];
}

- (CVPixelBufferRef)copyPixelBuffer {
  CMTime ts = _player.currentItem.currentTime;
  if (!_output || ![_output hasNewPixelBufferForItemTime:ts]) {
    //  no pixel to update
    return nullptr;
  }

  CVPixelBufferRef buffer = [_output copyPixelBufferForItemTime:ts itemTimeForDisplay:nil];
  return buffer;
}

- (void)observePlayerItemDidReachEnd:(NSNotification*)notification {
  __weak typeof(self) weakSelf = self;
  [self performBlockOnThreadThatTirggerLoad:^{
    __strong typeof(self) strongSelf = weakSelf;
    [strongSelf onPlayerItemDidReachEnd];
  }];
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id>*)change
                       context:(void*)context {
  KRYPTON_LLog(@"Player default KVO %@ ", keyPath);
  __weak typeof(self) weakSelf = self;
  if ([keyPath isEqualToString:@"status"]) {
    if ([object isKindOfClass:AVPlayerItem.class] &&
        [[change objectForKey:NSKeyValueChangeNewKey]
            isEqualToNumber:@(AVPlayerItemStatusReadyToPlay)] &&
        ![[change objectForKey:NSKeyValueChangeOldKey]
            isEqualToNumber:@(AVPlayerItemStatusReadyToPlay)]) {
      [self notifyPlayerStateOnRuntimeThread:kVideoStateCanPlay];
    }

    [self performBlockOnThreadThatTirggerLoad:^{
      __strong typeof(self) strongSelf = weakSelf;
      [strongSelf onPlayerStatusChanged];
    }];
  } else if ([keyPath isEqualToString:@"rate"]) {
    [self performBlockOnThreadThatTirggerLoad:^{
      __strong typeof(self) strongSelf = weakSelf;
      [strongSelf onPlayerRateChanged];
    }];
  }
}

- (void)onPlayerStatusChanged {
  if ([_playItem status] == AVPlayerItemStatusReadyToPlay &&
      [_player status] == AVPlayerStatusReadyToPlay && !_audioOnly &&
      _playItem.presentationSize.width > 1e-6) {
    [self autoNotifyStatusCanRender];
  } else {
    [self tryToRemoveTimeObserver];
  }
}

- (void)onPlayerRateChanged {
  if (_player) {
    float playerRate = [_player rate];
    if (playerRate > 1e-6 && !_playing) {
      KRYPTON_LLog(@"Player default status not playing, auto call pause");
      [_player pause];
    }
  }
}

- (void)onPlayerItemDidReachEnd {
  // always send end ignore loop status
  [self notifyPlayerState:kVideoStateEnd];

  if (_looping && _playing) {
    [_player seekToTime:kCMTimeZero];
    _player.volume = _volume;
    [_player play];
  } else {
    _playing = false;
    [_player pause];
  }
}

- (void)autoNotifyStatusCanRender {
  // wait for the first frame
  [self tryToRemoveTimeObserver];

  _timeObserverStartTime = [[NSDate date] timeIntervalSince1970];

  __weak typeof(self) weakSelf = self;
  _timeObserver =
      [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30)
                                            queue:nullptr
                                       usingBlock:^(CMTime) {
                                         __strong typeof(self) strongSelf = weakSelf;
                                         [strongSelf performBlockOnThreadThatTirggerLoad:^{
                                           __strong typeof(self) innerStrongSelf = weakSelf;
                                           [innerStrongSelf checkTimeObserver];
                                         }];
                                       }];
}

- (void)checkTimeObserver {
  if ([_output hasNewPixelBufferForItemTime:_player.currentItem.currentTime]) {
    // success
  } else if ([[NSDate date] timeIntervalSince1970] - _timeObserverStartTime > 2) {
    KRYPTON_LLog(@"Player default wait for first frame time out === ");
  } else {
    return;
  }
  if (_timeObserver != nil) {
    [self notifyPlayerState:kVideoStateCanDraw];
  }
  [self tryToRemoveTimeObserver];
}

- (void)tryToRemoveTimeObserver {
  if (_timeObserver != nil) {
    @try {
      [_player removeTimeObserver:_timeObserver];
    } @catch (NSException* exception) {
      // do nothing is ok
    }
    _timeObserver = nil;
  }
}

- (void)notifyPlayerStateOnRuntimeThread:(KryptonVideoState)state {
  __weak typeof(self) weakSelf = self;
  [self performBlockOnThreadThatTirggerLoad:^{
    __strong typeof(self) strongSelf = weakSelf;
    [strongSelf notifyPlayerState:state];
  }];
}

- (void)notifyPlayerState:(KryptonVideoState)state {
  if (!_destroyed) {
    [_delegate onVideoStatusChanged:state];
  }
}

@end
