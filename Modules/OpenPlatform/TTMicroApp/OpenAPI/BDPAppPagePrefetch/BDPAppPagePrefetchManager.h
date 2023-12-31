//
//  BDPAppPagePrefetchManager.h
//  Timor
//
//  Created by 李靖宇 on 2019/11/25.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/OPAppUniqueID.h>
#import "BDPAppPagePrefetchDataModel.h"
@class BDPSchema;
@class BDPUniqueID;
@class OPPrefetchErrnoWrapper;

NS_ASSUME_NONNULL_BEGIN

@protocol BDPAppPagePrefetchManagerSwiftProtocol <NSObject>
/// 解码app-config.json的二进制数据, 缓存Prefetch接口列表，并进行数据预期
/// @param configDict app-config.json解析后的字典数据 【为空直接return】
/// @param schema 当前打开或正在打开的小程序schema
/// @param version app版本号【为空直接return】
- (void)decodeAndPrefetchWithConfigDict:(NSDictionary * _Nullable)configDict schema:(BDPSchema *)schema uniqueID:(OPAppUniqueID *)uniqueID version:(NSString * _Nullable)version;
@end

@interface BDPAppPagePrefetchManager : NSObject <BDPAppPagePrefetchManagerSwiftProtocol>

/// 内部 FG 控制关闭 prefetch 时返回 nil
+ (nullable instancetype)sharedManager;
/// 通过schema判断当前场景是否进行预下载场景下的数据预取
/// @param schema 调起小程序的schema
- (BOOL)isAllowPrefetchWithSchema:(BDPSchema *)schema;

/// 解码app-config.json的二进制数据, 缓存Prefetch接口列表
/// @param configData app-config.json的二进制数据
/// @param uniqueID uniqueID
/// @param version app版本号
- (void)decodeWithConfigData:(NSData *)configData uniqueID:(BDPUniqueID *)uniqueID version:(NSString *)version;

/// 解码app-config.json的字典数据, 缓存Prefetch接口列表
/// @param dict app-config.json的字典数据
/// @param uniqueID uniqueID
/// @param version app版本号
/// @param completion 完成回调
- (void)decodeWithConfigDict:(NSDictionary *)dict uniqueID:(BDPUniqueID *)uniqueID version:(NSString *)version completion:(void (^ _Nullable)(NSDictionary *cacheDict))completion;

/// 根据已缓存的Prefetch接口数据进行数据预取
/// @param schema 当前打开或正在打开的小程序schema
/// @param uniqueID uniqueID
- (void)prefetchWithCurrentSchema:(BDPSchema *)schema uniqueID:(BDPUniqueID *)uniqueID;

/// 当清除热启动缓存时，释放对应uniqueID的prefetcher变量
/// @param uniqueID uniqueID
- (void)releasePrefetcherWithUniqueID:(BDPUniqueID *)uniqueID;

/// 判断当前key是否有预取的数据，有预取完毕的直接执行，有正在预取的等待预取请求完成时执行
/// @param param tt.request cp传入的参数
/// @param uniqueID uniqueID
/// @param completion 网络请求的回调
/// @param error 预取错误信息
- (BOOL)shouldUsePrefetchCacheWithParam:(NSDictionary*)param uniqueID:(BDPUniqueID *)uniqueID requestCompletion:(PageRequestCompletionBlock)completion error:(OPPrefetchErrnoWrapper **)error;

/// 插件config数据预取
/// @param configDict 插件的app-config
/// @param schema 当前打开或正在打开的小程序schema
/// @param uniqueID uniqueID
- (void)decodeAndPrefetchPluginConfig:(NSDictionary *)configDict schema:(BDPSchema *)schema uniqueID:(BDPUniqueID*)uniqueID;

//切租户的情况下
//清理prefetch缓存
-(void)logout;
@end

NS_ASSUME_NONNULL_END
