//
//  BDASplashVideoContainer.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2020/4/27.
//

#import <UIKit/UIKit.h>

@class TTAdSplashModel;

/** 播放器类型 */
typedef NS_ENUM(NSInteger, BDASplashVideoPlayerType) {
    BDASplashVideoPlayerTypeSystem = 0, ///< 系统播放器
    BDASplashVideoPlayerTypeOwner       ///< 自研播放器
};

typedef NS_ENUM(NSUInteger, BDASplashVideoStatus) {
    BDASplashVideoStatus_Unkown,
    BDASplashVideoStatus_Fail,
    BDASplashVideoStatus_Ready,
    BDASplashVideoStatus_Interrupt,
    BDASplashVideoStatus_Finish,
    BDASplashVideoStatus_Pause,
};

typedef NS_ENUM(NSInteger, BDASplashVideoPlayPercent) {
    BDASplashVideoPlayPercentStart = 0,
    BDASplashVideoPlayPercentFirstQuartile,
    BDASplashVideoPlayPercentMidPoint,
    BDASplashVideoPlayPercentThirdQuartile,
    BDASplashVideoPlayPercentComplete
};

NS_ASSUME_NONNULL_BEGIN

@protocol BDASplashVideoViewDelegate;

@protocol BDASplashVideoProtocol <NSObject>

@property (nonatomic, weak) id<BDASplashVideoViewDelegate> delegate;

- (NSTimeInterval)duration;

- (NSTimeInterval)currentTime;

- (BOOL)isPlaying;

/// 开始播放
- (void)play;

/// 暂停播放
- (void)pause;

- (void)setVideoMute:(BOOL)isMute;

@optional
/// 设置从什么位置播放
/// @param seconds 播放的位置,精确到秒
- (void)seekToTime:(CGFloat)seconds;

- (BOOL)enableNNSR;

@end

@protocol BDASplashVideoViewDelegate <NSObject>

- (void)splashVideoView:(id<BDASplashVideoProtocol>)videoView playStatus:(BDASplashVideoStatus)status;

@optional

- (void)splashVideoPlayPercent:(BDASplashVideoPlayPercent)percent;

- (void)splashVideoPlayFailedWithError:(nullable NSError *)error;

- (void)didEnterBackground;

@end

/** 视频 view 容器，里面包含了两种播放器初始化 ：系统播放器和公司自研播放器。并处理播放器公共逻辑*/
@interface BDASplashVideoContainer : UIView <BDASplashVideoProtocol>

@property (nonatomic, weak) id<BDASplashVideoViewDelegate> delegate;

- (instancetype)initWithModel:(TTAdSplashModel *)model
                   playerType:(BDASplashVideoPlayerType)type;

@end

NS_ASSUME_NONNULL_END
