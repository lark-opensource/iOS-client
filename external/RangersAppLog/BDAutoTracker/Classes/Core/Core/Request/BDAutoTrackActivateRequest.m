//
//  BDAutoTrackActivateRequest.m
//  RangersAppLog
//
//  Created by bob on 2019/9/15.
//

#import "BDAutoTrackActivateRequest.h"
#import "BDTrackerCoreConstants.h"
#import "BDMultiPlatformPrefix.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackNotifications.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackUtility.h"

#import "BDAutoTrackRegisterService.h"
#import "BDAutoTrackSandBoxHelper.h"
#import "BDAutoTrackNetworkRequest.h"
#if DEBUG && __has_include("BDAutoTrackASA.h")
#import "BDAutoTrackASA.h"
#endif

#import "NSDictionary+VETyped.h"
#import "BDAutoTrack+Private.h"

@interface BDAutoTrackActivateRequest ()

@end

@implementation BDAutoTrackActivateRequest

/// activate请求在初始化时会观察BDAutoTrackNotificationRegisterSuccess, 在观察的回调中发起激活请求。
- (instancetype)initWithAppID:(NSString *)appID next:(BDAutoTrackRequest *)nextRequest {
    self = [super initWithAppID:appID next:nextRequest];
    if (self) {
        self.requestType = BDAutoTrackRequestURLActivate;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onRegisterSuccess:)
                                                     name:BDAutoTrackNotificationRegisterSuccess
                                                   object:nil];
    }

    return self;
}

/// Callback: Observe RegisterSuccessNotification. Send an followed activateRequest if DataSource == Server.
- (void)onRegisterSuccess:(NSNotification *)not {
    NSString *appID = not.userInfo[kBDAutoTrackNotificationAppID];
    if ([appID isEqualToString:self.appID] &&
        [not.userInfo[kBDAutoTrackNotificationDataSource] isEqualToString:BDAutoTrackNotificationDataSourceServer]) {

        if ([BDAutoTrack trackWithAppID:appID].localConfig.autoActiveUser || self.needActiveUser) {
            [self startRequestWithRetry:3];
        }
    }
}

- (BOOL)handleResponse:(NSDictionary *)responseDict urlResponse:(NSURLResponse *)urlResponse request:(nonnull NSDictionary *)request {
    BOOL success = bd_isResponseMessageSuccess(responseDict);
    if (success) {
        NSString *appID = self.appID;
        NSDictionary *userInfo = @{kBDAutoTrackNotificationAppID: appID};
        [[NSNotificationCenter defaultCenter] postNotificationName:BDAutoTrackNotificationActiveSuccess
                                                            object:nil
                                                          userInfo:userInfo];
        BOOL activated = [[responseDict vetyped_dictionaryForKey:@"data"] vetyped_boolForKey:@"is_activated"];
        if (activated) {
            self.needActiveUser = NO;
            [bd_registerServiceForAppID(self.appID) saveActivateState:YES];
        }
    }

    return success;
}

- (NSString *)requestURL {
    NSString *appID = self.appID;
    
   
    
    NSString *requestURL = [super requestURL];
    NSMutableDictionary *result = [NSMutableDictionary new];
    [result addEntriesFromDictionary:bd_requestURLParameters(appID)];
    bd_addSettingParameters(result, appID);
    bd_registeredAddParameters(result, appID);
    [result setValue:nil forKey:kBDAutoTrackCustom];
    [result setValue:bd_registerinstallID(appID) forKey:@"iid"];
    
    [result setValue:bd_sandbox_releaseVersion() forKey:kBDAutoTrackerVersionCode];
    
    //add active custom data
    BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:appID];
    BDAutoTrackLocalConfigService *local = tracker.localConfig;
    if (local.activeCustomParamsBlock) {
        NSDictionary *customHeaders = local.activeCustomParamsBlock();
        [customHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *obj_str = @"";
            if (obj != [NSNull null]) {
                obj_str = [NSString stringWithFormat:@"%@", obj];
            }
            [result setValue:obj_str forKey:[NSString stringWithFormat:@"custom_%@",key]];
        }];
    }
    
    BDAutoTrackNetworkEncryptor *encryptor = tracker.networkManager.encryptor;
    result = [encryptor encryptParameters:result allowedKeys:@[kBDAutoTrackAPPID]];
    
    /* Apple Search Ads相关字段。私有化从设备注册接口透传给设备激活，公有云直接在此传递给设备激活。
     */
    Class cls_BDAutoTrackASA = NSClassFromString(@"BDAutoTrackASA");
    if (cls_BDAutoTrackASA) {
        SEL sel = NSSelectorFromString(@"ASAParams");
        if ([cls_BDAutoTrackASA respondsToSelector:sel]) {
            NSDictionary *asaParams = [cls_BDAutoTrackASA performSelector:sel];
            if ([asaParams isKindOfClass:[NSDictionary class]]) {
                [result addEntriesFromDictionary:asaParams];
            }
        }
    }
    return bd_appendQueryDictToURL(requestURL, result);
}

- (NSMutableDictionary *)requestParameters {
    return [NSMutableDictionary new];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
