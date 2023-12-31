//
//  BDLGeckoProtocol.h
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDLGurdSyncStatusDictionaryBlock)(BOOL succeed,
                                                 NSDictionary<NSString *, NSNumber *> *dict);

// 某个channel文件类型
typedef NS_ENUM(NSInteger, BDLGurdChannelFileType) {
  BDLGurdChannelFileTypeCompressed,
  BDLGurdChannelFileTypeUncompressed,
  BDLGurdChannelFileTypeSettingsFile,
  BDLGurdChannelFileTypeSettingsData
};

@protocol BDLGeckoProtocol <NSObject>

/*
@brief 获取 Gecko 目前使用的 accessKey
*/
- (NSString *)accessKey;

/*
@brief 普通优先级默认延迟请求时长，单位ms
*/
- (NSUInteger)normalPolicyDelaySyncTime;

/**
 为特定accessKey动态注册channels
 */
- (void)registerChannels:(NSArray<NSString *> *)channels forAccessKey:(NSString *)accessKey;

/*
 @brief 同步指定channel资源
 */
- (void)syncResourcesChannels:(NSArray<NSString *> *)channelArray
                   completion:(BDLGurdSyncStatusDictionaryBlock)completion;

/**
 同步指定accessKey下的channels资源
 */
- (void)syncResourcesForAccessKey:(NSString *)accessKey
                         channels:(NSArray<NSString *> *)channels
                       completion:(BDLGurdSyncStatusDictionaryBlock)completion;

/**
 返回指定accessKey的根目录
 */
- (NSString *)rootDirectoryForAccessKey:(NSString *)accessKey;

/**
 返回指定accessKey和channel的根目录
 */
- (NSString *)rootDirectoryForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 返回默认accessKey下制定channel的根目录
 */
- (NSString *)rootDirectoryForChannel:(NSString *)channel;

- (BDLGurdChannelFileType)fileTypeForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

@optional
/// gecko 没下载时兜底页面，需要宿主内置
- (nonnull NSString *)defaultFileForGroupID:(nonnull NSString *)groupID;
- (nonnull NSString *)defaultFilerootDirForGroupID:(nonnull NSString *)groupID;

/// 默认groupID
- (nonnull NSString *)defaultGroupID;

/**
 * @brief 更新指定的包，准备好缓存环境。
 *
 * @param accessKey     business的部署key
 * @param channelArray  指定的channel
 * @param businessDomain 业务域名
 * @param forceSync     是否强制请求，如果是，忽略 +[IESGurdKit enable]
 * @param completion    completion
 */
- (void)syncResourcesWithAccessKey:(NSString *)accessKey
                          channels:(NSArray<NSString *> *)channelArray
                   resourceVersion:(NSString *_Nullable)resourceVersion
                    businessDomain:(NSString *_Nullable)businessDomain
                         forceSync:(BOOL)forceSync
                        completion:(BDLGurdSyncStatusDictionaryBlock)completion;

/**
  sync resources with extra custom params
 */
- (void)syncResourcesWithAccessKey:(NSString *)accessKey
                          channels:(NSArray<NSString *> *)channelArray
                    businessDomain:(NSString *_Nullable)businessDomain
                         forceSync:(BOOL)forceSync
                      customParams:(NSDictionary *_Nullable)customParams
                        completion:(BDLGurdSyncStatusDictionaryBlock)completion;

/**
 * @brief 更新指定的包，准备好缓存环境。
 *
 * @param accessKey     business的部署key
 * @param channelArray  指定的channel
 * @param businessDomain 业务域名
 * @param completion    completion
 */
- (void)syncResourcesWithAccessKey:(NSString *)accessKey
                          channels:(NSArray<NSString *> *)channelArray
                   resourceVersion:(NSString *_Nullable)resourceVersion
                    businessDomain:(NSString *_Nullable)businessDomain
                        completion:(BDLGurdSyncStatusDictionaryBlock)completion;

/**
  sync resources with extra custom params
 */
- (void)syncResourcesWithAccessKey:(NSString *)accessKey
                          channels:(NSArray<NSString *> *)channelArray
                    businessDomain:(NSString *_Nullable)businessDomain
                      customParams:(NSDictionary *_Nullable)customParams
                        completion:(BDLGurdSyncStatusDictionaryBlock)completion;

@end

NS_ASSUME_NONNULL_END
