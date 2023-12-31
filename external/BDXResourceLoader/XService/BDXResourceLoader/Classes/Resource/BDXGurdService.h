//
//  BDXGurdService.h
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#ifndef BDXGurdService_h
#define BDXGurdService_h

#import <IESGeckoKit/IESGeckoDefines.h>
#import "BDXGurdConfigDelegate.h"
#import "BDXGurdSyncTask.h"

@interface BDXGurdService : NSObject

@property(class, nonatomic, copy) id<BDXGurdConfigDelegate> configDelegate;

/*
 @brief 获取 BDX 目前使用的 accessKey
 */
+ (NSString *)accessKey;

/**
 注册accessKey
 */
+ (void)registerAccessKey:(NSString *)accessKey;

/**
 返回指定accessKey的根目录
 */
+ (NSString *)rootDirectoryForAccessKey:(NSString *)accessKey;

/**
 返回指定accessKey和channel的根目录
 */
+ (NSString *)rootDirectoryForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/// 返回指定channel的文件类型
/// @param accessKey accessKey
/// @param channel channel
+ (IESGurdChannelFileType)fileTypeForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 * @brief 返回文件版本；如果文件未激活，则返回0
 */
+ (uint64_t)packageVersionForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 根据accessKey和channel清理对应的缓存;
 */
+ (void)clearCacheForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 同步资源
*/
+ (void)syncResourcesWithTask:(BDXGurdSyncTask *)task completion:(IESGurdSyncStatusDictionaryBlock)completion;

+ (BOOL)hasCacheForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel;

+ (NSData *)dataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel;

+ (BOOL)isRequestThrottledWithStatusDictionary:(NSDictionary *)statusDictionary;

@end

#endif /* BDXGurdService_h */
