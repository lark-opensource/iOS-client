//
//  BDPAuthorization+UI.h
//  Timor
//
//  Created by liuxiangxin on 2019/12/9.
//

#import <UIKit/UIkit.h>
#import "BDPAuthorization.h"
#import "BDPJSBridgeProtocol.h"

typedef void(^BDPPermissionControllerCompletion)(BOOL on);

NS_ASSUME_NONNULL_BEGIN

@interface BDPAuthorization (BDPUI)

// 显示授权弹窗
- (void)showCustomPermissionVCWithTitle:(NSString *)title
                            description:(NSString *)description
                              scopeType:(BDPPermissionScopeType)scopeType
                             completion:(void (^)(BOOL))completion;

+ (void)showAlertNoPermission:(BDPAuthorizationSystemPermissionType)type;

+ (void)showViewController:(UIViewController *)vc
                  animated:(BOOL)animated
                completion:(__nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
