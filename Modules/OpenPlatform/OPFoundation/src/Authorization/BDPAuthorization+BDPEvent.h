//
//  BDPAuthorization+Event.h
//  Timor
//
//  Created by liuxiangxin on 2019/12/10.
//

#import <UIKit/UIKit.h>
#import "BDPAuthorization.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPAuthorization (BDPEvent)

+ (void)eventCombineAuthRessltWithUniqueID:(BDPUniqueID *)uniqueID
                                authResult:(NSDictionary<NSString *, NSNumber *> *)resultDic;

+ (void)eventAlertShowForScope:(BDPPermissionScopeType)scopeType
          uniqueID:(BDPUniqueID *)uniqueID
                  multipleAuth:(BOOL)isMultipleAuth;

+ (void)eventAuthResultForScope:(BDPPermissionScopeType)scopeType
                         result:(BDPAuthorizationPermissionResult)result
           uniqueID:(BDPUniqueID *)uniqueID
                   multipleAuth:(BOOL)isMultipleAuth;

@end

NS_ASSUME_NONNULL_END
