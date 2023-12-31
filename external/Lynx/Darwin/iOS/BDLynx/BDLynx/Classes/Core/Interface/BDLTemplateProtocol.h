//
//  BDSTemplateProtocol.h
//  BDLynx
//
//  Created by zys on 2020/2/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 获取模板数据Protocol，如果使用SDK Gecko subspec 则不需要实现这个SDK
@protocol BDLTemplateProtocol <NSObject>

/**
 * 单例对象
 */
+ (instancetype)sharedInstance;

/// SDKLynx资源包根目录，目录结构参考文档
/// https://bytedance.feishu.cn/docs/doccnQ0zw8t1k8uGDhbigoeLLHb
/// @param groupID 对应业务
/// 注意 资源包内部如果没有config.json则此方法无效需要使用 fileForChannel 方法
/// 处于体验优化最好有内置资源
- (NSString *)rootDirForGroupID:(NSString *)groupID;

/// 单独的模板文件不存在版本控制
/// @param groupID 对应业务
- (NSString *)fileForGroupID:(NSString *)groupID;

/// 注册回调,当模板文件有改动时调用block通知SDK
/// @param block 回调
- (void)registerDataUpdate:(void (^)(NSString *groupID, BOOL succeed))block
                forGroupID:(NSString *)groupID;

@optional
/// 默认groupID
- (NSString *)defaultGroupID;

@end

NS_ASSUME_NONNULL_END
