//
//  IESGeckoKit.h
//  IESGeckoKit
//
//  Created by willorfang on 2017/8/7.
//
//

#import <Foundation/Foundation.h>
#import "IESGeckoDefines.h"
#import "IESGurdProtocolDefines.h"
#import "IESGurdCacheConfiguration.h"
#import "IESGurdFetchResourcesParams.h"
#import "IESGurdLoadResourcesParams.h"
#import "IESGurdLazyResourcesInfo.h"
#import "IESGurdRegisterModel.h"

NS_ASSUME_NONNULL_BEGIN

#define IESGeckoKit IESGurdKit
#define IESGeckoNetworkDelegate IESGurdNetworkDelegate
#define IESGeckoKitSDKVersion IESGurdKitSDKVersion
#define IESGeckoKitDidRegisterAccessKeyNotification IESGurdKitDidRegisterAccessKeyNotification

#define kIESGurdKitRegisterAccesskey "kIESGurdKitRegisterAccesskey"
#define IESGurdKitRegisterAccesskeyFunction GAIA_FUNCTION(kIESGurdKitRegisterAccesskey)
#define IESGurdKitRegisterAccesskeyMethod GAIA_METHOD(kIESGurdKitRegisterAccesskey)

#define IESGeckoHasSettingFeature 1

FOUNDATION_EXTERN NSString *IESGurdKitSDKVersion(void);

@interface IESGurdKit : NSObject

@property (class, nonatomic, assign) IESGurdEnvType env;

@property (class, assign) BOOL enable; // default YES

@property (class, nonatomic, copy) NSString *deviceID; // DeviceID。统计用。 注意：需要在syncResources之前进行设置。
@property (class, nonatomic, copy, readonly) NSString *appId;
@property (class, nonatomic, copy, readonly) NSString *appVersion;

@property (class, nonatomic, copy) NSString *(^getDeviceID)(void);

@property (class, nonatomic, copy) NSString *platformDomain; // Gecko 系统的domain; 注意：需要在syncResources之前进行设置。

@property (class, nonatomic, assign, getter=isLogEnabled) BOOL logEnable; // 废弃

@property (class, nonatomic, assign, getter=isEventTraceEnabled) BOOL eventTraceEnabled; // 开启内存日志（线上环境不开启）

@property (class, nonatomic, strong) id<IESGurdNetworkDelegate> _Nullable networkDelegate; // 设置网络代理

@property (class, nonatomic, strong) id<IESGurdDownloaderDelegate> _Nullable downloaderDelegate; // 设置下载代理

@property (class, nonatomic, strong) id<IESGurdAppLogDelegate> _Nullable appLogDelegate;

@property (class, nonatomic, copy) NSDictionary<NSString *, NSDictionary<NSString *, NSArray<NSString *> *> *> *prefetchChannels;

#pragma mark - Config

/**
 * @brief 返回是否已配置
 * 在请求资源前必须先调用 +[IESGurdKit setupWithAppId:appVersion:cacheRootDirectory:]
 */
+ (BOOL)didSetup;

/**
 * @brief 返回配置时间戳
 */
+ (NSInteger)setupTimestamp;

/**
 * @brief 设置基本参数
 * @param appId                  应用id
 * @param appVersion             应用版本
 * @param cacheRootDirectory     Gecko系统的cache根目录；可为空，默认 Library/Caches/IESWebCache/
 *
 * 注意：尽可能提前设置
 */
+ (void)setupWithAppId:(NSString * _Nonnull)appId
            appVersion:(NSString * _Nonnull)appVersion
    cacheRootDirectory:(NSString * _Nullable)cacheRootDirectory;

/**
 * @brief Gecko 系统的cache根目录
 */
+ (NSString *)cacheRootDir;

/**
 * @brief 应用id
 */
+ (NSString *)appId;

/**
 * @brief 应用版本
 */
+ (NSString *)appVersion;

/**
 注册事件代理；内部弱持有
 */
+ (void)registerEventDelegate:(id<IESGurdEventDelegate>)eventDelegate;

/**
 反注册事件代理
 */
+ (void)unregiserEventDelegate:(id<IESGurdEventDelegate>)eventDelegate;

/**
 * @brief 注册要更新的accessKey
 *
 * 注意 : 需要在syncResources之前进行设置。
 */
+ (void)registerAccessKey:(NSString *)accessKey;

/**
 * @brief 注册要更新的accessKey
 *
 * 注意 : 需要在syncResources之前进行设置。
 */
+ (void)registerAccessKey:(NSString *)accessKey
               SDKVersion:(NSString *)SDKVersion;


/**
 * @brief 给accessKey添加更新请求的custom参数
 *
 * 注意 : 需要在syncResources之前进行设置。
 与registerAccessKey的行为有些区别，registerAccessKey对于每个accessKey只有第一次调用有效
 这个函数可以多次调用添加customParams，为了直播ak下包含多个业务，可能会有多次调用的情况
 */
+ (void)addCustomParamsForAccessKey:(NSString *)accessKey
                       customParams:(NSDictionary * _Nullable)customParams;

/**
 所有注册信息
 */
+ (NSArray<IESGurdRegisterModel *> *)allRegisterModels;

/**
 设置请求 header field
 */
+ (void)setRequestHeaderFieldBlock:(NSDictionary<NSString *, NSString *> *(^)(void))block;

/**
 持久化日志代理
 */
+ (void)addGurdLogDelegate:(id<IESGurdLogProxyDelegate>)logDelegate;

/**
 移除日志代理
 */
+ (void)removeGurdLogDelegate:(id<IESGurdLogProxyDelegate>)logDelegate;

/**
 拉取 settings
 */
+ (void)fetchSettings;

/**
 清理 settings 缓存
 */
+ (void)cleanSettingsCache;

/**
 锁住channel，本次生命周期不再更新
 */
+ (void)lockChannel:(NSString *)accessKey channel:(NSString *)channel;

/**
 解锁channel
 */
+ (void)unlockChannel:(NSString *)accessKey channel:(NSString *)channel;

/**
 channel是否被锁了
 */
+ (BOOL)isChannelLocked:(NSString *)accessKey channel:(NSString *)channel;

#pragma mark - Apply

/**
 * @brief 将所有未激活的缓存进行激活
 */
+ (void)applyInactivePackages:(IESGurdSyncStatusBlock _Nullable)completion;

/**
 * @brief 将指定accesskey & channel下未激活的缓存进行激活
 */
+ (void)applyInactivePackageForAccessKey:(NSString *)accessKey
                                 channel:(NSString *)channel
                              completion:(IESGurdSyncStatusBlock _Nullable)completion;

#pragma mark - Download

/**
 * @brief 下载指定的包，并不直接进行更新。
 *
 * @param accessKey     business的部署key
 * @param channels      指定的channel
 * @param completion    completion
 */
+ (void)downloadResourcesWithAccessKey:(NSString *)accessKey
                              channels:(NSArray<NSString *> *)channels
                            completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion
__attribute__((deprecated("Use +[IESGurdKit syncResourcesWithAccessKey] instead")));

/**
 * @brief 下载指定的包，并不直接进行更新。
 *
 * @param paramsBlock       配置参数
 * @param completion    completion
 */
+ (void)downloadResourcesWithParamsBlock:(IESGurdFetchResourcesParamsBlock)paramsBlock
                              completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion
__attribute__((deprecated("Use +[IESGurdKit syncResourcesWithParamsBlock] instead")));

#pragma mark - Sync Resource

/**
 * @brief 更新指定的包，准备好缓存环境。
 *
 * @param accessKey     business的部署key
 * @param channels      指定的channel
 * @param completion    completion
 */
+ (void)syncResourcesWithAccessKey:(NSString *)accessKey
                          channels:(NSArray<NSString *> * _Nullable)channels
                        completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion;

+ (void)syncResourcesWithAccessKey:(NSString *)accessKey
                           channel:(NSString *)channel
                           version:(uint64_t)version
                        completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion;

/**
 * @brief 更新指定的包，准备好缓存环境。
 *
 * @param paramsBlock       配置参数
 * @param completion        completion
 */
+ (void)syncResourcesWithParamsBlock:(IESGurdFetchResourcesParamsBlock)paramsBlock
                          completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion;

/**
 * @brief 异步加载指定资源；如果本地存在资源，直接返回；否则发起请求；回调在主线程
 */
+ (void)loadResourceForAccessKey:(NSString *)accessKey
                         channel:(NSString *)channel
                            path:(NSString *)path
                      completion:(IESGurdLoadResourceCompletion)completion;

/**
 * @brief 异步加载指定资源；如果本地存在资源，直接返回；否则发起请求；回调在主线程
 */
+ (void)loadResourceWithParamsBlock:(void (^)(IESGurdLoadResourcesParams *params))paramsBlock
                         completion:(IESGurdLoadResourceCompletion)completion;

#pragma mark - Enqueue

/**
 * @brief 冷启请求聚合
 */
+ (void)enqueueSyncResourcesTaskWithParamsBlock:(IESGurdFetchResourcesParamsBlock)paramsBlock
                                     completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion;


#pragma mark - Cancel Download

/**
 * @brief 取消下载
 */
+ (void)cancelDownloadWithAccesskey:(NSString *)accessKey channel:(NSString *)channel;

#pragma mark - Cache

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
 * @brief 预先读取配置文件
 */
+ (NSData *)prefetchDataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 * @brief 读取缓存数据
 */
+ (NSData *)dataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 * @brief 读取缓存数据
 */
+ (NSData *)dataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel options:(NSDataReadingOptions)options;

/**
 * @brief 异步读取缓存数据；回调在主线程
 */
+ (void)asyncGetDataForPath:(NSString *)path
                  accessKey:(NSString *)accessKey
                    channel:(NSString *)channel
                 completion:(IESGurdAccessResourceCompletion)completion;

/**
 * @brief 读取缓存数据，只读取离线资源，不读内置资源
 */
+ (NSData *)offlineDataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel;

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
 * @brief 获取指定 accessKey 已激活的 channels
 */
+ (NSArray<NSString *> *)activeChannelsForAccessKey:(NSString *)accessKey;

/**
 返回channel缓存的状态
 */
+ (IESGurdChannelCacheStatus)cacheStatusForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

#pragma mark - Lazy

/**
 * @brief 获取 lazy channel 信息
 */
+ (IESGurdLazyResourcesInfo *)lazyResourcesInfoWithAccesskey:(NSString *)accesskey channel:(NSString *)channel;

#pragma mark - ClearCache

/**
 添加资源白名单
 当调用 +[IESGurdKit clearCacheExceptWhitelist] 时，白名单资源不会被清理
 */
+ (void)addCacheWhitelistWithAccessKey:(NSString *)accessKey
                              channels:(NSArray<NSString *> *)channels;
/**
 清除cache
 */
+ (void)clearCache;

/**
 清除白名单以外的资源
 */
+ (void)clearCacheExceptWhitelist;

/**
 根据accessKey和channel清理对应的缓存;
 */
+ (void)clearCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel;

/**
 * @brief 获取全部过期 cache size
 * @param expireAge   expireAge
 */
+ (int64_t)getClearCacheSize:(int)expireAge;

/**
 * @brief 获取指定 accessKey 过期 cache size
 * @param accessKey   accessKey
 * @param expireAge   expireAge
 */
+ (int64_t)getClearCacheSizeWithAccesskey:(NSString *)accessKey
                                expireAge:(int)expireAge;

/**
 * @brief 清除全部过期 cache
 * @param expireAge   expireAge
 * @param cleanType   cleanType
 */
+ (void)clearExpiredCache:(int)expireAge
                cleanType:(int)cleanType
               completion:(void (^ _Nullable)(NSDictionary<NSString *, IESGurdSyncStatusDict> *info))completion;

/**
 * @brief 清除指定 accesskey 过期 cache
 * @param accesskey   accesskey
 * @param expireAge   expireAge
 * @param cleanType   cleanType
 */
+ (void)clearExpiredCacheWithAccesskey:(NSString *)accesskey
                             expireAge:(int)expireAge
                             cleanType:(int)cleanType
                            completion:(void (^ _Nullable)(IESGurdSyncStatusDict info))completion;

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

+ (nullable NSDictionary *)getPackageExtra:(NSString *)accsskey
                                   channel:(NSString *)channel;

/**
 添加低存储停止下载的白名单，如果groups和channels都为空，代表整个accesskey都是白名单
 */
+ (void)addLowStorageWhiteList:(NSString *)accesskey
                        groups:(NSArray *_Nullable)groups
                      channels:(NSArray *_Nullable)channels;

+ (BOOL)isInLowStorageWhiteList:(NSString *)accesskey group:(NSString *_Nullable)group channel:(NSString *_Nullable)channel;

+ (BOOL)isInLowStorageWhiteList:(NSString *)accesskey channel:(NSString *)channel;

+ (BOOL)isInLowStorageWhiteList:(NSString *)accesskey group:(NSString *)group;

@end

NS_ASSUME_NONNULL_END
