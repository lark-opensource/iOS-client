//
//  IESGurdKit+ExtraParams.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/3/18.
//

#import "IESGeckoKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdKit (ExtraParams)

+ (void)setAppId:(NSString *)appId;

+ (void)registerAccessKey:(NSString *)accessKey channels:(NSArray *)channels;

+ (void)syncResourcesWithAccessKey:(NSString *)accessKey
                          channels:(NSArray<NSString *> *)channelArray
                   resourceVersion:(NSString * _Nullable)resourceVersion
                        completion:(IESGurdSyncStatusDictionaryBlock)completion;

+ (void)syncResourcesWithAccessKey:(NSString *)accessKey
                          channels:(NSArray<NSString *> *)channelArray
                   resourceVersion:(NSString * _Nullable)resourceVersion
                         forceSync:(BOOL)forceSync
                        completion:(IESGurdSyncStatusDictionaryBlock)completion;

@end

NS_ASSUME_NONNULL_END
