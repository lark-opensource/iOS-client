//
//  TMAPlayerView.h
//  OPPluginBiz
//
//  Created by bupozhuang on 2019/1/3.
//

#import <UIKit/UIKit.h>
#import <OPFoundation/BDPMediaPluginDelegate.h>
#import "TMAVideoControlView.h"
#import "TMAVideoContainer.h"

NS_ASSUME_NONNULL_BEGIN
@class TMAPlayerModel;
@class TMAVideoControlView;
@class TMAPlayerView;

// 播放器的几种状态
typedef NS_ENUM(NSInteger, TMAPlayerState) {
    TMAPlayerStateFailed,     // 播放失败
    TMAPlayerStateBuffering,  // 缓冲中
    TMAPlayerStatePlaying,    // 播放中
    TMAPlayerStateStopped,    // 停止播放
    TMAPlayerStatePause,      // 暂停播放
    TMAPlayerStateBreak,      // break
    TMAPlayerStateEnd,        // 播放结束
};

@protocol TMAPlayerViewDelegate <NSObject>
@optional
/** 播放器播放状态变化 */
- (void)tma_playerView:(TMAPlayerView *)player playStatuChanged:(TMAPlayerState)state;
- (void)tma_playerViewFullScreenChanged:(TMAPlayerView *)player;
- (void)tma_playerViewSeekComplete;
- (void)tma_playerViewTimeUpdate;
- (void)tma_playerViewControlsToggle:(BOOL)show;
- (void)tma_playerViewLoadedMetaData;
- (void)tma_playerViewError:(nullable NSError *)error;
- (void)tma_playerViewErrorString:(nonnull NSString *)errorInfo;
- (void)tma_playerViewPlaybackRateChanged;
- (void)tma_playerViewMuteChanged;
- (void)tma_playerViewUserAction:(BDPVideoUserAction)action value:(BOOL)value;

@end

@interface TMAPlayerView : UIView<TMAVideoContainerPlayerDelegate>

@property (nonatomic, weak) id <TMAPlayerViewDelegate> delegate;
@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, assign) BOOL muted;
@property (nonatomic, assign, readonly) TMAPlayerState state;
@property (nonatomic, strong) TMAPlayerModel *playerModel;

- (void)updateWithPlayerModel:(TMAPlayerModel *)playerModel
            changedDataSource:(BOOL)changedDataSource
                     autoPlay:(BOOL)autoPlay;
// 暂停
- (void)pauseByUser:(BOOL)byUser;
// 开始播放
- (void)play;
// 关闭并清空内存
- (void)close;
- (void)addPlayerToFatherView;
- (void)seekToTime:(NSTimeInterval)dragedSeconds completionHandler:(void (^)(BOOL success))completionHandler;
- (void)enterFullScreen:(BOOL)enter;
- (void)setPlaybackRate:(CGFloat)rate;

- (NSString *)fullScreenDirection;
- (CGFloat)currentSeekTime;
- (CGFloat)totalDuration;
- (NSInteger)videoWidth;
- (NSInteger)videoHeight;
- (CGFloat)playbackSpeed;

@end

NS_ASSUME_NONNULL_END
