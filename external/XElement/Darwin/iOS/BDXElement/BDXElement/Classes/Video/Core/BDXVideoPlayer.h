//
//  BDXVideoPlayer.h
//  BDXElement
//
//  Created by yuanyiyang on 2020/4/23.
//

#import <Foundation/Foundation.h>
#import "BDXVideoDefines.h"

@class BDXVideoPlayerConfiguration;
@class BDXVideoPlayerVideoModel;
@class BDXVideoPlayer;

NS_ASSUME_NONNULL_BEGIN

@protocol BDXVideoPlayerDelegate <NSObject>

@optional
+ (Class)videoCorePlayerClazz;
+ (Class)fullScreenPlayerClz;

- (void)didPlay;
- (void)didPause;
- (void)didEnd;
- (void)didError;
- (void)didError:(NSDictionary *)errorInfo;
- (void)didTimeUpdate:(NSDictionary *)info;
- (void)didFullscreenChange:(NSDictionary *)info;
- (void)didBufferChange;
- (void)didBufferChangeWithInfo:(NSDictionary *)info;
- (void)didDeviceChange:(NSDictionary *)info;
- (void)didSeek:(NSTimeInterval)time;
- (void)didOnProgressChange:(NSDictionary *)info;
- (void)didStateChange:(NSDictionary *)info;
- (BOOL)hidden;

- (void)fetchByResourceManager:(NSURL *)aURL completionHandler:(void (^)(NSURL * _Nonnull, NSURL * _Nonnull, NSError * _Nullable))completionHandler;

@end

@interface BDXVideoPlayer : UIView

//TODO: implement this
/// 是否开启硬解
@property (nonatomic, assign) BOOL enableHardDecode;
@property (nonatomic, assign) BOOL mute;
@property (nonatomic, assign) BOOL useSharedPlayer;
// Props
@property (nonatomic, assign) BOOL autoPlay;
@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) NSTimeInterval playTime;
@property (nonatomic, assign) BOOL needReplay;

@property (nonatomic, assign) BDXVideoPlayState currentPlayState;

// new props
@property (nonatomic, assign) BOOL isLoop;
@property (nonatomic, copy) NSString *posterURL;
@property (nonatomic, assign) BOOL needPreload;
@property (nonatomic, assign) BOOL autoLifecycle;
@property (nonatomic) NSTimeInterval rate;
@property (nonatomic, copy) NSString *fitMode;
@property (nonatomic, strong) BDXVideoPlayerVideoModel *videoModel;
@property (nonatomic, copy) NSDictionary *logExtraDict;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval currPlaybackTime;

@property (nonatomic, strong, readonly) UIImageView *coverImageView;

@property (nonatomic, weak, nullable) id<BDXVideoPlayerDelegate> delegate;

- (instancetype)initWithDelegate:(nullable id<BDXVideoPlayerDelegate>)delegate;

- (void)setupPlayer;

- (void)setStartPlayTime:(NSTimeInterval)startTime;

- (void)refreshBDXVideoModel:(BDXVideoPlayerVideoModel *)videoModel params:(NSDictionary *)params;

- (void)refreshLogExtraDict:(NSDictionary *)logExtraDict;

- (void)refreshActionTimestamp:(NSNumber *)actionTimestamp;

- (void)seekToTime:(NSTimeInterval)timeInSeconds completion:(void(^)(BOOL finished))completion;

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
