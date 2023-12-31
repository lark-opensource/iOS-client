//
//  IESGurdKit+DownloadProgress.m
//  IESGeckoKit
//
//  Created by bytedance on 2021/11/4.
//

#import "IESGurdKit+DownloadProgress.h"

#import "IESGurdDownloadProgressManager.h"

@implementation IESGurdKit (DownloadProgress)

+ (void)observeDownloadProgressWithAccessKey:(NSString *)accessKey
                                     channel:(NSString *)channel
                               progressBlock:(void(^)(NSProgress *progress))downloadProgressBlock
{
    [[IESGurdDownloadProgressManager sharedManager] observeAccessKey:accessKey
                                                             channel:channel
                                               downloadProgressBlock:downloadProgressBlock];
}

+ (IESGurdDownloadProgressObject *)progressObjectForIdentity:(NSString *)identity
{
    return [[IESGurdDownloadProgressManager sharedManager] progressObjectForIdentity:identity];
}

+ (void)removeObserverWithIdentity:(NSString *)identity
{
    [[IESGurdDownloadProgressManager sharedManager] removeObserverWithIdentity:identity];
}

@end
