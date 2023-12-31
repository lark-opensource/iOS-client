//
//  ACCEffectMessageDownloader.h
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/11/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCEffectMessageDownloader : NSObject

/// 清理下载的缓存
+ (void)cleanCache;

+ (nonnull instancetype)sharedDownloader;

/// 下载单个文件
/// @param urlList 同一个资源文件不同的 url，域名不一样，路径相同
/// @param needUpzip 下载完是否需要解压
/// @param completion 结果回调
- (void)downloadWithUrlList:(NSArray<NSString *> *)urlList
                  needUpzip:(BOOL)needUpzip
                 completion:(void(^)(NSURL * _Nullable filePath, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
