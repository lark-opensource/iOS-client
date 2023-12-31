//
//  IESPrefetchLoaderProtocol.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchDefines.h"
#import "IESPrefetchJSNetworkRequestModel.h"
#import "IESPrefetchCacheStorageProtocol.h"
#import "IESPrefetchSchemaResolver.h"
#import "IESPrefetchMonitorService.h"
#import "IESPrefetchConfigResolver.h"
#import "IESPrefetchConfigTemplate.h"
#import "IESPrefetchAPIModel.h"
#import "IESPrefetchCacheModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IESPrefetchLoaderProtocol;

@protocol IESPrefetchCapability <IESPrefetchMonitorService>

/// 发起一个网络请求
- (void)networkForRequest:(IESPrefetchJSNetworkRequestModel * _Nullable)requestModel completion:(void (^)(id _Nullable data, NSError * _Nullable error))completion;

@optional
/// 自定义的缓存存储形式，SDK内部以weak形式持有该对象
- (id<IESPrefetchCacheStorageProtocol> _Nullable)customCacheStorage;
/// 通用环境变量参数
- (nullable NSDictionary<NSString *, id> *)envVariables;
/// 根据project和version返回对应的自定义配置解析器，如果返回nil，则会使用SDK内置的配置解析器
- (nullable id<IESPrefetchConfigResolver>)customConfigForProject:(NSString * _Nullable)project version:(NSString * _Nullable)version;

@end

@protocol IESPrefetchLoaderEventDelegate <NSObject>

/// 完成加载某一个project的配置
- (void)loader:(id<IESPrefetchLoaderProtocol> _Nullable)loader didFinishLoadConfig:(nullable NSString *)project withError:(nullable NSError *)error;
/// 完成某场景的预取匹配
- (void)loader:(id<IESPrefetchLoaderProtocol> _Nullable)loader didFinishPrefetchOccasion:(nullable IESPrefetchOccasion)occasion withError:(nullable NSError *)error;
/// 完成某schema的预取匹配
- (void)loader:(id<IESPrefetchLoaderProtocol> _Nullable)loader didFinishPrefetchSchema:(NSString * _Nullable)schemaString withError:(nullable NSError *)error;
/// 完成某个API的预取请求
- (void)loader:(id<IESPrefetchLoaderProtocol> _Nullable)loader didFinishPrefetchApi:(NSString * _Nullable)api withCacheStatus:(IESPrefetchCache)cacheStatus;
/// 完成某个获取数据的请求
- (void)loader:(id<IESPrefetchLoaderProtocol> _Nullable)loader didFinishFetchData:(NSString * _Nullable)requestUrl withStatus:(IESPrefetchCache)status error:(nullable NSError *)error;
/// 加载过程日志记录
- (void)loader:(id<IESPrefetchLoaderProtocol> _Nullable)loader logInfo:(NSString * _Nullable)message;

@end

@protocol IESPrefetchLoaderProtocol <NSObject>

/// 设置是否启用预取功能
- (void)setEnabled:(BOOL)enabled;

/// 设置预取时是否跳过缓存确认环节
- (void)setPrefetchIgnoreCache:(BOOL)enabled;

/**
加载单个配置文件JSON，支持调用多次，内部会以配置中的project为维度进行覆盖，加载过程会在子线程中进行

@param JSON 配置JSON
*/
- (void)loadConfigurationJSON:(NSString * _Nullable)JSON;

/**
加载单个配置文件JSON，支持调用多次，内部会以配置中的project为维度进行覆盖，加载过程会在子线程中进行
clean过期的数据可选择在子线程进行

@param JSON 配置JSON
@param async 异步清理过期的数据
*/
- (void)loadConfigurationJSON:(NSString * _Nullable)JSON cleanExpiredDataAsync:(BOOL)async;

/// 一次性加载所有配置文件，将会丢弃之前的所有配置文件，如果传入一个空数组或者nil，意味着清空之前加载的所有配置, 加载过程会在子线程中进行
/// @param configs 数组内元素为每个配置文件的具体内容
- (void)loadAllConfigurations:(NSArray<NSString *> * _Nullable)configs;

/**
 指定时机预下载数据，预取过程会在子线程中进行

 @param occasion 时机
 */
- (void)prefetchForOccasion:(nonnull IESPrefetchOccasion)occasion withVariable:(nullable NSDictionary<NSString *, id> *)variables;

/// 根据Schema进行数据预取，预取过程会在子线程中进行
/// @param urlString Schema字符串
/// @param variables 当前上下文参数
- (void)prefetchForSchema:(nonnull NSString *)urlString withVariable:(nullable NSDictionary<NSString *, id> *)variables;

/**
 Request 接口数据，completion会保证在主线程进行回调

 @param requestModel 请求接口model
 @param completion 请求结果callback
*/
- (void)requestDataWithModel:(IESPrefetchJSNetworkRequestModel * _Nonnull)requestModel
                  completion:(void (^ _Nonnull)(id _Nullable data, IESPrefetchCache cached, NSError * _Nullable error))completion;

/// 注册schema解析器，后注册的比先注册的优先级高
/// @param resolver schema解析器
- (void)registerSchemaResolver:(id<IESPrefetchSchemaResolver> _Nullable)resolver;

/// 注册loader的事件代理，loader对delegate为弱引用
- (void)addEventDelegate:(id<IESPrefetchLoaderEventDelegate> _Nullable)delegate;

- (void)prefetchAPI:(IESPrefetchAPIModel * _Nullable)model;

/**
 主动清理过期缓存
 */
- (void)cleanExpiredDataIfNeed;

/// 找出所有匹配传入URL对应的API，查看这些API有没有缓存，将有缓存的API以及其对应的数据返回。
- (nullable NSDictionary<NSString *, IESPrefetchCacheModel *> *)currentCachedDatasByUrl:(NSString * _Nullable)url;
/// 找出所有occasion对应的API，查看这些API有没有缓存，将有缓存的API以及其对应的数据返回。
- (nullable NSDictionary<NSString *, IESPrefetchCacheModel *> *)currentCachedDatasByOccasion:(IESPrefetchOccasion _Nullable)occasion;
/// 同上，但返回值包含 @"cache_model" ,@"cache_request"
- (nullable NSDictionary<NSString *, NSDictionary *> *)currentCachedDataAndRequestsByUrl:(NSString * _Nullable)url;
/// 同上，但返回值包含 @"cache_model" ,@"cache_request"
- (nullable NSDictionary<NSString *, NSDictionary *> *)currentCachedDataAndRequestsByOccasion:(IESPrefetchOccasion _Nullable)occasion;
@end

NS_ASSUME_NONNULL_END
