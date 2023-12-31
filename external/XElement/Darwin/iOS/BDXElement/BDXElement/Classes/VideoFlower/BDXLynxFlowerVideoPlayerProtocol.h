// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "BDXLynxFlowerVideoDefines.h"
@class BDXLynxFlowerVideoPlayer;
@class BDXLynxFlowerVideoPlayerConfiguration;
@class BDXLynxFlowerVideoPlayerVideoModel;

@protocol BDXLynxFlowerVideoCorePlayerProtocol;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDXLynxFlowerVideoStallAction) {
  /// 卡顿开始
  BDXLynxFlowerVideoStallActionBegin = 0,
  /// 卡顿结束
  BDXLynxFlowerVideoStallActionEnd,
};

typedef void (^BDXLynxFlowerVideoFullScreenPlayerDismissBlock)(void);

@protocol BDXLynxFlowerVideoCorePlayerDelegate <NSObject>

- (void)bdx_player:(id<BDXLynxFlowerVideoCorePlayerProtocol>)player
    didChangePlaybackStateWithAction:(BDXLynxFlowerVideoPlaybackAction)action;
- (void)bdx_player:(id<BDXLynxFlowerVideoCorePlayerProtocol>)player
    playbackFailedWithError:(NSError *)error;
- (void)bdx_playerDidReadyForDisplay:(id<BDXLynxFlowerVideoCorePlayerProtocol>)player;
- (void)bdx_playerWillLoopPlaying:(id<BDXLynxFlowerVideoCorePlayerProtocol>)player;
- (void)bdx_player:(id<BDXLynxFlowerVideoCorePlayerProtocol>)player
    didChangeStallState:(BDXLynxFlowerVideoStallAction)stallState;

@optional
- (void)bdx_player:(id<BDXLynxFlowerVideoCorePlayerProtocol>)player
    fullScreenAlone:(BOOL)isFullScreen;
- (void)bdx_player:(id<BDXLynxFlowerVideoCorePlayerProtocol>)player
    fetchByResourceManager:(NSURL *)aURL
         completionHandler:(void (^)(NSURL *localUrl, NSURL *remoteUrl,
                                     NSError *_Nullable error))completionHandler;

@end

@protocol BDXLynxFlowerVideoCorePlayerProtocol <NSObject>

- (instancetype)initWithFrame:(CGRect)frame
                configuration:(BDXLynxFlowerVideoPlayerConfiguration *)configuration;

@property(nonatomic, strong, readonly) UIView *view;
@property(nonatomic, assign) BOOL mute;
@property(nonatomic, assign) BOOL repeat;
@property(nonatomic, assign) CGFloat volume;
@property(nonatomic, assign) BOOL enableHardDecode;
@property(nonatomic, copy) NSDictionary *logExtraDict;
@property(nonatomic, assign) NSTimeInterval actionTimestamp;
@property(nonatomic, weak) id<BDXLynxFlowerVideoCorePlayerDelegate> delegate;

- (void)refreshVideoModel:(BDXLynxFlowerVideoPlayerVideoModel *)videoModel;
- (void)rereshPlayerScale:(BDXLynxFlowerVideoPlayerConfiguration *)config;

/**
 *  增加播放时间监听(系统播放器需要在prepare之前设置)
 */
- (void)addPeriodicTimeObserverForInterval:(NSTimeInterval)interval
                                     queue:(dispatch_queue_t)queue
                                usingBlock:(void (^)(void))block;
- (void)setStartPlayTime:(NSTimeInterval)startTime;
- (void)seekToTime:(NSTimeInterval)timeInSeconds completion:(void (^)(BOOL finished))completion;

#pragma mark - Player Control

- (void)stop;
- (void)pause;
- (void)play;

- (BOOL)isPlaying;

#pragma mark - PixelBuffer

/*
 * 当前视频播放的帧数据
 */
- (CVPixelBufferRef)currentPixelBuffer;

#pragma mark - Time

/**
 *  当前播放时间
 */
- (NSTimeInterval)currPlaybackTime;  // 原currentPlaybackTime

/**
 *  视频时长
 */
- (NSTimeInterval)videoDuration;  // 原duration
/**
 *  当前可播放时长
 */
- (NSTimeInterval)currPlayableDuration;  // 原playableDuration

@end

#pragma mark - FullScreen Player VC

@protocol BDXLynxFlowerVideoPlayProgressDelegate <NSObject>

@optional
- (void)playerDidPlayAtProgress:(NSTimeInterval)progress;

@end

@protocol BDXLynxFlowerVideoFullScreenPlayer <NSObject>

@property(nonatomic, assign) BOOL autoLifecycle;
/// 重复播放，默认 NO
@property(nonatomic, assign) BOOL repeated;
/// 设置要播放的视频，覆盖 playURL, coverURL
@property(nonatomic, strong, nullable) BDXLynxFlowerVideoPlayerVideoModel *video;

@property(nonatomic, assign) NSTimeInterval initPlayTime;

@property(nonatomic, weak) id<BDXLynxFlowerVideoPlayProgressDelegate> playerDelegate;

@property(nonatomic, strong) UIView *playerView;

@property(nonatomic, strong) BDXLynxFlowerVideoFullScreenPlayerDismissBlock dismissBlock;

- (BOOL)play;

- (BOOL)pause;

- (void)dismiss;
- (void)show:(void (^)(void))completion;

- (instancetype)initWithCoverImageURL:(NSString *)url;
- (instancetype)initWithCoverImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
