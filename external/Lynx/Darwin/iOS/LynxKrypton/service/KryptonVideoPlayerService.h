//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "KryptonService.h"

#import <CoreVideo/CVPixelBuffer.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, KryptonVideoState) {
  kVideoStateCanPlay = 0,
  kVideoStateEnd = 2,
  kVideoStateError = 3,
  kVideoStateCanDraw = 4,
  kVideoStateSeekEnd = 5,
  kVideoStateStartPlay = 6,
  kVideoStatePaused = 7,
};

typedef NS_ENUM(NSInteger, KryptonVideoRotation) {
  kVideoRotationCounterClockWise,
  kVideoRotationClockWise,
  kVideoRotationNone,
  kVideoRotation180,
};

#pragma mark - KryptonVideoPlayerDelegate

@protocol KryptonVideoPlayerDelegate <NSObject>

- (void)onVideoStatusChanged:(KryptonVideoState)status;

@end

#pragma mark - KryptonVideoPlayerProtocol
@protocol KryptonVideoPlayer <NSObject>

/// @param delegate  delegate, weak reference
- (void)setDelegate:(id<KryptonVideoPlayerDelegate>)delegate;

- (void)setSource:(NSString *)url;

- (void)play;

- (void)pause;

- (void)dispose;

- (CVPixelBufferRef)copyPixelBuffer;

- (int)getVideoWidth;

- (int)getVideoHeight;

- (double)getCurrentTime;

- (BOOL)getLooping;

- (double)getDuration;

- (KryptonVideoRotation)getVideoRotation;

- (void)setCurrentTime:(double)time;

- (void)setLooping:(BOOL)looping;

- (void)setVolume:(double)volume;

@end

@protocol KryptonVideoPlayerService <KryptonService>

/// Create video player instance
- (id<KryptonVideoPlayer>)createVideoPlayer;

@end

NS_ASSUME_NONNULL_END
