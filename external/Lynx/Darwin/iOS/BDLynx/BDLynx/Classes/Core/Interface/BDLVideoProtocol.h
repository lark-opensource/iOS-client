//
//  BDLVideoProtocol.h
//  AFgzipRequestSerializer
//
//  Created by zys on 2020/2/16.
//

#import <Foundation/Foundation.h>
@class BDLVideoModel;

NS_ASSUME_NONNULL_BEGIN

@protocol BDLVideoProtocol <NSObject>

/**
 * 播放之前初始化Model和播放器
 * @param videoModel 视频数据模型
 */
- (void)setVideoModel:(BDLVideoModel *)videoModel;

/**
 * 获取播放器 View 实例
 */
- (UIView *)playerView;

/**
 * 开始播放
 */
- (void)start;

/**
 * 暂停播放
 */
- (void)pause;

/**
 * 暂停播放
 */
- (void)stop;

/**
 * 设置时间进度
 */
- (void)seekToTime:(NSTimeInterval)timeInSeconds;

@end

NS_ASSUME_NONNULL_END
