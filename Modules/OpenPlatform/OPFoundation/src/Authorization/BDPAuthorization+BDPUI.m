//
//  BDPAuthorization+UI.m
//  Timor
//
//  Created by liuxiangxin on 2019/12/9.
//

#import "BDPAuthorization+BDPUI.h"
#import <ECOInfra/BDPLog.h>
#import "BDPUtils.h"
#import "BDPAuthorizationUtilsDefine.h"
#import "BDPMacroUtils.h"
#import "BDPUIPluginDelegate.h"
#import "BDPTimorClient.h"
#import "BDPAuthorizationSettingManager.h"
#import "BDPResponderHelper.h"
#import "UIViewController+BDPExtension.h"
#import "BDPDeviceHelper.h"
#import "BDPSandBoxHelper.h"
#import "BDPI18n.h"
#import <OPFoundation/OPFoundation-Swift.h>
#import "BDPAuthorization+BDPUtils.h"
#import "OPResolveDependenceUtil.h"

@implementation BDPAuthorization (BDPUI)

- (void)showCustomPermissionVCWithTitle:(NSString *)title
                            description:(NSString *)description
                              scopeType:(BDPPermissionScopeType)scopeType
                             completion:(void (^)(BOOL))completion
{
    BDPLogInfo(@"showCustomPermissionVCWithTitle, title=%@, description=%@", title, description);
    
    // Custom Permission AlertController
    [self showInnerPermissionControllerWithScopeType:scopeType
                                               title:title
                                         description:description
                                          completion:completion];
}

+ (void)showAlertNoPermission:(BDPAuthorizationSystemPermissionType)type
{
    BDPExecuteOnMainQueue(^{
           // Get App Name
           NSString *appName = BDPSandBoxHelper.appDisplayName;
           NSString *description = @"";
           if (type == BDPAuthorizationSystemPermissionTypeCamera) {
               description = [NSString stringWithFormat:BDPI18n.permissions_camera_acess, appName];
           } else if (type == BDPAuthorizationSystemPermissionTypeMicrophone) {
               description = [NSString stringWithFormat:BDPI18n.permissions_microphone_acess, appName];
           } else if (type == BDPAuthorizationSystemPermissionTypeAlbum) {
               description = [NSString stringWithFormat:BDPI18n.permissions_photo_acess, appName];
           }

           // 适配DarkMode:使用主端提供的UDDilog
           UDDialog *dialog = [UDOCDialogBridge createDialog];
           [UDOCDialogBridge setTitleWithDialog:dialog text:BDPI18n.permissions_no_access];
           [UDOCDialogBridge setContentWithDialog:dialog text:description];
           [UDOCDialogBridge addSecondaryButtonWithDialog:dialog text:BDPI18n.cancel dismissCompletion:^{

           }];

           [UDOCDialogBridge addButtonWithDialog:dialog text:BDPI18n.microapp_m_permission_go_to_settings dismissCompletion:^{
               [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
           }];

           [self showDialog:dialog animated:YES completion:nil];
       });
}

#pragma mark - Controller Get

- (UIViewController *)permissionControllerWithScopeType:(BDPPermissionScopeType)type
                                                  title:(NSString *)title
                                            description:(NSString *)description
                                             completion:(BDPPermissionControllerCompletion)completion
{
    UIViewController *vc = nil;
    vc = [self sheetPermissionControllerWithScopeType:type completion:completion];
    return vc;
}

- (UIViewController<BDPPermissionViewControllerDelegate> *)sheetPermissionControllerWithScopeType:(BDPPermissionScopeType)type
                                                             completion:(BDPPermissionControllerCompletion)completion
{
    Class<BDPPermissionViewControllerDelegate> permissionVCClass = [OPResolveDependenceUtil permissionViewControllerClass];
    UIViewController<BDPPermissionViewControllerDelegate>  *permissionVC = [permissionVCClass initControllerWithName:self.source.name icon:self.source.icon uniqueID:self.source.uniqueID authScopes:self.scope scopeList:@[@(type)]];
    permissionVC.completion = ^(NSArray<NSNumber *> * _Nonnull authorizedScopes, NSArray<NSNumber *> * _Nonnull deniedScopes) {
        if (authorizedScopes.count) {
            AUTH_COMPLETE(YES);
        } else {
            AUTH_COMPLETE(NO);
        }
    };
    
    return permissionVC;
}

#pragma mark - Controller Show

- (void)showInnerPermissionControllerWithScopeType:(BDPPermissionScopeType)type
                                             title:(NSString *)title
                                       description:(NSString *)description
                                        completion:(BDPPermissionControllerCompletion)completion
{
    WeakSelf;
    BDPExecuteOnMainQueue(^{
        StrongSelfIfNilReturn;
        UIViewController *permissionVC = [self permissionControllerWithScopeType:type
                                                                           title:title
                                                                     description:description
                                                                      completion:completion];
        
        [self.class showViewController:permissionVC animated:YES completion:nil];
    });
}

+ (void)showDialog:(UDDialog *)vc animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    BDPExecuteOnMainQueue(^{
        UIViewController *topVC = [self getTopVCWith:vc];
        if ([UDRotation isAutorotateFrom:topVC]) {
            [UDOCDialogBridge setAutorotatableWithDialog:vc enable:YES];
        }
        [topVC presentViewController:vc animated:animated completion:completion];
    });
}

+ (void)showViewController:(UIViewController *)vc animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    BDPExecuteOnMainQueue(^{
        UIViewController *topVC = [self getTopVCWith:vc];
        [topVC presentViewController:vc animated:animated completion:completion];
    });
}

+ (UIViewController *)getTopVCWith:(UIViewController *)vc {
    UIWindow *window = vc.view.window ?: OPWindowHelper.fincMainSceneWindow;
    UIViewController *topVC = [BDPResponderHelper topViewControllerFor:[BDPResponderHelper topmostView:window]];
    if ([BDPDeviceHelper isPadDevice]) {
        UIPopoverPresentationController *popPresenter = [vc popoverPresentationController];
        popPresenter.sourceView = window;
        popPresenter.sourceRect = window.bounds;
    }
    return topVC;
}

@end
