//
//  TTSmallAppConfig.h
//  TTRexxar
//
//  Created by muhuai on 2017/11/17.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import <OPFoundation/BDPModel.h>
#import "BDPPageConfig.h"
#import "BDPTabBarConfig.h"
#import "BDPWindowConfig.h"
#import "BDPLaunchAppConfig.h"
#import "BDPNetworkTimeoutConfig.h"
#import "BDPNetworkAPIVersionConfig.h"
#import "BDPRedirectPageConfig.h"

FOUNDATION_EXTERN NSString *const BDPAuthorizeDescriptionKeyUserInfo;
FOUNDATION_EXTERN NSString *const BDPAuthorizeDescriptionKeyUserLocation;
FOUNDATION_EXTERN NSString *const BDPAuthorizeDescriptionKeyAddress;
FOUNDATION_EXTERN NSString *const BDPAuthorizeDescriptionKeyRecord;
FOUNDATION_EXTERN NSString *const BDPAuthorizeDescriptionKeyAlbum;
FOUNDATION_EXTERN NSString *const BDPAuthorizeDescriptionKeyCamera;
FOUNDATION_EXTERN NSString *const BDPAuthorizeDescriptionKeyPhoneNumber;


@protocol BDPRedirectPageConfig;

@interface BDPAppConfig : JSONModel

@property (nonatomic, strong) NSString *entryPagePath;
@property (nonatomic, strong) NSArray<NSString *> *pages;
// 单个page的config解析改为懒加载, 要访问的话全部走 `getPageConfigByPath:`方法
//@property (nonatomic, strong) NSDictionary<NSString *, BDPPageConfig *> *page;
@property (nonatomic, strong) BDPWindowConfig<Optional> *window;
@property (nonatomic, strong) BDPTabBarConfig<Optional> *tabBar;
@property (nonatomic, copy) NSDictionary<NSString *, NSDictionary *><Optional> * apiConfig;
@property (nonatomic, copy) BDPNetworkAPIVersionConfig<Optional> *networkAPIVersion;
@property (nonatomic, strong) BDPNetworkTimeoutConfig<Optional> *networkTimeout;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray *> *prefetches;
@property (nonatomic, copy) NSDictionary<NSString *, NSDictionary *> *prefetchRules;
@property (nonatomic, copy) NSDictionary<NSString *, NSDictionary *> *preloadRule;//分包预加载规则配置
@property (nonatomic, copy, nullable) NSArray<NSDictionary *> *subPackages; //分包配置信息
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *loadPage;
@property (nonatomic, strong) NSArray<NSString *><Optional> *navigateToAppIdList;
@property (nonatomic, strong) BDPLaunchAppConfig<Optional> *launchApp;
@property (nonatomic, copy) NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *permission;
@property (nonatomic, assign) BOOL debug;
/// 开发者配置小程序是否支持 darkmode
@property (nonatomic, assign) BOOL darkmode;

@property (nonatomic, copy, nullable) NSArray<BDPRedirectPageConfig *><BDPRedirectPageConfig> *redirectPagePath;

- (instancetype)initWithDict:(NSDictionary *)dict noTab:(BOOL)noTab;

- (BOOL)containsPage:(NSString *)page;          // 判断页面是否存在
- (BOOL)isTabPage:(NSString *)page;             // 判断页面是否为Tab页面
- (NSInteger)tabBarIndexOfPath:(NSString *)path;

- (BDPPageConfig *)getPageConfigByPath:(NSString *)path;

/// 应用 Dark Mode 配置
- (void)applyDarkMode:(BOOL)darkMode;
- (NSString * _Nullable)redirectPage:(NSString *)page;
@end

