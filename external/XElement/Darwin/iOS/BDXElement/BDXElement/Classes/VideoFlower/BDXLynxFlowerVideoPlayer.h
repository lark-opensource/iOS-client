// Copyright 2021 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>
#import "BDXLynxFlowerVideoDefines.h"
#import "BDXLynxFlowerVideoPlayerVideoModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDXLynxFlowerVideoPlayerDelegate <NSObject>

@optional

- (void)didPlay;
- (void)didPause;
- (void)didEnd;
- (void)didError;
- (void)didTimeUpdate:(NSDictionary *)info;
- (void)didFullscreenChange:(NSDictionary *)info;
- (void)didBufferChange;
- (void)didBufferChangeWithInfo:(NSDictionary *)info;
- (void)didDeviceChange:(NSDictionary *)info;
- (void)didSeek:(NSTimeInterval)time;
- (void)didOnProgressChange:(NSDictionary *)info;
- (void)didStateChange:(NSDictionary *)info;

- (void)fetchByResourceManager:(NSURL *)aURL
             completionHandler:
                 (void (^)(NSURL *_Nonnull, NSURL *_Nonnull, NSError *_Nullable))completionHandler;

@end

@interface BDXLynxFlowerVideoPlayer : UIView

/// 是否开启硬解
@property(nonatomic, assign) BOOL enableHardDecode;
@property(nonatomic, assign) BOOL mute;
@property(nonatomic, assign) BOOL useSharedPlayer;
// Props
@property(nonatomic, assign) BOOL autoPlay;
@property(nonatomic, assign) CGFloat volume;
@property(nonatomic, assign) NSTimeInterval startTime;
@property(nonatomic, assign) NSTimeInterval playTime;
@property(nonatomic, assign) BOOL needReplay;

@property(nonatomic, assign) BDXLynxFlowerVideoPlayState currentPlayState;

// new props
@property(nonatomic, assign) BOOL isLoop;
@property(nonatomic, copy) NSString *posterURL;
@property(nonatomic, assign) BOOL needPreload;
@property(nonatomic, assign) BOOL autoLifecycle;
@property(nonatomic) NSTimeInterval rate;
@property(nonatomic, copy) NSString *fitMode;
@property(nonatomic, strong) BDXLynxFlowerVideoPlayerVideoModel *videoModel;
@property(nonatomic, copy) NSDictionary *logExtraDict;
@property(nonatomic, assign) NSTimeInterval duration;
@property(nonatomic, assign) NSTimeInterval currPlaybackTime;

@property(nonatomic, strong, readonly) UIImageView *coverImageView;

@property(nonatomic, weak, nullable) id<BDXLynxFlowerVideoPlayerDelegate> delegate;

- (instancetype)initWithDelegate:(nullable id<BDXLynxFlowerVideoPlayerDelegate>)delegate;

- (void)setupPlayer;

- (void)setStartPlayTime:(NSTimeInterval)startTime;

- (void)refreshBDXVideoModel:(BDXLynxFlowerVideoPlayerVideoModel *)videoModel
                      params:(NSDictionary *)params;

- (void)refreshLogExtraDict:(NSDictionary *)logExtraDict;

- (void)refreshActionTimestamp:(NSNumber *)actionTimestamp;

- (void)seekToTime:(NSTimeInterval)timeInSeconds completion:(void (^)(BOOL finished))completion;

#pragma mark - Player Control

- (void)stop;
- (void)pause;
- (void)play;

- (void)onSeeked:(NSTimeInterval)seekProgress;
/// full screen
- (void)zoom;
- (void)exitFullScreen;

@end

NS_ASSUME_NONNULL_END
