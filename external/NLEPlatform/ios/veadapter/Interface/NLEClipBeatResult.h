//
//  NLEClipBeatResult.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/5/31.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/HTSVideoData.h>

NS_ASSUME_NONNULL_BEGIN

/*
 ---------- 业务侧调用NLEBingoManager之后返回的卡点数据结构 ----------
 */

@interface NLEClipBeatResult : NSObject

/// 音频数据
@property (nonatomic, copy, readonly) NSArray<AVAsset *> *audioAssets;

/// 音频剪辑数据
@property (nonatomic, copy, readonly) NSDictionary<AVAsset *, IESMMVideoDataClipRange*> *audioTimeClipInfo;

/// 照片电影
@property (nonatomic, copy) NSDictionary<AVAsset *, NSURL *> *_Nonnull photoAssetsInfo;

/// 照片电影资源(标识顺序)
@property (nonatomic, copy, readonly) NSArray<AVAsset *> *photoMovieAssets;

/// 图片素材的transform，用于zoom in/out效果
@property (nonatomic, copy, readonly) NSDictionary<AVAsset *, IESMMVideoTransformInfo *> *assetTransformInfo;

/// 视频段之间转场类型
@property (nonatomic, copy, readonly) NSDictionary<AVAsset *, IESMediaFilterInfo *> *movieAnimationType;

/// 视频填充模式
@property (nonatomic, copy, readonly) NSDictionary<AVAsset *, NSNumber *> *_Nonnull movieInputFillType;

/// Bingo asset和videokey的对应关系
@property (nonatomic, copy, readonly) NSDictionary * bingoVideoKeys;

/// 视频段数据（有序）
@property (nonatomic, copy, readonly) NSArray<AVAsset *> *videoAssets;

/// 音频音量数据 NSNumber(float)
@property (nonatomic, copy, readonly) NSDictionary<AVAsset *, NSArray<NSNumber *> *> *volumnInfo;

/// 视频播放速率数据 NSNumber(CGFloat)
@property (nonatomic, copy, readonly) NSDictionary<AVAsset *, NSNumber *> *videoTimeScaleInfo;

/// 视频剪辑数据
@property (nonatomic, copy, readonly) NSDictionary<AVAsset *, IESMMVideoDataClipRange *> *videoTimeClipInfo;

/// 需通过VideoData初始化
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithVideoData:(HTSVideoData *)videoData;

@end

NS_ASSUME_NONNULL_END
