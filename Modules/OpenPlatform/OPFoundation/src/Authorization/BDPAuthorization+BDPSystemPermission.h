//
//  BDPAuthorization+SystemPermission.h
//  Timor
//
//  Created by liuxiangxin on 2019/12/10.
//

#import <UIKit/UIKit.h>
#import "BDPAuthorization.h"

typedef void(^BDPAuthorizationSystemPermissionCompletion)(BOOL isSuccess);

NS_ASSUME_NONNULL_BEGIN

@interface BDPAuthorization (BDPSystemPermission)

+ (void)checkSystemPermissionWithTips:(BDPAuthorizationSystemPermissionType)type
                           completion:(BDPAuthorizationSystemPermissionCompletion)completion;

+ (void)checkSystemPermission:(BDPAuthorizationSystemPermissionType)type
                   completion:(BDPAuthorizationSystemPermissionCompletion)completion;

- (void)requestSystemPermissionForScopeIfNeed:(NSString *)scope
                                     uniqueID:(OPAppUniqueID *)uniqueID
                                   completion:(BDPAuthorizationRequestCompletion)completion;

- (void)requestSystemPermissionForScopeListIfNeeded:(NSArray<NSString *> *)scopeList
                                           uniqueID:(OPAppUniqueID *)uniqueID
                                         completion:(void (^)(NSDictionary<NSString *, NSNumber *> *))completion;

@end

NS_ASSUME_NONNULL_END
