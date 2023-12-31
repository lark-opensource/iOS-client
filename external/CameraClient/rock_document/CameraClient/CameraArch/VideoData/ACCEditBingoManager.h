//
//  ACCEditBingoManager.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/14.
//

#import <Foundation/Foundation.h>
#import "ACCEditVideoData.h"
#import <AVFoundation/AVFoundation.h>
#import <TTVideoEditor/IESMMBingoManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditBingoManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDraftFolder:(NSString *)draftFolder;

/**
 设置背景音乐

 @param musicPath 音乐地址
 */
- (void)setMusic:(NSString *)musicPath;

/**
 设置音乐裁剪区域

 @param startTime 起始点
 @param duration 长度
 @param completion 回调
 */
- (void)changeMusic:(NSTimeInterval)startTime
           duration:(NSTimeInterval)duration
         completion:(void (^)(int ret))completion;

/**
 设置音乐算法数据(划分音乐点模式不设置手动干预文件，其他的可以为空；一次卡点模式A0、C、收到干预文件互斥必须有一个)
 */
- (void)setStoredBeats:(IESMMBingoBeats *)beats
            completion:(void (^)(int))completion;

/**
 插入视频

 @param videoPath 视频地址
 @param pos 相对位置(从0开始)
 @param completion 回调闭包
 */
- (void)insertVideo:(NSString *)videoPath
                pos:(int)pos
         completion:(void (^)(NSString *key))completion;

/**
 插入视频
 
 @param picPath 图片地址
 @param pos 相对位置(从0开始)
 @param completion 回调闭包
 */
- (void)insertPic:(NSString *)picPath
      picDuration:(float)picDuration
              pos:(int)pos
       completion:(void (^)(NSString *_Nonnull))completion;

/**
 交换视频位置

 @param oldPos 交换前的位置
 @param newPos 交换后的位置
 */
- (void)moveVideoInPos:(NSInteger)oldPos
                 toPos:(NSInteger)newPos
            completion:(void (^)(bool ret))completion;

/**
 删除指定位置的视频

 @param pos 位置
 */
- (void)deleteVideoWithPos:(NSInteger)pos
                completion:(void (^)(bool ret))completion;

/**
 key对应的视频开始抽针

 @param key 视频标识
 @param range 区间
 @param interval 抽针间隔
 */
- (void)generateVideo:(NSString *)key
                range:(CMTimeRange)range
             interval:(NSTimeInterval)interval
             progress:(void (^)(float percent))progress completion:(IESMMBingoGenertorBlock)completion;

/**
 取消抽帧

 @param key 视频标识
 */
- (void)cancleGenerateVideo:(NSString *)key;

/**
 获取随机结果

 @param completion 设置音频算法数据之后通过该接口获取随机预览数据
 */
- (void)getRandomReslove:(void (^)(ACCEditVideoData *))completion;

/**
 获取一键卡点结果(所有视频跑完之后才能调用)

 @param completion 回调闭包
 */
- (void)getReslove:(void (^)(ACCEditVideoData *))completion;

/**
 根据videodata生成Item

 @param videodata videodata
 */
- (AVPlayerItem *)makeItemWithVideodata:(ACCEditVideoData *)videodata;

/**
智能数据回流文件路径
@param path 文件路径
*/
- (int)saveInterimScoresToFile:(NSString *)filePath;

/**
检查智能数据回流文件是否合法
@param path 文件路径
*/
- (int)checkScoreFile:(NSString *)filePath;

#pragma mark - 类方法

+ (AVPlayerItem *)makeItemWithVideoData:(ACCEditVideoData *)videodata;

/// 插入图片
+ (void)insertPic:(NSURL *)picUrl
         duration:(float)duration
        transform:(IESMMVideoTransformInfo *)transfomInfo
      toVideoData:(ACCEditVideoData *)videodata;
/// 插入视频
+ (void)insertVideo:(AVAsset *)asset
          clipRange:(IESMMVideoDataClipRange *)clipRange
        toVideoData:(ACCEditVideoData *)videodata;
/// 设置图片或视频播放速率
+ (void)setRate:(CGFloat)rate
forAssetAtIndex:(NSUInteger)index
      videoData:(ACCEditVideoData *)videoData;
/// 设置图片或视频裁剪区间
+ (void)setClipRange:(IESMMVideoDataClipRange *)clipRange
     forAssetAtIndex:(NSUInteger)index
           videoData:(ACCEditVideoData *)videoData;
/// 设置图片或视频旋转
+ (void)setRotateType:(NSNumber *)rotateType
      forAssetAtIndex:(NSUInteger)index
            videoData:(ACCEditVideoData *)videoData;
/// 删除图片或者视频
+ (void)deleteAsset:(AVAsset *)asset
      toVideeeoData:(ACCEditVideoData *)videodata;
/// 调整图片或视频顺序
+ (void)moveAssetFromIndex:(NSUInteger)fromIndex
                   toIndex:(NSUInteger)toIndex
                 videoData:(ACCEditVideoData *)videoData;
/// 设置图片zoom in zoom out效果
+ (void)setTransformInfo:(IESMMVideoTransformInfo *)transformInfo
         forAssetAtIndex:(NSUInteger)index
               videoData:(ACCEditVideoData *)videoData;

@end

NS_ASSUME_NONNULL_END
