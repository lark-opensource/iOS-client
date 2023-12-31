//
//  BDPContainerModuleProtocol.h
//  Timor
//
//  Created by yin on 2020/4/2.
//


#import "BDPModuleProtocol.h"
#import "BDPJSBridgeProtocol.h"



/// 鉴权模块协议
@protocol BDPAuthModuleProtocol <BDPModuleProtocol>

/// 校验scheme权限
/// @param url 链接url
/// @param uniqueID 应用id
/// @param failErrMsg 错误信息
- (BOOL)checkSchema:(NSURL *)url uniqueID:(BDPUniqueID *)uniqueID errorMsg:(NSString *)failErrMsg;

/// 检查是否有权限
/// @param scope 权限名
/// @param context 上下文
/// @param completion 完成回调
- (void)requestUserPermissionForScopeIfNeeded:(NSString *)scope
                                      context:(BDPPluginContext)context
                                   completion:(void (^)(BDPAuthorizationPermissionResult))completion;
/// 检查是否有权限
/// @param contex 上下文
/// @return session 应用session
- (NSString *)getSessionContext:(BDPPluginContext)contex DEPRECATED_MSG_ATTRIBUTE("Use GadgetSessionPlugin instead");

/// 改造userInfo返回
/// @param data userInfo dict
/// @param uniqueID 应用id
- (NSDictionary *)userInfoDict:(NSDictionary *)data uniqueID:(BDPUniqueID *)uniqueID;

/// userInfo接口的url
/// @param uniqueID 应用id
- (NSString *)userInfoURLUniqueID:(BDPUniqueID *)uniqueID;

@end

