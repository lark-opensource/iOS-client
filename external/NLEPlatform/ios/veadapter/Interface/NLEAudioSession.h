//
//  NLEAudioSession.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/4/26.
//

#import <Foundation/Foundation.h>

@class AVAsset;
@class IESMMTranscodeRes;
@class IESMMAudioDetectionConfig;

NS_ASSUME_NONNULL_BEGIN

typedef void (^NLEAudioExportBlock)(NSURL * _Nullable url, NSError * _Nullable error);
typedef void (^NLEVoiceBlanceDetectCompletionBlock)(IESMMTranscodeRes *_Nullable result, NSMutableArray<IESMMAudioDetectionConfig *> *detectConfigs);

@interface NLEAudioSession : NSObject

// 需要通过NLEInterface_OC的 - (NLEAudioSession *)audioSession; 获取该对象
- (instancetype)init NS_UNAVAILABLE;

// 获取volumeInfo
- (NSDictionary<AVAsset *, NSArray<NSNumber *> *> *)volumeInfo;

/**
 * @brief 获取视频波形图
 * @param pointsCount 提取点数
 */
- (void)getVolumnWaveForVideoWithPointsCount:(NSUInteger)pointsCount
                                  completion:(void (^)(NSArray * _Nullable values, NSError * _Nullable error))completion;

/**
 * @brief 获取视频波形图
 * @param videoPath 视频绝对路径
 * @param pointsCount 提取点数
 */
+ (void)getVolumnWaveForVideoWithVideoPath:(NSString *)videoPath
                                pointCount:(NSUInteger)pointsCount
                                completion:(void (^)(NSArray * _Nullable values, NSError * _Nullable error))completion;
                            

/**
 * @brief 获取音频波形图
 * @param audioPath 音频绝对路径
 * @param duration 时长
 * @param pointsCount 提取点数
 * @return 波形数组，存储double类型数据
 */
+ (NSArray *)getVolumnWaveForAudioWithAudioPath:(NSString *)audioPath
                                       duration:(CGFloat)duration
                                    pointsCount:(NSUInteger)pointsCount;

// 抽取视频中的所有音频
- (void)exportAllAudioSound:(void (^)(NSURL * _Nullable outputURL, NSError * _Nullable error))completion;

/**
 * @brief 提取视频轨道的音频
 * @param completion NLEAudioExportBlock
 */
- (void)exportVideoTrackAudio:(NLEAudioExportBlock)completion;

/// 检测视频或者音频的声音最佳平衡度参数
/// @param forVideoAssets BOOL  处理视频资源还是音频资源
/// @param completion NLEVoiceBlanceDetectCompletionBlock
- (void)getVoiceBalanceDetectConfigForVideoAssets:(BOOL)forVideoAssets
                                       completion:(NLEVoiceBlanceDetectCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
