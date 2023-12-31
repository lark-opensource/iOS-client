//
//  BDPJSBridgeProtocol.h
//  Timor
//
//  Created by 王浩宇 on 2018/11/12.
//

#import "OPJSEngineProtocol.h"

@protocol BDPContextProtocol;
@protocol BDPAuthStorage;
@protocol ECONetworkServiceContext;
typedef NSObject<BDPContextProtocol>  *BDPPluginContext;
typedef id<BDPAuthStorage> BDPAuthStorageProvider;

/* ------- 各应用类型API Handler context遵循的协议 ------- */
@protocol BDPContextProtocol <NSObject, ECONetworkServiceContext>

@required
@property (nonatomic, weak, nullable) id<BDPEngineProtocol> engine;
@optional
@property (nonatomic, weak, nullable) UIViewController *controller;
// 当前worker
@property (nonatomic, weak, nullable) id<BDPEngineProtocol> workerEngine;

@optional

@end

#pragma mark - BDPlatform JSBridge Authorization DataSource Protocol
/* ------- 开放平台权限数据存储协议 ------- */
@protocol BDPAuthStorage <NSObject>

/// 存储键值对
/// @param object 值
/// @param key 键
- (BOOL)setObject:(id)object forKey:(NSString *)key;


/// 获取键值对
/// @param key 键
- (id)objectForKey:(NSString *)key;

/// 移除键值对
/// @param key 键
- (BOOL)removeObjectForKey:(NSString *)key;


@end

