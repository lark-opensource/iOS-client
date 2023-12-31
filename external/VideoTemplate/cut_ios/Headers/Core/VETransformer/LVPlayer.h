//
//  LVPlayer.h
//  Pods
//
//  Created by zenglifeng on 2019/8/11.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <TTVideoEditor/HTSVideoData.h>
#import "LVPlayerItem.h"

@class LVPlayer;

typedef void(^LVExportProgressHandler)(CGFloat);
typedef void(^LVExportCompletionHandler)(NSError *_Nullable, int, NSURL *_Nullable);

typedef NS_ENUM(NSUInteger, LVPlayerSeekMode) {
    LVPlayerSeekModeSmooth, // 平滑模式，可以是接近的帧
    LVPlayerSeekModeAccurate, // 精准模式，返回帧是准的
};

NS_ASSUME_NONNULL_BEGIN

@protocol LVPlayerDelegate <NSObject>

@optional
/**
 播放器进度更新
 */
- (void)player:(LVPlayer *)player progressDidChanged:(double)progress;

/**
 暂停播放器
 */
- (void)playerDidPause:(LVPlayer *)player;

/**
 暂停播放器
 */
- (void)playerDidPlay:(LVPlayer *)player;

/**
 播放器数据更新完成
 */
- (void)playerDidUpdateVideoData:(LVPlayer *)player;

/**
 画布比例更新
 */
- (void)playerDidUpdateCanvasSize:(LVPlayer *)player;

/**
 画布首帧
 */
- (void)playerDidUpdateCanvasFrame:(LVPlayer *)player;

/// 打开草稿后首帧渲染
/// @param player 播放器
- (void)playerDidFirstRender:(LVPlayer *)player;

/**
 添加信息化贴纸
*/
- (void)player:(LVPlayer *)player didAddSticker:(NSInteger)taskID;

/// 关键帧信息
- (void)player:(LVPlayer *)player didUpdateAllKeyframe:(LVAllKeyframe *)allKeyframe;

/*
 * 实时更新视频音量关键帧信息
 */
- (void)playerDidUpdateAudioKeyframeWithPts:(NSUInteger)pts audioVolumeDic:(NSMutableDictionary<AVAsset *,NSNumber *> *)audioVolumeDic;

@end

@interface LVPlayer : UIView

@property (nonatomic, weak) id<LVPlayerDelegate>delegate;

@property (nonatomic, strong, readonly) LVPlayerItem *playItem;

@property (nonatomic, strong, readonly) LVAIMattingManager *mattingManager;

/**
 恢复前台是否自动恢复
 */
@property (nonatomic, assign) BOOL autoPlayWhenAppBecomeActive;

/**
 自动循环播放
 */
@property (nonatomic, assign) BOOL autoRepeatPlay;

- (instancetype)initWithFrame:(CGRect)frame playItem:(LVPlayerItem *)playItem;

/**
 播放状态
 */
- (BOOL)isPlaying;

/**
 当前播放时间
 */
- (CMTime)currentTime;

/**
 更新画布尺寸
 */
- (void)reloadCanvasSize;

/**
 获取最近1s的帧率
*/
- (CGFloat)lastPlayFrameRate;

- (NSDictionary <NSString *, NSNumber*> *)getFirstRenderTimeDic;

@end

@interface LVPlayer (Control)

/**
 暂停
 */
- (void)pause;

/**
 播放
 */
- (void)play;

/**
 预览timeRange时间范围内的视频
 */
- (void)playWithinTimeRange:(CMTimeRange)timeRange;

/**
立即预览timeRange时间范围内的视频， 不等待seek回调
*/
- (void)immediatelyPlayWithinTimeRange:(CMTimeRange)timeRange;

/// seek
/// @param time 时间
/// @param seekMode seek 模式
/// @param completion seek 完成回调，不关心就传 nil
- (void)seekToTimeAndRender:(CMTime)time seekMode:(LVPlayerSeekMode)seekMode completion:(void (^_Nullable)(BOOL finished))completion;

@end

NS_ASSUME_NONNULL_END
