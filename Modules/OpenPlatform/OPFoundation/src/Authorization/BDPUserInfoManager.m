//
//  BDPUserInfoManager.m
//  Timor
//
//  Created by liuxiangxin on 2019/6/25.
//

#import "BDPUserInfoManager.h"
#import "BDPAuthModuleProtocol.h"
#import <ECOInfra/BDPLogHelper.h>
#import "BDPModuleManager.h"
#import "BDPMonitorHelper.h"
#import "BDPNetworking.h"
#import "BDPSandboxProtocol.h"
#import "BDPUserAgent.h"
#import "BDPUtils.h"
#import "NSData+BDPExtension.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "GadgetSessionStorage.h"
#import "BDPTimorClient.h"
#import "BDPMonitorEvent.h"
#import <OPFoundation/OPFoundation-Swift.h>

NSErrorDomain const BDPUserInfoErrorDomain = @"BDPUserInfoErrorDomain";
NSString * const BDPUserInfoServerErrorKey = @"BDPUserINfoServierErrorKey";
NSString *const BDPUserInfoAvatarURLKey = @"avatarUrl";
NSString *const BDPUserInfoCityKey = @"city";
NSString *const BDPUserInfoCountryKey = @"country";
NSString *const BDPUserInfoGenderKey = @"gender";
NSString *const BDPUserInfoLanguageKey = @"language";
NSString *const BDPUserInfoNickNameKey = @"nickName";
NSString *const BDPUserInfoProvicneKey = @"province";
NSString *const BDPUserInfoRawDataKey = @"rawData";
NSString *const BDPUserInfoUserIDKey = @"userId";
NSString *const BDPUserInfoUserInfoKey = @"userInfo";
NSString *const BDPUserInfosessionIDKey = @"sessionId";
static const NSInteger kServerErrorCodeNone = -1;

@implementation BDPUserInfoManager

#pragma mark - UserInfo

+ (void)fetchUserInfoWithCredentials:(BOOL)credentials
                             context:(BDPPluginContext)context
                          completion:(void (^)(NSDictionary *userInfo, NSError *error))completion

{
    void (^CompletionBlk)(NSDictionary *userInfo, NSError *error) = nil;
    CompletionBlk = ^(NSDictionary *userInfo, NSError *error) {
        if (completion) {
            completion(userInfo, error);
        }
    };
    
    BDPPlugin(userPlugin, BDPUserPluginDelegate);
    //这里默认返回true,就不对应用形态做区分了
    if (![userPlugin bdp_isLogin]) {
        NSError *error = [self errorForErrorCode:BDPUserInfoErrorCodeNotLogin serverCode:kServerErrorCodeNone];
        CompletionBlk(nil, error);
        return;
    }

    BDPResolveModule(auth, BDPAuthModuleProtocol, context.engine.uniqueID.appType);
    NSString *session = [auth getSessionContext:context];
    NSMutableDictionary *headerFieldDict = [NSMutableDictionary dictionary];
    headerFieldDict[@"User-Agent"] = [BDPUserAgent getUserAgentString];
    if(context) {
        [headerFieldDict addEntriesFromDictionary:[GadgetSessionFactory storageForPluginContext:context].sessionHeader];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:context.engine.uniqueID.appID forKey:@"appid"];
    [params setValue:session forKey:@"session"];
    [params setValue:credentials ? @"true": @"false" forKey:@"withCredentials"];
    NSString *url = [auth userInfoURLUniqueID:context.engine.uniqueID];
    NSString *eventName = @"getUserInfo";
    [BDPLogHelper logRequestBeginWithEventName:eventName URLString:url];
    
    OPMonitorEvent *monitor = BDPMonitorWithName(kEventName_mp_user_info_result, context.engine.uniqueID).timing();
    
    BDPNetworkRequestExtraConfiguration* config = [BDPNetworkRequestExtraConfiguration defaultConfig];
    config.bdpRequestHeaderField = headerFieldDict;
    [BDPNetworking taskWithRequestUrl:url parameters:[params copy] extraConfig:config completion:^(NSError *error, id jsonObj, id<BDPNetworkResponseProtocol> response) {
        [BDPLogHelper logRequestEndWithEventName:eventName URLString:url error:error];
        [self parseUserInfoJson:jsonObj callback:completion error:error uniqueID: context.engine.uniqueID userPluginDelegate:userPlugin monitor:monitor];
    }];
}

+ (void)parseUserInfoJson:(NSDictionary *)jsonObj
                 callback:(void (^)(NSDictionary *userInfo, NSError *error))completion
                    error:(NSError *)error
                 uniqueID:(OPAppUniqueID *)uniqueID
       userPluginDelegate:(id<BDPUserPluginDelegate>)userPlugin
                  monitor:(OPMonitorEvent *)monitor
{
    void (^CompletionBlk)(NSDictionary *userInfo, NSError *error) = nil;
    CompletionBlk = ^(NSDictionary *userInfo, NSError *error) {
        if (completion) {
            BDPExecuteOnMainQueue(^{
                completion(userInfo, error);
            });
        }
    };
    
    if (error) {
        monitor.kv(kEventKey_result_type, kEventValue_fail).setError(error).flush();
        NSError *err = [self errorForErrorCode:BDPUserInfoErrorCodeServerError serverCode:kServerErrorCodeNone];
        CompletionBlk(nil, err);
        return;
    }
    
    if (![jsonObj isKindOfClass:[NSDictionary class]]) {
        monitor.kv(kEventKey_result_type, kEventValue_fail).kv(kEventKey_error_msg, @"Response Data Error").flush();
    }
    
    NSDictionary *dict = [jsonObj copy];
    if (![dict isKindOfClass:NSDictionary.class] || BDPIsEmptyDictionary(dict)) {
        NSError *err = [self errorForErrorCode:BDPUserInfoErrorCodeServerError serverCode:kServerErrorCodeNone];
        CompletionBlk(nil, err);
        return;
    }
    
    NSInteger code = [dict bdp_integerValueForKey:@"error"];
    if (code != 0) {
        NSError *err = [self errorForErrorCode:BDPUserInfoErrorCodeServerError serverCode:code];
        CompletionBlk(nil, err);
        return;
    }
    
    NSDictionary *data = [dict bdp_dictionaryValueForKey:@"data"];
    // 兼容之前的接口结构，目前仅有Lark小程序在用 @houzhiyou
    dict = data ?: dict;
    BDPResolveModule(auth, BDPAuthModuleProtocol, uniqueID.appType);
    NSDictionary *userDict = [auth userInfoDict:dict uniqueID:uniqueID];
    CompletionBlk(userDict, nil);
    monitor.kv(kEventKey_result_type, kEventValue_success).timing().kv(kEventKey_error_code, jsonObj[@"error"]).kv(kEventKey_error_msg, jsonObj[@"message"]).flush();
}

+ (NSError *)errorForErrorCode:(BDPUserInfoErrorCode)errorCode serverCode:(NSInteger)serverCode
{
    if (errorCode == BDPUserInfoErrorCodeNone) {
        return nil;
    }
    
    NSString *desc = @"error";
    switch (errorCode) {
        case BDPUserInfoErrorCodeNone:
            break;
        case BDPUserInfoErrorCodeServerError:
            desc = @"server error";
            break;
        case BDPUserInfoErrorCodeInvalidSession:
            desc = @"invalid session";
            break;
        case BDPUserInfoErrorCodeNotLogin:
            desc = @"Please Login.";
            break;
        case BDPUserInfoErrorCodeUnknow:
            break;
    }
    
    NSNumber *serverErrCode = nil;
    if (serverCode != kServerErrorCodeNone) {
        serverErrCode = @(serverCode);
    }
    
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : desc
                               }.mutableCopy;
    [userInfo setValue:serverErrCode forKey:BDPUserInfoServerErrorKey];
    NSError *error = [NSError errorWithDomain:BDPUserInfoErrorDomain code:errorCode userInfo:userInfo];

    return error;
}


@end
