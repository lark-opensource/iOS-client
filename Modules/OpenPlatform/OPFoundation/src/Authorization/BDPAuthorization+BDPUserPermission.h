//
//  BDPAuthorization+UserPermission.h
//  Timor
//
//  Created by liuxiangxin on 2019/12/11.
//

#import <UIKit/UIKit.h>
#import "BDPAuthorization.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPAuthorization (BDPUserPermission)

#pragma mark - Request Single Permission

- (void)requestUserPermissionIfNeed:(BDPJSBridgeMethod *)method
                           uniqueID:(OPAppUniqueID *)uniqueID
                       authProvider:(BDPAuthorization *)authProvider
                           delegate:(id<BDPAuthorizationDelegate>)delegate
                         completion:(BDPAuthorizationRequestCompletion)completion;

- (void)requestUserPermissionForScopeIfNeeded:(NSString *)scope
                                     uniqueID:(OPAppUniqueID *)uniqueID
                                 authProvider:(BDPAuthorization *)authProvider
                                     delegate:(id<BDPAuthorizationDelegate>)delegate
                                   completion:(void (^)(BDPAuthorizationPermissionResult))completion;

#pragma mark - Request Multiple Permissions

- (void)requestUserPermissionQeueuedForScopeList:(NSArray<NSString *> *)scopeList
                                        uniqueID:(OPAppUniqueID *)uniqueID
                                    authProvider:(BDPAuthorization *)authProvider
                                        delegate:(id<BDPAuthorizationDelegate>)delegate
                                      completion:(BDPAuthorizationRequestCompletion)completion;

/// 调用requestUserPermissionForScopeListByPendding方法前，先调用checkIfNeedAuthorziationForInvokeName检查是否存在该权限
- (void)requestUserPermissionQueuedForScopeList:(NSArray<NSString *> *)scopeList
                                       uniqueID:(OPAppUniqueID *)uniqueID
                                   authProvider:(BDPAuthorization *)authProvider
                                       delegate:(id<BDPAuthorizationDelegate>)delegate
                         withDetailedCompletion:(void (^)(NSDictionary<NSString *, NSNumber *> *))completion;

- (void)requestUserPermissionBatchedForScopeList:(NSArray<NSString *> *)scopeList
                                        uniqueID:(OPAppUniqueID *)uniqueID
                                    authProvider:(BDPAuthorization *)authProvider
                                        delegate:(id<BDPAuthorizationDelegate>)delegate
                                      completion:(void (^)(NSDictionary<NSString *,NSNumber *> *))completion;

- (void)requestUserPermissionHybridForScopeList:(NSArray<NSString *> *)scopeList
                                       uniqueID:(OPAppUniqueID *)uniqueID
                                   authProvider:(BDPAuthorization *)authProvider
                                       delegate:(id<BDPAuthorizationDelegate>)delegate
                                     completion:(void (^)(NSDictionary<NSString *,NSNumber *> *))completion;

@end

NS_ASSUME_NONNULL_END
