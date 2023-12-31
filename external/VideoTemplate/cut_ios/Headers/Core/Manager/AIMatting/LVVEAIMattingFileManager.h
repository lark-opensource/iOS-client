//
//  LVVEAiMattingFileManager.h
//  VideoTemplate
//
//  Created by wuweixin on 2020/11/24.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LVMediaAsset.h"

NS_ASSUME_NONNULL_BEGIN



typedef void(^LVAIMattingMatchMattingCachePathCompletion)(NSString *cachePath, NSTimeInterval matchTimeInterval);
@interface LVVEAIMattingFileManager : NSObject

/// 获取该路径下文件的md5
/// @param absolutePath 媒体文件的绝对路径
- (NSString * _Nullable)md5OfFileAtAbsolutePath:(NSString *)absolutePath;
/// 获取该路径下文件matting缓存的路径
/// @param absolutePath 媒体文件的绝对路径
- (NSString * _Nullable)mattingCachePathWithAbsolutePath:(NSString *)absolutePath;
- (NSString * _Nullable)mattingCachePathWithAsset:(AVURLAsset *)asset;

- (void)matchMattingCachePathWithAsset:(LVMediaAsset *)mediaAsset completion:(LVAIMattingMatchMattingCachePathCompletion)completion;

/// 智能抠图文件管理根路径：Library/Caches/com.lemon.matting
+ (NSString * _Nonnull)rootPath;
/// 智能抠图文件缓存根路径：Library/Caches/com.lemon.matting/cache
+ (NSString * _Nonnull)cacheRootPath;
+ (NSString * _Nullable)md5OfFileAtAbsolutePath:(NSString *)absolutePath;
/// 根据文件md5获取matting缓存路径：Library/Caches/com.lemon.matting/cache/<fileMD5>
/// @param fileMD5 文件MD5
+ (NSString * _Nullable)mattingCachePathWithFileMD5:(NSString *)fileMD5;
/// 获取改路径下的文件的matting缓存路径
/// @param absolutePath 媒体文件的绝对路径
+ (NSString * _Nullable)mattingCachePathWithAbsoluteFilePath:(NSString *)absolutePath;
+ (unsigned long long)cacheFilesSize;
+ (void)cleanAllCacheFiles;

+ (void)cleanCacheFilesRegularlyIfNeeded;

@end

NS_ASSUME_NONNULL_END
