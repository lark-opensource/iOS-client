//
//  TTAdSplashVideoView.h
//  TTAdSplashSDK
//
//  Created by yin on 2017/8/7.
//  Copyright © 2017年 yin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTAdSplashHeader.h"
#import "BDASplashVideoContainer.h"

@protocol BDASplashVideoViewDelegate;
@class TTAdSplashModel;

@interface TTAdSplashVideoView : UIView <BDASplashVideoProtocol>

@property (nonatomic, weak) id<BDASplashVideoViewDelegate> delegate;
@property (nonatomic, assign) BOOL mute;
@property (nonatomic, assign) BOOL pauseAtInit;    ///<是否初始化完成不直接播放，先暂停
@property (nonatomic, assign) CGFloat volume;      ///< 通过外部设置音量，从互动开屏声音开关按钮开始有效,范围0~1
@property (nonatomic, assign) BOOL sendMuteEvent;  ///<是否发送静音埋点

- (instancetype)initWithModel:(TTAdSplashModel *)model;

/// 互动视频时单独传入视频ID
/// @param model 广告数据
/// @param videoId 视频ID
- (instancetype)initWithModel:(TTAdSplashModel *)model videoId:(NSString *)videoId sendMuteEvent:(BOOL)sendMuteEvent;

/// 开始播放
- (void)play;

/// 暂停播放
- (void)pause;

/// 设置从什么位置播放
/// @param seconds 播放的位置,精确到秒
- (void)seekToTime:(CGFloat)seconds;

@end
