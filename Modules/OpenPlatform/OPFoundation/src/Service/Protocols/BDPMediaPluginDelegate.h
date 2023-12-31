//
//  BDPMediaPluginDelegate.h
//  Pods
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#ifndef BDPMediaPluginDelegate_h
#define BDPMediaPluginDelegate_h

#import "BDPBasePluginDelegate.h"
#import "BDPChooseImagePluginModel.h"
#import "BDPJSBridgeProtocol.h"
#import "BDPVideoViewModel.h"
#import "BDPChooseVideoModel.h"
#import <AVFoundation/AVFoundation.h>

#pragma mark - Video
#pragma mark -
/****************************************************************************/
/*********                       Video                       ****************/
/****************************************************************************/

typedef NS_ENUM(NSInteger, BDPVideoPlayerState) {
    BDPVideoPlayerStateUnknow,
    BDPVideoPlayerStateFinished, // 正常播放结束
    BDPVideoPlayerStateBreak, //播放中断Stop，但是没有播放结束
    BDPVideoPlayerStatePlaying,
    BDPVideoPlayerStatePaused,
    BDPVideoPlayerStateTimeUpdate,
    BDPVideoPlayerStateFullScreenChange,
    BDPVideoPlayerStateError,
    BDPVideoPlayerStateWaiting,
    BDPVideoPlayerStateSeekComplete,
    BDPVideoPlayerStateLoadedMetaData,
    BDPVideoPlayerStatePlaybackRateChange,
    BDPVideoPlayerStateMuteChange
};

typedef NS_ENUM(NSInteger, BDPVideoUserAction) {
    BDPVideoUserActionPlay,
    BDPVideoUserActionCenterPlay,
    BDPVideoUserActionMute,
    BDPVideoUserActionFullscreen,
    BDPVideoUserActionRetry,
    BDPVideoUserActionBack
};

@protocol BDPVideoViewDelegate;
@protocol BDPVideoPlayerControlProtocol <NSObject>

/**
 播放器当前的播放状态
 */
- (void)bdp_videoPlayerStateChange:(BDPVideoPlayerState)state videoPlayer:(UIView<BDPVideoViewDelegate> *)videoPlayer;

@optional
- (void)bdp_videoControlsToggle:(BOOL)show;
- (void)bdp_videoUserAction:(BDPVideoUserAction)action value:(BOOL)value;
- (void)bdp_videoError:(nullable NSError *)error;
- (void)bdp_videoErrorString:(nonnull NSString *)errorInfo;

@end

/**
 * 视频view的协议
 */
@protocol BDPVideoViewDelegate <NSObject>

@property (nonatomic, copy) NSString *componentID;
@property (nonatomic, strong) BDPVideoViewModel *model;
@property (nonatomic, weak) id<BDPVideoPlayerControlProtocol> delegate;

/**
 * 根据一个视频mdoel初始化一个视频view
 * @param model 视频的信息
 * @param componentID 组件ID
 * @return 返回一个播放器组件实例
 */
- (instancetype)initWithModel:(BDPVideoViewModel *)model
                  componentID:(NSString *)componentID;

/**
 * 根据一个视频model更新这个视频view
 * @param model 新的视频信息
 */
- (void)updateWithModel:(BDPVideoViewModel *)model;

@property (nonatomic, assign ,readonly) CGFloat currentTime;
@property (nonatomic, assign ,readonly) CGFloat duration;
@property (nonatomic, assign ,readonly) BOOL fullScreen;
@property (nonatomic, strong ,readonly) NSString* direction;
@property (nonatomic, assign, readonly) NSInteger videoWidth;
@property (nonatomic, assign, readonly) NSInteger videoHeight;
@property (nonatomic, assign, readonly) BOOL muted;
@property (nonatomic, assign, readonly) CGFloat playbackSpeed;

@optional

/// 播放
- (void)play;

/// 暂停
- (void)pause;

/// 停止
- (void)stop;

/// 继续
- (void)resume;

//点播
- (void)seek:(CGFloat)time completion:(void (^)(BOOL))completion;

/// 进入全屏
- (void)enterFullScreen;

/// 退出全屏
- (void)exitFullScreen;

/// 倍速播放
- (void)setPlaybackRate:(CGFloat)rate;

- (void)viewDidAppear;

- (void)viewWillDisappear;

@end


#endif /* BDPMediaPluginDelegate_h */
