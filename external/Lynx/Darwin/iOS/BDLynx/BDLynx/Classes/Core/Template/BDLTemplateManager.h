//
//  BDLTemplateManager.h
//  BDLynx
//
//  Created by zys on 2020/2/6.
//

#import <Foundation/Foundation.h>
@class BDLynxBundle;

NS_ASSUME_NONNULL_BEGIN

static NSString *const kChannelTemplateDidUpdate = @"kChannelTemplateDidUpdate";

@interface BDLTemplateManager : NSObject

@property(class, readonly, nonatomic, strong) BDLTemplateManager *sharedInstance;

/// 异步读取Lynx数据
/// @param cardID  当前模板名称
/// @param groupID 当前模板所在业务名
/// @param completion 获取回调在主线程执行
+ (void)asyncGetDataForCardID:(NSString *)cardID
                      groupID:(NSString *)groupID
                   completion:(void (^)(NSData *data))completion
    DEPRECATED_MSG_ATTRIBUTE("即将废弃，请勿使用");

/// 获取Channel Bundle 内部包含对应Channel的配置
/// @param groupID 业务名
+ (BDLynxBundle *)lynxBundleForGroupID:(NSString *)groupID cardID:(NSString *)cardID;

// ------------------------------------ OnCard在线流程 BEGIN
// ------------------------------------------------

/// 异步读取Lynx数据
/// @param channel 当前模板所在业务名
/// @param completion 获取回调在主线程执行
- (void)loadGurdBundle:(NSString *)channel
             completion:(void (^)(BDLynxBundle *bundle, BOOL success))completion;

/// 异步读取Lynx数据
/// @param channel 当前模板所在业务名
/// @param accessKey 业务的accessKey
/// @param completion 获取回调在主线程执行
- (void)loadGurdBundle:(NSString *)channel
              accessKey:(nullable NSString *)accessKey
             completion:(void (^)(BDLynxBundle *bundle, BOOL success))completion;

/// 异步读取Lynx数据，同时加载 _resource 分包资源
/// @param channel 当前模板所在业务名
/// @param accessKey 业务的accessKey
/// @param completion 获取回调在主线程执行
- (void)loadGurdBundleAndResource:(NSString *)channel
                         accessKey:(nullable NSString *)accessKey
                        completion:(void (^)(BDLynxBundle *bundle, BOOL success))completion;

- (void)bundleUpdate:(NSString *)groupID success:(BOOL)success;

// ------------------------------------ OnCard在线流程 END
// ------------------------------------------------

/// 返回存在本地的Bundle
/// @param groupID 卡片组ID
- (BDLynxBundle *)lynxBundleForGroupID:(NSString *)groupID;

/// 直接获取远程数据
/// @param url 远程数据地址
/// @param completion  回调
+ (void)asyncGetDataForDirectURL:(NSURL *)url
                      completion:(void (^)(NSData *data))completion
    DEPRECATED_MSG_ATTRIBUTE("即将废弃，请勿使用");

/// 获取Channel Bundle 内部包含对应Data
/// @param groupID 业务名
/// @param cardID 模块名
+ (NSData *)lynxDataForGroupID:(NSString *)groupID cardID:(NSString *)cardID;

/// 获取Channel Bundle 内部包含对应Channel的 path
/// @param groupID 业务名
/// @param cardID 模块名
+ (NSString *)lynxBundlePathForGroupID:(NSString *)groupID cardID:(NSString *)cardID;

@end

NS_ASSUME_NONNULL_END
