//
//  BDPTimorClient.h
//  Timor
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDPAppearanceConfiguration.h"
#import "BDPApplicationPluginDelegate.h"
#import "BDPAuthorizationPluginDelegate.h"
#import "BDPBasePluginDelegate.h"
#import "BDPFileSystemPluginDelegate.h"
#import "BDPLifeCyclePluginDelegate.h"
#import "BDPLocationPluginDelegate.h"
#import "BDPMediaPluginDelegate.h"
#import "BDPMonitorPluginDelegate.h"
#import "BDPNetworkPluginDelegate.h"
#import "BDPRouterPluginDelegate.h"
#import "BDPRuntimeGlobalConfiguration.h"
#import "BDPSharePluginDelegate.h"
#import "BDPTrackerPluginDelegate.h"
#import "BDPUIPluginDelegate.h"
#import "BDPUserPluginDelegate.h"
#import "BDPAPIPluginDelegate.h"
#import "BDPXScreenPluginDelegate.h"
#import "BDPVersionManagerDelegate.h"
#import "BDPPermissionViewControllerDelegate.h"
#import "OPGadgetPluginDelegate.h"
#import "EMAAppEnginePluginDelegate.h"
#import "EMAPermissionSharedService.h"

#define SCHEMA_APP [NSString stringWithFormat:@"%@%@%@" , @"mic", @"roa", @"pp"]

typedef NS_ENUM(NSInteger, BDPViewControllerOpenType) {
    BDPViewControllerOpenTypeUnknown = 0,
    BDPViewControllerOpenTypePush,
    BDPViewControllerOpenTypePresent,
    BDPViewControllerOpenTypeChild, // 子VC模式
};

NS_ASSUME_NONNULL_BEGIN

/// 前置声明
@protocol GadgetUniversalRouteDelegate;

@protocol OPDisasterRecoverProtocol;

#pragma mark - Client
/*-----------------------------------------------*/
//             Client - 小程序客户端
// SDK调用入口，根据schema创建BDPAppContainerController做小程序的UI容器。
/*-----------------------------------------------*/
@interface BDPTimorClient : NSObject

/// 获取这个类实例的方法只能通过shareClient
+ (instancetype)sharedClient;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/******************          Delegates         *********************/
/**
 宿主pre-main阶段与小程序相关的耗时优化可使用 BDPBootstrapHeader 中提供的方法去替代+load实现, 比如
 @BDPBootstrapLaunch(classname, { // 以下作用于范围内的代码, 将在非启动启动阶段的某个时机执行
    [BDPTimorClient sharedClient].toastPlugin = [xxx class];
 }); // 详细注释请看 BDPBootstrapHeader.h 文件
 */

// UI
@property (nonatomic, strong) Class<BDPToastPluginDelegate> toastPlugin;
@property (nonatomic, strong) Class<BDPModalPluginDelegate> modalPlugin;
@property (nonatomic, strong) Class<BDPAlertPluginDelegate> alertPlugin;
@property (nonatomic, strong) Class<BDPPickerPluginDelegate> pickerPlugin;
@property (nonatomic, strong) Class<BDPNavigationPluginDelegate> navigationPlugin;
@property (nonatomic, strong) Class<BDPLoadingViewPluginDelegate> loadingViewPlugin;
@property (nonatomic, strong) Class<BDPWebviewPluginDelegate> webviewPlugin;
@property (nonatomic, strong) Class<BDPCustomResponderPluginDelegate> customResponderPlugin;
// Share
@property (nonatomic, strong) Class<BDPSharePluginDelegate> sharePlugin;
// user
@property (nonatomic, strong) Class<BDPUserPluginDelegate> userPlugin;
// Application
@property (nonatomic, strong) Class<BDPApplicationPluginDelegate> applicationPlugin;
// location
@property (nonatomic, strong) Class<BDPLocationPluginDelegate> locationPlugin;
// Router
@property (nonatomic, strong) Class<BDPRouterPluginDelegate> routerPlugin;
/// file system
@property (nonatomic, strong) Class<BDPFileSystemPluginDelegate> fileSystemPlugin;
// Monitor, tips: 如果你已经接入了 ExceptrionMonitor 的 subspecs， 就可以不需要实现这个plugin。
@property (nonatomic, strong) Class<BDPMonitorPluginDelegate> monitorPlugin;
//Tracker
@property (nonatomic, strong) Class<BDPTrackerPluginDelegate> trackerPlugin;
//Network
@property (nonatomic, strong) Class<BDPNetworkPluginDelegate> networkPlugin;
/// authorization
@property (nonatomic, strong) Class<BDPAuthorizationPluginDelegate> authorizationPlugin;
/// Life Cycle
@property (nonatomic, strong) Class<BDPLifeCyclePluginDelegate> lifeCyclePlugin;
/// API
@property (nonatomic, strong) Class<BDPAPIPluginDelegate> apiPlugin;
/// 小程序统一路由的代理
@property (nonatomic, strong) Class<GadgetUniversalRouteDelegate> gadgetUniversalRoutePlugin;
/// 半屏能力注入
@property (nonatomic, strong) Class<BDPXScreenPluginDelegate> XScreenPlugin;

// BDPVersionManager 能力注入
@property (nonatomic, strong) Class<BDPVersionManagerDelegate> versionManagerPlugin;
// BDPPermissionViewController class 注入
@property (nonatomic, strong) Class<BDPPermissionViewControllerDelegate> permissionVCPlugin;
// 小程序对外能力，主要包含 OPAppUniqueID+OP.swift 对外能力 注入
@property (nonatomic, strong) Class<OPGadgetPluginDelegate> opGadgetPlugin;
// EMAAppEngine 对外能力 注入
@property (nonatomic, strong) Class<EMAAppEnginePluginDelegate> appEnginePlugin;
/// 小程序容灾 API接口
@property (nonatomic, strong) Class<OPDisasterRecoverProtocol> disasterRecoverPlugin;
/// 小程序/网页应用鉴权接口
@property (nonatomic, strong) Class<EMAPermissionSharedService> permissionPlugin;

@property (nonatomic, strong, readonly) BDPRuntimeGlobalConfiguration *currentNativeGlobalConfiguration;

@property (nonatomic, strong, readonly) BDPRuntimeGlobalConfiguration *globalConfiguration;

@property (nonatomic, strong, readonly) BDPAppearanceConfiguration *appearanceConfiguration;

///** 清理所有热缓存数据(小程序实例、数据库实例、下载/请求任务等) */
//- (void)clearAllWarmBootCache;
///// 清理用户缓存
//- (void)clearAllUserCache;

@end

#pragma mark - Appearance

@interface BDPTimorClient (Appearance)

@property (nonatomic, strong) BDPAppearanceConfiguration *appearanceConfg;

@end


NS_ASSUME_NONNULL_END
