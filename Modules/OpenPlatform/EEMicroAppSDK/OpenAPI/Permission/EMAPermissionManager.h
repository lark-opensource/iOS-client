//
//  EMAPermissionManager.h
//  Pods
//
//  Created by 武嘉晟 on 2019/4/24.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPAuthorization.h>
#import <OPFoundation/EMAPermissionSharedService.h>

NS_ASSUME_NONNULL_BEGIN

/// 小程序/网页应用权限管理器
@interface EMAPermissionManager : NSObject <EMAPermissionSharedService>

+ (instancetype)sharedManager;

/**
 获取应用权限数据
 
 @param uniqueID uniqueID
 @return 权限数组
 */
- (NSArray<EMAPermissionData *> *)getPermissionDataArrayWithUniqueID:(BDPUniqueID *)uniqueID;

/**
 设置应用权限

 @param permissons 标识授权状态的键值对：@{(NSString *)scopeKey: @((BOOL)approved)}
 @param uniqueID uniqueID
 */
- (void)setPermissons:(NSDictionary<NSString *, NSNumber *> *)permissons uniqueID:(BDPUniqueID *)uniqueID;

/**
 cache网页应用授权模块

 @param authProvider 授权模块
 @param uniqueID uniqueID
 */
- (void)setWebAppAuthProviderForUniqueID:(BDPUniqueID *)uniqueID authProvider:(BDPAuthorization *)authProvider;

- (void)fetchAuthorizeData:(BDPUniqueID *)uniqueID storage:(BOOL)storage completion:(void (^ _Nonnull)(NSDictionary * _Nullable result, NSDictionary * _Nullable bizData, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
