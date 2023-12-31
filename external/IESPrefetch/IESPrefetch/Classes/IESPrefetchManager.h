//
//  IESPrefetchManager.h
//  IESPrefetch
//
//  Created by Hao Wang on 2019/11/15.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchLoaderProtocol.h"
#import "IESPrefetchSchemaResolver.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESPrefetchManager : NSObject

@property(nonatomic, strong, readonly, class, nonnull) IESPrefetchManager *sharedInstance;

/**
 注册 Prefetch Loader 一些外部能力，例如网络，缓存

 @param capability 协议 IESPrefetchCapability 的实现实例
 @param business 业务标识
 
 @return id<IESPrefetchLoaderProtocol>
 */
- (id<IESPrefetchLoaderProtocol> _Nullable)registerCapability:(id<IESPrefetchCapability> _Nullable)capability forBusiness:(NSString * _Nullable)business;

/**
 通过 business 获取 PrefetchLoader

 @param business 业务标识
 @return id<IESPrefetchLoaderProtocol>
 */
- (id<IESPrefetchLoaderProtocol> _Nullable)loaderForBusiness:(NSString * _Nullable)business;

/**
通过 webUrl 预加载展示的数据

@param webUrl 将要打开的Url
*/
- (void)prefetchDataWithWebUrl:(NSString * _Nullable)webUrl;

//MARK: - 新接口

/// 根据business移除某个loader
- (void)removeLoaderForBusiness:(NSString * _Nullable)business;

/// 当前注册的所有business
-(NSArray<NSString *> * _Nullable)allBiz;

/// 注册schema解析器，后注册的比先注册的优先级高
/// @param resolver schema解析器
- (void)registerSchemaResolver:(id<IESPrefetchSchemaResolver> _Nullable)resolver;


@end

NS_ASSUME_NONNULL_END
