**IESGeckoKit** 是一个比较灵活的通用包更新、管理方案。它支持：
- 多条业务线管理
- 每条业务线的多频道管理
- 包更新、生效的信息跟踪
- 包有效性检查
- 全量更新 & 增量更新
- 自定义包更新的配置信息

**Note：以下API基于IESGeckoKit 0.5.2版本**


## 注册元信息

设置基本参数。（注意：调用时机尽可能提前；尽量由宿主进行调用，SDK如果调用，需要跟宿主保持 `cacheRootDirectory` 一致）
``` objc
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
    cacheRootDirectory:(NSString * _Nullable)cacheRootDirectory
                   env:(IESGurdEnvType)env
```

设置设备id。
``` objc
/**
 * @brief 设置DeviceID。统计用。
 *
 * 注意：需要在syncResources之前进行设置。
 */
+ (void)setDeviceID:(NSString *)deviceID;
```

注册各业务线的元信息。
``` objc
/**
 * 注意 : 需要在syncResources之前进行设置。
 * 注意 : 会根据 +[IESGurdKit setCacheConfiguration:forAccessKey:] 限制channels数量
 */
+ (void)registerAccessKey:(NSString *)accessKey
                 channels:(NSArray<NSString *> *)channels;
```
其中，accessKey对应一条业务线，appVersion是业务线的版本号，channels是业务线的所有频道。每一个频道对应一个包。
- 对于一个App，一般情况下，一条业务线足以。不同的业务模块可以划分成不同的channel。
- 对于一些平台型App，本身划分了不同的业务线，各业务线之间独立开发，互相不耦合。这个时候，多业务线才变得有意义。每条业务线只需要注册自己的元信息即可。


## 包更新

### 一般应用

同步指定已注册的channels资源。
``` objc
/**
 * @brief 更新指定的包，准备好缓存环境。
 *
 * @param accessKey     business的部署key
 * @param channelArray  指定的channel
 * @param completion    completion
 */
+ (void)syncResourcesWithAccessKey:(NSString *)accessKey
                          channels:(NSArray<NSString *> *)channelArray
                        completion:(IESGurdSyncStatusDictionaryBlock)completion;
```

### SDK型应用

同步指定版本资源。
``` objc
#import <IESGeckoKit/IESGurdKit+ExtraParams.h>

/**
 * @brief 更新指定的包，准备好缓存环境。
 *
 * @param accessKey     business的部署key
 * @param channelArray  指定的channel
 * @param resourceVersion 资源版本
 * @param completion    completion
 */
+ (void)syncResourcesWithAccessKey:(NSString *)accessKey
                          channels:(NSArray<NSString *> *)channelArray
                   resourceVersion:(NSString * _Nullable)resourceVersion
                        completion:(IESGurdSyncStatusDictionaryBlock)completion;
```

## 包管理

推荐用异步的方式获取包数据。
``` objc
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
+ (NSData *)dataForPath:(NSString *)path accessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
* @brief 异步读取缓存数据
*/
+ (void)asyncGetDataForPath:(NSString *)path
                  accessKey:(NSString *)accessKey
                    channel:(NSString *)channel
                 completion:(IESGurdAccessResourceCompletion)completion;

/**
 * @brief 获取根目录
 */
+ (NSString *)rootDirForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 * @brief 清除cache
 */
+ (void)clearCache;
```

## 缓存清理

``` objc
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
```

## 版本更新
    
- 0.5.3-rc.13.1-bugfix  代理分发防闪退处理
- 0.5.3-rc.13           meta信息本地化降频
- 0.5.3-rc.12           补齐请求被cancel的错误日志
- 0.5.3-rc.11     		修复同个channel并发请求问题，废弃 syncResourcesIfNeeded
- 0.5.3-rc.7~rc.10		完成定向缓存清理和自定义参数功能
- 0.5.3-rc.6       		setup加上稳定性处理
- 0.5.3-rc.5       		数据上报改为定时上报
- 0.5.3-rc.4       		修复Gecko开关打开通知问题
- 0.5.3-rc.3       		去掉日志敏感关键字
- 0.5.3-rc.2 			修复 iOS 8 反序列化闪退问题
- 0.5.3-rc.1			修复 下载前删除旧包导致patch失败的问题
- 0.5.3-rc.0			修复 @synchronized锁问题	

