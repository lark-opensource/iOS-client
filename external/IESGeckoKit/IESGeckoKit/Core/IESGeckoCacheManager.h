//
//  IESGurdCacheManager.h
//  IESGurdKit
//
//  Created by willorfang on 2017/11/2.
//
//

#import "IESGeckoResourceModel.h"
#import "IESGeckoDefines.h"
#import "IESGeckoDefines+Private.h"

@class IESGurdCacheConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdCacheManager : NSObject

/**
 * @brief 将所有未激活的缓存进行激活
 */
+ (void)applyAllInactiveCacheWithCompletion:(IESGurdSyncStatusBlock)completion;

/**
 * @brief 将指定accesskey & channel下未激活的缓存进行激活
 */
+ (void)applyInactiveCacheForAccessKey:(NSString *)accessKey
                               channel:(NSString *)channel
                            completion:(IESGurdSyncStatusBlock)completion;

/**
 1）请求最新的package配置信息
 2）下载最新package包，解压、激活
 */
+ (void)syncResourcesWithParams:(IESGurdFetchResourcesParams *)params
                     completion:(IESGurdSyncStatusDictionaryBlock)completion;

#pragma mark - Cache management

/**
 * @brief 是否有缓存
 *
 * @param path      文件相对路径
 * @param accessKey 包名
 * @param channel   渠道名
 *                  文件绝对路径：Library/Caches/IESWebCache/<accessKey>/<channel>/<path>
 */
+ (BOOL)hasCacheForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
* @brief 读取缓存数据
*/
+ (NSData *)dataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel options:(NSDataReadingOptions)options;

+ (NSData *)offlineDataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
* @brief 异步读取缓存数据
*/
+ (void)asyncGetDataForPath:(NSString *)path
                  accessKey:(NSString *)accessKey
                    channel:(NSString *)channel
                 completion:(IESGurdAccessResourceCompletion)completion;

/**
 * @brief 返回文件类型；如果文件未激活，则返回-1
 */
+ (IESGurdChannelFileType)fileTypeForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
* @brief 返回文件版本；如果文件未激活，则返回0
*/
+ (uint64_t)packageVersionForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 * @brief 获取指定accessKey根目录
 */
+ (NSString *)rootDirForAccessKey:(NSString *)accessKey;

/**
 * @brief 获取指定channel根目录
 */
+ (NSString *)rootDirForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 返回channel缓存的状态
 */
+ (IESGurdChannelCacheStatus)cacheStatusForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

+ (void)addCacheWhitelistWithAccessKey:(NSString *)accessKey
                              channels:(NSArray<NSString *> *)channels;
/**
 * @brief 清除cache
 */
+ (void)clearCache;

+ (void)clearCacheExceptWhitelist;

/**
 根据accessKey和channel清理对应的缓存;
 */
+ (void)clearCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel;

#pragma mark - Clean

/**
 设置缓存策略
 */
+ (void)setCacheConfiguration:(IESGurdCacheConfiguration *)configuration
                 forAccessKey:(NSString *)accessKey;

/**
 添加channel白名单，不被清理
 */
+ (void)addChannelsWhitelist:(NSArray<NSString *> *)channels
                forAccessKey:(NSString *)accessKey;

@end

NS_ASSUME_NONNULL_END
