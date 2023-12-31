//
//  BDPUserPluginCustomImpl.m
//  Pods
//
//  Created by zhangkun on 25/07/2018.
//

#import "BDPUserPluginCustomImpl.h"
#import "EERoute.h"
#import "EMAAppEngine.h"
#import "EMAAppEngine.h"
#import <OPFoundation/EMAMonitorHelper.h>
#import <OPFoundation/EMANetworkAPI.h>
#import <ECOInfra/EMANetworkManager.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPUserPluginDelegate.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOProbe/OPTrace.h>
#import <ECOProbe/OPTraceService.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>

@interface BDPUserPluginCustomImpl() <BDPUserPluginDelegate>
@end

@implementation BDPUserPluginCustomImpl

#pragma mark - TMAPluginLoginDelegate

+ (id<BDPUserPluginDelegate>)sharedPlugin
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (BOOL)bdp_isLogin
{
    return YES;
}

- (nullable NSString *)bdp_userId
{
    EMAAppEngine *engine = [self getAppEngine];
    NSString *userId = engine.account.userID;
    if(userId.length == 0){
        NSString *msg = @"EMAAppEngine.currentEngine.account.userId is empty";
        NSAssert(false, msg);
        BDPLogError(msg)
    }
    return userId;
}

- (nullable NSString *)bdp_appId
{
    return @"0";
    /* SSAppID在头条小程序里代表宿主的标识，EE小程序的宿主固定是Lark，我们直接通过调用[[[NSBundle mainBundle] infoDictionary] setValue:@"0" forKey:@"SSAppID"]直接设置这个值为@"0"
     return kAppID;
     */
}


- (nullable NSString *)bdp_sessionId
{
    EMAAppEngine *engine = [self getAppEngine];
    NSString *sessionId = engine.account.userSession;
    if (sessionId.length == 0) {
        NSString *msg = @"EMAAppEngine.currentEngine.account.userSession is empty";
        NSAssert(false, msg);
        BDPLogError(msg)
    }
    return sessionId;
    /**
     return kSessionID;
     */
}

- (nullable NSString *)bdp_deviceId
{
    NSString *deviceID;
    id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
    if([delegate respondsToSelector:@selector(hostDeviceID)]) {
        deviceID = delegate.hostDeviceID;
    }
    return deviceID;
}

- (nullable NSString *)bdp_encyptTenantId
{
    EMAAppEngine *engine = [self getAppEngine];
    NSString *encyptedTenantID = engine.account.encyptedTenantID;
    if(encyptedTenantID.length == 0){
        NSString *msg = @"EMAAppEngine.currentEngine.account.encyptedTenantID is empty";
        NSAssert(false, msg);
        BDPLogError(msg)
    }
    return encyptedTenantID;
}

#pragma mark - Private
/** currentEngine可能会是nil或者被替换;(Lark登出或者切换租户)
    使用一个临时指针持有当前的EMAAppEngine对象以保证此次调用过程中对象不会被释放;
    否则访问其成员变量可能会造成crash;
 */
- (nullable EMAAppEngine *)getAppEngine {
    EMAAppEngine *engine = EMAAppEngine.currentEngine;
    if (!engine) {
        BDPLogError(@"EMAAppEngine.currentEngine is empty!");
    }
    return engine;
}

#pragma clang diagnostic pop

- (void)bdp_loginWithParam:(NSDictionary *)param completion:(void (^)(BOOL, NSString *, NSString *))completion
{
    BDPLogInfo(@"bdp_login");
    if (completion) {
        completion(YES, @"0", [self bdp_sessionId]);
    }
}

- (void)bdp_customUserInfoResultWithResponse:(NSDictionary *)response completion:(void (^)(BOOL, NSDictionary *))completion {
    BDPLogInfo(@"bdp_customUserInfoResult, responseIsExist=%@", @(response != nil));
    // 判断用户信息是否已授权
    NSInteger errorCode = [response bdp_integerValueForKey:@"error"];
    BOOL isError = (errorCode != 0);
    if (completion) {
        if (isError) {
            NSString *reason = [response bdp_stringValueForKey:@"message"];
            reason = reason.length > 0 ? reason : @"unknown error";
            NSError *error = [NSError errorWithDomain:@"UserInfoError" code:errorCode userInfo:@{NSLocalizedDescriptionKey: reason}];
            NSMutableDictionary *result = [NSMutableDictionary dictionary];
            result[BDPUserPluginResultErrorKey] = error;
            completion(NO, result);
        } else {
            completion(YES, response);
        }
    }
}

- (void)bdp_checkSessionWithParam:(NSDictionary *)param completion:(void (^)(BOOL valid))completion {
    BDPLogInfo(@"bdp_checkSession");
    OPMonitorEvent *monitor = BDPMonitorWithName(kEventName_mp_check_session, nil).timing();
    [EMANetworkManager.shared postUrl:EMAAPI.checkSessionURL params:param completionWithJsonData:^(NSDictionary * _Nullable json, NSError * _Nullable error) {
        if (error) {
            BDPLogError(@"dataTaskWithRequest error!!! %@", BDPParamStr(error));
            monitor.kv(kEventKey_result_type, kEventValue_fail).setError(error).flush();
            if (completion) {
                completion(NO);
            }
            return;
        }

        NSDictionary *data = [json bdp_dictionaryValueForKey:@"data"];
        BOOL valid = NO;
        NSString *validString = [data bdp_objectForKey:@"valid"];
        if (validString != nil &&
            ([validString caseInsensitiveCompare:@"true"] == NSOrderedSame ||
             [validString caseInsensitiveCompare:@"yes"] == NSOrderedSame)) {
            valid = YES;
        } else {
            valid = ([validString intValue] == 0) ? NO : YES;
        }
        if (completion) {
            completion(valid);
        }
        BDPLogInfo(@"checkSessionResult");
        monitor.kv(kEventKey_result_type, kEventValue_success).timing().flush();
    } eventName:@"checkSession" requestTracing:nil];
}

@end
