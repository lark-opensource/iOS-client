//
//  BDPPluginRouterImpl.m
//  TTMicroApp-Example
//
//  Created by MacPu on 2018/11/6.
//  Copyright © 2018 muhuai. All rights reserved.
//

#import "BDPPluginRouterImpl.h"
#import <TTRoute/TTRoute.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPResponderHelper.h>
#import <OPFoundation/BDPSettingsManager.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/BDPLog.h>
#import <LKLoadable/Loadable.h>
#import <TTMicroApp/BDPTimorClient+Business.h>
#import <TTMicroApp/BDPTimorLaunchParam.h>

LoadableMainFuncBegin(BDPPluginRouterImplSettingTimorClientData)
/** Lark小程序不能更新头条js sdk基础库和拉取配置接口 */
//BDPTimorClient.sharedClient.currentNativeGlobalConfiguration.shouldNotUpdateSettingsData = YES;
//BDPTimorClient.sharedClient.currentNativeGlobalConfiguration.shouldNotUpdateJSSDK = YES;
// 注册路由
[TTRoute registerRouteEntry:@"microapp" withObjClass:[BDPPluginRouterImpl class]];
LoadableMainFuncEnd(BDPPluginRouterImplSettingTimorClientData)


typedef void (^RouterCompletionBlock)(BOOL result);

@interface BDPPluginRouterImpl () <TTRouteInitializeProtocol>

@end

@implementation BDPPluginRouterImpl
- (instancetype)initWithRouteParamObj:(TTRouteParamObj *)paramObj
{
    self = [super init];
    return self;
}

- (void)customOpenTargetWithParamObj:(TTRouteParamObj *)paramObj
{
    BDPLogInfo(@"customOpenTarget, sourceUrl=%@", paramObj.sourceURL);
    UIWindow *window = [paramObj.userInfo.allInfo bdp_objectForKey:kTargetWindowKey ofClass:UIWindow.class];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        TTRouteUserInfo *userInfo = paramObj.userInfo;
        RouterCompletionBlock block = [userInfo.allInfo objectForKey:@"jsCallback"];
        if (block) {
            block(YES);
        }
    }];
    [[BDPTimorClient sharedClient] openWithURL:paramObj.sourceURL userInfo:paramObj.userInfo.allInfo openType:BDPViewControllerOpenTypePush window:window];
    [CATransaction commit];
}

@end
