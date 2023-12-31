//
//  ACCEditVideoDataConsumer.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/14.
//

#import <Foundation/Foundation.h>
#import "ACCEditVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditVideoDataConsumer : NSObject

+ (void)restartReverseAssetForVideoData:(ACCEditVideoData *)videoData
                             completion:(void (^)(void))completion;

// 获取视频中音频的波形图
+ (void)getVolumnWaveWithVideoData:(ACCEditVideoData *)videoData
                       pointsCount:(NSUInteger)pointsCount
                        completion:(void (^)(NSArray * _Nullable values, NSError * _Nullable error))completion;

// 获取音频波形图
+ (NSArray *)getVolumnWaveWithAudioURL:(NSURL *)audioURL
                      waveformduration:(CGFloat)waveformduration
                           pointsCount:(NSUInteger)pointsCount;

// 保存 videoData
+ (void)saveVideoData:(ACCEditVideoData *)videoData
toFileUsePropertyListSerialization:(NSString *_Nullable)filePath
           completion:(nullable void(^)(BOOL saved, NSError * _Nullable error))completion;

// 保存 videoData
+ (BOOL)saveDictionaryToPath:(NSString *)path
                        dict:(NSDictionary *)dict
                       error:(NSError *__autoreleasing*)error;

// 读取 videoData dictionary
+ (NSDictionary *)readDictionaryFromPath:(NSString *)path
                                   error:(NSError *__autoreleasing*)error;

// 读取 videoData
+ (void)loadVideoDataFromDictionary:(NSDictionary *)dataDict
                        draftFolder:(NSString *)draftFolder
                         completion:(nullable void (^)(ACCEditVideoData *_Nullable videoData, NSError *_Nullable error))completion;

// 读取 videoData
+ (void)loadVideoDataFromFile:(NSString *_Nullable)filePath
                   completion:(nullable void(^)(ACCEditVideoData * _Nullable videoData, NSError * _Nullable error))completion;

// 设置缓存路径
+ (void)setCacheDirPath:(NSString *)cacheDirPath;

/// 返回CacheDirPath是否被业务层设置过的信息，用于确认存草稿时，文件是否还需要copy
+ (BOOL)isCacheDirPathSetted;

/// 缓存文件夹路径
+ (NSString *)cacheDirPath;

/// 默认缓存文件路径
+ (NSString *)defaultCachePath;

/// 清除cacheDirPath下所有缓存（如果设置过缓存文件夹路径，则影响已持久化的数据）（建议在整个发布/存草稿流程结束之后调用）
+ (void)clearAllCache;

/// 是否是占位 videoAsset
/// @param asset 输入 asset
+ (BOOL)isPlaceholderVideoAssets:(AVAsset *)asset;

@end

NS_ASSUME_NONNULL_END
