//Copyright © 2021 Bytedance. All rights reserved.

#import <Foundation/Foundation.h>
#import <TTVideoEngine/TTVideoEngineHeader.h>
#import <AWEVideoPlayerWrapper/IESVideoPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@class BDXAweVideoPlayerWrapper;
@protocol BDXAweVideoPlayerWrapperDelegate <NSObject>

- (void)player:(BDXAweVideoPlayerWrapper *)player didChangePlaybackStateWithAction:(IESVideoPlaybackAction)playbackAction;

- (void)playerWillLoopPlaying:(BDXAweVideoPlayerWrapper *)player;

- (void)player:(BDXAweVideoPlayerWrapper *)player playbackFailedWithError:(NSError *)error;

- (void)player:(BDXAweVideoPlayerWrapper *)player playbackFailedForURL:(NSString *)URL error:(NSError *)error;

- (void)playerDidReadyForDisplay:(BDXAweVideoPlayerWrapper *)player;

- (void)player:(BDXAweVideoPlayerWrapper *)player didChangeStallState:(IESVideoStallAction)stallState;

@end

@interface BDXAweVideoPlayerWrapper : NSObject

@property (nonatomic, strong, readonly) UIView *view;

/// Player network type, using TTNET disaster recovery
@property (nonatomic, assign) IESVideoPlayerNetWorkType netWorkType;

/// Whether hard solution is enabled (for self-development)
@property (nonatomic, assign) BOOL enableHardDecode;

/// Use cache & preload when playing (default YES)
@property (nonatomic, assign) BOOL useCache;

/// Does the self-development player use URL to directly play (used by the self-development player)
@property (nonatomic, assign) BOOL ownPlayerPlayWithURLs;

/// Looping Play (Default Yes)
@property (nonatomic, assign) BOOL repeated;

/// Silent playback (default NO)
@property (nonatomic, assign) BOOL mute;

/// If the length of audio and video is inconsistent, whether to truncate (used by the system player)(default YES)
@property (nonatomic, assign) BOOL truncateTailWhenRepeated;

// Cache hit when playing (available after prepare)
@property (nonatomic, assign) BOOL playingWithCache;

/// volume
@property (nonatomic, assign) CGFloat volume;

// Cache size already exists at playback time
@property (nonatomic, assign) NSInteger cacheSize;

/// Scale mode (system player needs to be set before calling play)
@property (nonatomic, assign) IESVideoScaleMode scalingMode;

/// delegate
@property (nonatomic, weak) id<BDXAweVideoPlayerWrapperDelegate> delegate;

/// sessionId is created in prepareToPlay method and destroyed in stop method.
@property (nonatomic, assign) uint64_t sessionId;

- (instancetype)playerWithOwnPlayer:(BOOL)isOwnPlayer;

/**
 Set up the render engine for your own player
 */
- (void)setTTVideoEngineRenderEngine:(NSUInteger)renderEngineType;

/**
 *  Remove all playtime monitors
 */
- (void)removeTimeObserver;

/**
 *  Start playing
 */
- (void)play;

/**
 *  pause
 */
- (void)pause;

/**
 *  stop playing
 */
- (void)stop;

/**
 *  prepareToPlay
 */
- (void)prepareToPlay;

/**
 *  seekToTime
 */
- (void)seekToTime:(NSTimeInterval)timeInSeconds completion:(void(^)(BOOL finished))completion;

/**
 *  Added playback time monitoring (system player needs to be set before prepare)
 */
- (void)addPeriodicTimeObserverForInterval:(NSTimeInterval)interval queue:(dispatch_queue_t)queue usingBlock:(void (^)(void))block;

/**
 Use the self-development player
 @param time
 */
- (void)setStartPlayTime:(CGFloat)time;

/*
 * The frame data of the current video playing
 */
- (CVPixelBufferRef)currentPixelBuffer;

/**
 *  Current play time
 */
- (NSTimeInterval)currPlaybackTime;

/**
 *  videoDuration
 */
- (NSTimeInterval)videoDuration;

/**
 *  Current playback time
 */
- (NSTimeInterval)currPlayableDuration;

/*
**
*  playBitrate
*/
- (double)playBitrate;

/**
 *  playFPS
 */
- (double)playFPS;

/**
 *  video quality
 */
- (NSInteger)qualityType;

/**
 *  Reset VideoID(for self-development player) and VideoPlayUrls (for system player)
 */
- (void)resetVideoID:(NSString *)videoID andPlayURLs:(NSArray<NSString *> *)playURLs;
- (void)resetVideoID:(NSString *)videoID andPlayAuthToken:(NSString *)playAuthToken hosts:(NSArray *)hosts;

/**
 *  playerType
 */
- (IESVideoPlayerType)playerType;

@end

NS_ASSUME_NONNULL_END
