//
//  IESGurdKit+DownloadProgress.h
//  IESGeckoKit
//
//  Created by bytedance on 2021/11/4.
//

#import "IESGeckoKit.h"

#import "IESGurdDownloadProgressObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdKit (DownloadProgress)

+ (void)observeDownloadProgressWithAccessKey:(NSString *)accessKey
                                     channel:(NSString *)channel
                               progressBlock:(void(^)(NSProgress *progress))downloadProgressBlock;

+ (IESGurdDownloadProgressObject *)progressObjectForIdentity:(NSString *)identity;

+ (void)removeObserverWithIdentity:(NSString *)identity;

@end

NS_ASSUME_NONNULL_END
