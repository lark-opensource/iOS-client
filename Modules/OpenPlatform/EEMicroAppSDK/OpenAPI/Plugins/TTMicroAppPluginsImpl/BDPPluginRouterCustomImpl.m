//
//  BDPPluginRouterCustomImpl.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/5/7.
//

#import "BDPPluginRouterCustomImpl.h"

#import "EERoute.h"
#import "EMAAppEngine.h"
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPGadget/OPGadget-Swift.h>
#import <OPSDK/OPSDK-Swift.h>

@implementation BDPPluginRouterCustomImpl

+ (instancetype)sharedPlugin {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (BDPOpenSchemaResult)bdp_openSchemaWithURL:(NSURL *)url
                                    uniqueID:(BDPUniqueID *)uniqueID
                                     appType:(BDPType)appType
                                    external:(BOOL)external
                              fromController:(UIViewController *)fromController
                            whiteListChecker:(BDPAuthorization *)whiteListChecker {
    BDPLogInfo(@"bdp_openSchema, uniqueID=%@, external=%@", uniqueID, @(external));
    return [self tryOpenURL:url
                   uniqueID:uniqueID
                       from:external ? OpenUrlFromSceneOpenSchemaExternalTrue : OpenUrlFromSceneOpenSchemaExternalFalse
                   external:external
                    appType:appType
             fromController:fromController
           whiteListChecker:whiteListChecker];
}

- (BOOL)bdp_interceptWebViewRequest:(NSURL *)url
                           uniqueID:(BDPUniqueID *)uniqueID
                           fromView:(UIView * _Nullable)fromView {
    BDPLogInfo(@"bdp_interceptWebViewRequest, uniqueID=%@", uniqueID);
    // 在小程序webview组件内部，对于普通的http链接只允许跳转外部应用
    BDPOpenSchemaResult ret = [self tryOpenURL:url
                                      uniqueID:uniqueID
                                          from:OpenUrlFromSceneWebView
                                      external:YES
                                       appType:BDPTypeNativeApp
                                fromController:[OPNavigatorHelper topMostAppControllerWithWindow:fromView.window?:uniqueID.window]
                              whiteListChecker:nil];
    return ret == BDPOpenSchemaResultSuccess;
}

- (BDPOpenSchemaResult)tryOpenURL:(NSURL *)url
                         uniqueID:(BDPUniqueID *)uniqueID
                             from:(OpenUrlFromScene)fromScene
                         external:(BOOL)external
                          appType:(BDPType)appType
                   fromController:(UIViewController * _Nullable)fromController
                 whiteListChecker:(BDPAuthorization *)whiteListChecker {
    BDPLogInfo(@"tryOpen, uniqueID=%@, interceptForWebView=%@, external=%@", uniqueID, @(fromScene), @(external));
    if (!url) {
        BDPLogWarn(@"!url");
        return BDPOpenSchemaResultOtherFailed;
    }
    // 1. 优先交给宿主处理：打开Docs/其他小程序
    id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
    if ([delegate respondsToSelector:@selector(canOpenURL:fromScene:)]
        && [delegate canOpenURL:url fromScene:fromScene]
        && [delegate respondsToSelector:@selector(openURL:fromScene:uniqueID:fromController:)]) {
        [delegate openURL:url fromScene:fromScene uniqueID:uniqueID fromController:fromController];
        BDPLogInfo(@"handle by host");
        return BDPOpenSchemaResultSuccess;
    }
    // 2. 检查是否需要由外部处理
    // 支持跳转到App Store或者直接在应用内下载企业包
    // 拉取失败则使用上次本地缓存配置
    BOOL result = NO;
    if (appType == BDPTypeBlock && (fromScene == OpenUrlFromSceneOpenSchemaExternalFalse || fromScene == OpenUrlFromSceneOpenSchemaExternalTrue) && [OpenSchemaRefactorPolicy refactorEnabled] && whiteListChecker) {
        // openSchema API一致性治理，统一 block和小程序的 白名单校验逻辑
        result = [whiteListChecker checkSchema:&url uniqueID:uniqueID errorMsg:NULL];
    } else {
        if (appType == BDPTypeWebApp || appType == BDPTypeNativeCard || appType == BDPTypeBlock) {
            result = YES;
        } else {
            result = [EMAAppEngine.currentEngine.onlineConfig isOpeningURLInWhiteList:url
                                                                             uniqueID:uniqueID
                                                                  interceptForWebView:fromScene == OpenUrlFromSceneWebView
                                                                             external:external];
            // 埋点
            [BDPTracker event:fromScene == OpenUrlFromSceneWebView?@"mp_open_url":@"mp_open_schema" attributes:@{
                @"appid": uniqueID.appID ?: @"",
                @"url": url.absoluteString ?: @"",
                @"result": @(result)
            } uniqueID:uniqueID];
        }
    }
    // 临时逻辑，待删除 >>> start
    // 头条圈会更新版本改为使用openSchema接口。
    // 目前为了兼容Lark旧版本不跳转到外部浏览器，先不将头条圈配置到白名单，过几个版本再配置
    // 操作：针对external为NO且是头条圈，则支持跳转Lark内部浏览器
    if (!external && [uniqueID.appID isEqualToString:@"tt06bd70009997ab3e"]) {
        result = YES;
    }
    // 临时逻辑，待删除 <<< end

    if (!result) {
        BDPLogInfo(@"not allowed by white list");
        return BDPOpenSchemaResultAuthFailed;
    }

    // 跳转外部APP
    // 去掉了 `canOpen` 的判断，这样会限制只能判断 SchemaList 中的 Schema
    if (external) {
        BOOL opened = [UIApplication.sharedApplication openURL:url];
        if (opened) {
            BDPLogInfo(@"handle by other application");
            return BDPOpenSchemaResultSuccess;
        } else {
            BDPLogWarn(@"no app can handle this url");
        }
    }

    // 跳转Lark内部浏览器
    // 具体方案参考：https://bytedance.feishu.cn/space/doc/doccnt8Kr9nqp95dYBm8pw
    if (!external) {
        id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
        if ([delegate respondsToSelector:@selector(openInternalWebView:uniqueID:fromController:)]) {
            if ([delegate openInternalWebView:url uniqueID:uniqueID fromController:fromController]) {
                BDPLogInfo(@"handle by app internal webview");
                return BDPOpenSchemaResultSuccess;
            }
        }
    }

    return BDPOpenSchemaResultOtherFailed;
}

- (void)bdp_closeMiniParam:(UIViewController *)container completion:(nullable void(^)(BOOL))completion {
    [EENavigatorBridge closeMiniProgramWith:container completion:completion];
}

- (void)aboutHandlerForUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        BDPLogError(@"openAboutVCWithUniqueID, uniqueID is invalid");
        return;
    }
    id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
    if ([delegate respondsToSelector:@selector(openAboutVCWithUniqueID:appVersion:)]) {
        /// 通过uniqueID获取到当前运行的appVersion
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        NSString *appVersion = common.model.version;
        
        /// Lark App 打开外部的关于页面
        [delegate openAboutVCWithUniqueID:uniqueID appVersion:appVersion?:@""];
    }
}

@end
