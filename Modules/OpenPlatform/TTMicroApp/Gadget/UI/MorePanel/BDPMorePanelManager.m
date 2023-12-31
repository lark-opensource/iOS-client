//
//  BDPMorePanelManager.m
//  Timor
//
//  Created by 王浩宇 on 2019/11/22.
//

#import "BDPMorePanelManager.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPTracker.h>
#import "BDPTaskManager.h"
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPResponderHelper.h>
#import "BDPPermissionController.h"
#import "BDPPrivacyAccessNotifier.h"
#import "BDPToolBarManager.h"

#import <OPFoundation/BDPMorePanelItem+Private.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <OPFoundation/BDPI18n.h>
#import "BDPAppPageController.h"
#import "BDPAppContainerController.h"
#import <OPFoundation/BDPCommon.h>
#import <OPFoundation/BDPCommonManager.h>

#import <LarkUIKit/LarkUIKit-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPSDK/OPSDK-Swift.h>

@implementation BDPMorePanelManager

#pragma mark - Utils
/*-----------------------------------------------*/
//                  Utils - 工具
/*-----------------------------------------------*/
+ (void)openMorePanelWithUniqueID:(BDPUniqueID *)uniqueID
{
    [self showMorePanelForUniqueID:uniqueID];
}

#pragma mark - PanelStyle

+ (void)showMorePanelForUniqueID:(BDPUniqueID *)uniqueID {
    BDPTask *task = BDPTaskFromUniqueID(uniqueID);
    BDPAppContainerController *containerVC = (BDPAppContainerController *)task.containerVC;
    BDPAppPageController *appVC = [containerVC.appController currentAppPage];
    AppMenuContext * context = [[AppMenuContext alloc] initWithUniqueID:uniqueID containerController:containerVC];
    MenuPanelSourceViewModel * sourceView = [[MenuPanelSourceViewModel alloc] initWithApi:@""];
    id<MenuPanelOperationHandler> handler = [MenuPanelHelper getMenuPanelHandlerIn:containerVC
                                                                               for: MenuPanelStyleTraditionalPanel];
    /// 用户反馈小程序menuItem隐藏需求
    BDPCommon *common = BDPCommonFromUniqueID(uniqueID);
    BDPModel *model = common.model;
    NSDictionary *extra_dict = model.extraDict;
    /// 小程序meta中包含的信息为三端的pluginID信息，需要从中间提取iOS对应的pluginID信息
    NSDictionary *disabled_menus_for_all = [extra_dict bdp_dictionaryValueForKey:@"disabled_menus"];
    NSArray* disabled_menus = [disabled_menus_for_all bdp_arrayValueForKey:@"ios"];
    NSMutableArray *new_disabled_menus = @[].mutableCopy;
    [disabled_menus enumerateObjectsUsingBlock: ^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
        if ([obj isKindOfClass:[NSString class]]) {
            [new_disabled_menus addObject:obj];
        }
    }];
    disabled_menus = new_disabled_menus;
    
    [handler resetItemModelsWith:@[]]; // 在Show之前先清空一下handler可能缓存的数据模型
    [handler updateMenuItemsToBeRemovedWith:disabled_menus];
    [handler makePluginsWith:context];
    
    NSString * parentString = @"app_id";
    NSString * buttonString = @".app_more";
    if (uniqueID != nil) {
        parentString = [parentString stringByAppendingString:uniqueID.appID];
    }
    [parentString stringByAppendingString:buttonString];
    [handler showFrom:sourceView parentPath:[[MenuBadgePath alloc] initWithPath: parentString] animation:YES complete:nil];
}

@end
