//
//  IESGurdDownloadProgressManager.h
//  IESGeckoKit
//
//  Created by bytedance on 2021/11/3.
//

#import <Foundation/Foundation.h>

#import "IESGurdDownloadProgressObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdDownloadProgressManager : NSObject

+ (instancetype)sharedManager;

- (void)observeAccessKey:(NSString *)accessKey
                 channel:(NSString *)channel
   downloadProgressBlock:(void(^)(NSProgress *progress))downloadProgressBlock;

- (IESGurdDownloadProgressObject *)progressObjectForIdentity:(NSString *)identity;

- (void)removeObserverWithIdentity:(NSString *)identity;

@end

NS_ASSUME_NONNULL_END
