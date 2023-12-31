//
//  TMAPluginLogin.m
//  Timor
//
//  Created by muhuai on 2017/12/21.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "BDPPluginUser.h"
#import <OPFoundation/BDPAuthModuleProtocol.h>
#import <OPFoundation/BDPAuthorization+BDPUI.h>
#import <OPFoundation/BDPAuthorization+BDPUserPermission.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPDeviceManager.h>
#import <OPFoundation/BDPI18n.h>
#import <OPPluginManagerAdapter/BDPJSBridge.h>
#import <ECOInfra/BDPLogHelper.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPNetworking.h>
#import <OPFoundation/BDPRouteMediator.h>
#import <OPFoundation/BDPSDKConfig.h>
#import "BDPTaskManager.h"
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPUserAgent.h>
#import <OPFoundation/BDPUserInfoManager.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/NSData+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <OPFoundation/TMASecurity.h>
#import <OPFoundation/TMASessionManager.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import "BDPSandboxEntity.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/OPAPIDefine.h>
#import "BDPGadgetPreLoginManager.h"
#import <ECOInfra/NSURLSessionTask+Tracing.h>
#import <ECOInfra/OPTrace+RequestID.h>
#import <OPFoundation/BDPMonitorEvent.h>

#define LoginJSBCallBackGuard(condition, status, errMsg) \
{ \
    self.isLoginFinish = YES; \
    BDP_INVOKE_GUARD(condition, status, errMsg) \
}

#define LoginJSBCallBackGuardNew(condition, responseCallback, errMsg) \
{ \
    self.isLoginFinish = YES; \
    OP_INVOKE_GUARD_NEW(condition, responseCallback, errMsg) \
}

@interface BDPPluginUser()

@property (nonatomic, assign) BOOL isLoginFinish;
@property (nonatomic, assign) BOOL isHostLoginFinish;

@end

@implementation BDPPluginUser

+ (BDPJSBridgePluginMode)pluginMode
{
    return BDPJSBridgePluginModeLifeCycle;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isLoginFinish = YES;
        _isHostLoginFinish = YES;
    }
    return self;
}

#pragma mark - Function Implementation
/*-----------------------------------------------*/
//       Function Implementation - 功能实现
/*-----------------------------------------------*/

- (void)loginWithParam:(NSDictionary *)param callback:(BDPJSBridgeCallback)callback engine:(BDPJSBridgeEngine)engine controller:(UIViewController *)controller
{
    OP_API_RESPONSE(OPAPIResponse)
    BDPLogInfo(@"tma_login, app=%@, isLoginFinish=%@", engine.uniqueID, @(self.isLoginFinish));
    __weak BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:engine.uniqueID];
    __weak BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:engine.uniqueID];
    
    [BDPTracker beginEvent:@"mp_login" primaryKey:BDPTrackerPKLogin attributes:nil uniqueID:engine.uniqueID];

    BDPPlugin(userPlugin, BDPUserPluginDelegate);
    OP_INVOKE_GUARD_NEW(!self.isLoginFinish, [response callback:LoginAPICodeNotRetry], @"logining, not retrys");
    OP_INVOKE_GUARD_NEW(![userPlugin respondsToSelector:@selector(bdp_loginWithParam:completion:)], [response callback:OPGeneralAPICodeUnable], @"Client NOT Impl the API `login`.");
    
    self.isLoginFinish = NO;
    BOOL forceLogin = [param valueForKey:@"force"] ? [param bdp_boolValueForKey:@"force"] : YES;
    if (![userPlugin bdp_isLogin] && forceLogin) {
        [task.containerVC startAdaptOrientation];
        [BDPTracker event:@"mp_login_page_show" attributes:nil uniqueID:engine.uniqueID];
    }
    
    NSMutableDictionary *paramDict = [NSMutableDictionary new];
    [paramDict setValue:BDPStringUglify_micro_app forKey:@"login_source"];
    [paramDict setValue:@(forceLogin) forKey:@"force"];
    [paramDict setValue:engine.uniqueID.appID forKey:@"mp_id"];
    
    if ([param isKindOfClass:[NSDictionary class]] && param.count > 0) {
        [paramDict addEntriesFromDictionary:param];
    }
    
    void (^loginResultBlk)(BOOL success, NSString *userId, NSString *sessionId) = ^void(BOOL success, NSString *userId, NSString *sessionId) {
        if (forceLogin) {
            [BDPTracker event:@"mp_login_page_result"
                   attributes:@{BDPTrackerResultTypeKey: success ? BDPTrackerResultSucc : BDPTrackerResultFail}
         uniqueID:engine.uniqueID];
        }
        
        [task.containerVC endAdaptOrientation];
        
        if (!success) {
            self.isLoginFinish = YES;
            BDPLogError(@"login failed, login result is not success,appId=%@, userId=%@", engine.uniqueID, userId);
            OP_CALLBACK_WITH_ERRMSG([response callback:LoginAPICodeFail], @"login failed");
            return;
        }
        
        //开启预登陆配置的逻辑时，优先走prelogin缓存。提高tt.login的效率
        //https://bytedance.feishu.cn/docs/doccnUsnqAo5zYHtychs5OFLJgt
        //避免线上出现有登陆过程，但from_pre_login 埋点是空的情况。造成数据异常
        
        if ([[BDPGadgetPreLoginManager sharedInstance] preloginEnableWithUniqueId:engine.uniqueID]) {
            OPMonitorEvent *monitor = BDPMonitorWithName(kEventName_mp_login_result, engine.uniqueID).kv(@"from_pre_login", @"true").timing();
            [[BDPGadgetPreLoginManager sharedInstance] preloginWithUniqueId:engine.uniqueID
                                                                   callback:^(NSError *error, id jsonObj) {
                [BDPLogHelper logRequestEndWithEventName:@"wx.login"
                                               URLString:[BDPSDKConfig sharedConfig].userLoginURL
                                                   error:error];
                OPMonitorEvent * monitorClone = monitor;
                if (!BDPIsEmptyDictionary(jsonObj) && [jsonObj bdp_boolValueForKey2:@"from_pre_login"]) {
                    monitorClone = monitor.kv(@"from_pre_login", @"true");
                }
                [self parseLoginJson:jsonObj response:response error:error forceLogin:forceLogin engine:engine monitor:monitorClone];
                
            }];
            return;
        }
        
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params setValue:engine.uniqueID.appID forKey:@"appid"];
        [params setValue:[[TMASessionManager sharedManager] getAnonymousID] forKey:@"anonymousid"];
        
        // 2019-12-1 "育儿数据&宝宝树"需求，在login请求header中增加宿主did参数（https://bytedance.feishu.cn/docs/doccnHZZPvcZwt8NmcCPMPwjdnh#）
        BDPPlugin(userPlugin, BDPUserPluginDelegate);
        NSString *deviceId = @"";
        if ([userPlugin respondsToSelector:@selector(bdp_deviceId)]) {
            deviceId = [userPlugin bdp_deviceId];
        }
        
        NSString *url = [BDPSDKConfig sharedConfig].userLoginURL;
        NSString *eventName = @"wx.login";
        [BDPLogHelper logRequestBeginWithEventName:eventName URLString:url];
        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        [headers setValue:sessionId forKey:@"X-Tma-Host-Sessionid"];
        [headers setValue:BDPSafeString(deviceId) forKey:@"X-Tma-Host-Deviceid"];
        headers[@"User-Agent"] = [BDPUserAgent getUserAgentString];
        OPMonitorEvent *monitor = BDPMonitorWithName(kEventName_mp_login_result, engine.uniqueID).kv(@"from_pre_login", @"false").timing();

        BDPNetworkRequestExtraConfiguration *config = [BDPNetworkRequestExtraConfiguration defaultConfig];
        config.bdpRequestHeaderField = headers;
        id<BDPNetworkTaskProtocol> networkTask = [BDPNetworking taskWithRequestUrl:url parameters:[params copy] extraConfig:config completion:^(NSError *error, id jsonObj, id<BDPNetworkResponseProtocol> networkResponse) {
            [BDPLogHelper logRequestEndWithEventName:eventName URLString:url error:error];
            [self parseLoginJson:jsonObj response:response error:error forceLogin:forceLogin engine:engine monitor:monitor];
        }];
        
        if([networkTask isKindOfClass:[NSURLSessionTask class]] && [[(NSURLSessionTask *)networkTask trace] getRequestID]) {
            monitor.addCategoryValue(@"request_id", [[(NSURLSessionTask *)networkTask trace] getRequestID]);
        }
    };
    if ([userPlugin bdp_isLogin]) {
        loginResultBlk(YES, [userPlugin bdp_userId], [userPlugin bdp_sessionId]);
    } else {
        [userPlugin bdp_loginWithParam:[paramDict copy] completion:loginResultBlk];
    }
}

#pragma mark - Utils
/*-----------------------------------------------*/
//                  Utils - 工具
/*-----------------------------------------------*/
- (void)parseLoginJson:(NSDictionary *)jsonObj response:(OPAPIResponse *)response error:(NSError *)error forceLogin:(BOOL)forceLogin engine:(BDPJSBridgeEngine)engine monitor:(OPMonitorEvent *)monitor
{
    if (error) {
        BDPLogWarn(@"login error, app=%@, error=%@, forceLogin=%@", engine.uniqueID, error, @(forceLogin));
        monitor.kv(kEventKey_result_type, kEventValue_fail).setError(error).flush();
    }
    
    if (![jsonObj isKindOfClass:[NSDictionary class]]) {
        BDPLogWarn(@"login jsonObj class invalid, app=%@, jsonObjClass=%@, forceLogin=%@", engine.uniqueID, NSStringFromClass([jsonObj class]), @(forceLogin));
        monitor.kv(kEventKey_result_type, kEventValue_fail).kv(kEventKey_error_msg, @"Response Data Error").flush();
    }

    LoginJSBCallBackGuardNew(error, [response callback:OPGeneralAPICodeUnkonwError], @"server error");
    LoginJSBCallBackGuardNew(![jsonObj isKindOfClass:[NSDictionary class]], [response callback:OPGeneralAPICodeJsonError], @"server error");
    LoginJSBCallBackGuardNew(BDPIsEmptyDictionary(jsonObj), [response callback:OPGeneralAPICodeJsonError], @"server error");
    
    NSString *session = [jsonObj bdp_stringValueForKey:@"session"];
    NSString *anonymousID = [jsonObj bdp_stringValueForKey:@"anonymousid"];
    NSDictionary *dataDict = [jsonObj bdp_dictionaryValueForKey:@"data"];
    NSInteger errorCode = [jsonObj bdp_integerValueForKey:@"error"];
    NSString *errorMsg = [NSString stringWithFormat:@"server error %ld", (long)errorCode];
    if (errorCode != 0) {
        BDPLogWarn(@"login business error, app=%@, errorCode=%@, forceLogin=%@", engine.uniqueID, @(errorCode), @(forceLogin));
    }
    LoginJSBCallBackGuardNew(errorCode != 0, [response callback:OPGeneralAPICodeUnkonwError], errorMsg);

    OPAppUniqueID *uniqueId = engine.uniqueID;
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, uniqueId.appType);
    id<BDPSandboxProtocol> sandbox = [storageModule sandboxForUniqueId:uniqueId];

    [[TMASessionManager sharedManager] updateAnonymousID:anonymousID];
    [[TMASessionManager sharedManager] updateSession:session sandbox:sandbox];
    
    self.isLoginFinish = YES;
    OP_CALLBACK_WITH_DATA([response callback:OPGeneralAPICodeOk], dataDict)
    [BDPTracker endEvent:@"mp_login_result" primaryKey:BDPTrackerPKLogin attributes:nil uniqueID:uniqueId];
    
    monitor.kv(kEventKey_result_type, kEventValue_success).timing().kv(kEventKey_error_code, jsonObj[@"error"]).kv(kEventKey_error_msg, jsonObj[@"message"]).flush();
}

@end

