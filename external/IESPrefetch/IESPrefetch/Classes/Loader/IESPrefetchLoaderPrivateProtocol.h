//
//  IESPrefetchLoaderPrivateProtocol.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchDefines.h"
#import "IESPrefetchAPIModel.h"
#import "IESPrefetchCacheProvider.h"
#import "IESPrefetchLoaderProtocol.h"
@protocol IESPrefetchSchemaResolver;
@class IESPrefetchFlatSchema;
@protocol IESPrefetchLoaderEvent;

NS_ASSUME_NONNULL_BEGIN

/// 内部的私有协议方法，以下定义的方法都在调用方法的当前线程中执行
@protocol IESPrefetchLoaderPrivateProtocol <IESPrefetchLoaderProtocol>

//MARK: - Load config
/**
加载单个配置文件JSON，支持调用多次，内部会以配置中的project为维度进行覆盖

@param configDict 配置JSON
*/
- (nullable id<IESPrefetchLoaderEvent>)loadConfigurationDict:(NSDictionary *)configDict withEvent:(nullable id<IESPrefetchLoaderEvent>)event;
/// 删除某一个project的配置
- (void)removeConfiguration:(NSString *)project;
/// 删除所有配置
- (void)removeAllConfigurations;
/// 按照project获取当前生效的配置
- (id<IESPrefetchConfigTemplate>)templateForProject:(NSString *)project;
/// 当前生效的所有projects
- (NSArray<NSString *> *)allProjects;

//MARK: - Trigger Prefetch
- (nullable id<IESPrefetchLoaderEvent>)prefetchForSchema:(nullable IESPrefetchFlatSchema *)schema occasion:(nullable IESPrefetchOccasion)occasion withVariables:(nullable NSDictionary<NSString *, id> *)variables event:(nullable id<IESPrefetchLoaderEvent>)event;

- (void)prefetchAPI:(IESPrefetchAPIModel *)model;

- (IESPrefetchCacheProvider *)cacheProvider;

@end

NS_ASSUME_NONNULL_END
