//
//  EMARequestUtil.m
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2019/8/19.
//

#import "EMARequestUtil.h"
#import <OPFoundation/EMAMonitorHelper.h>
#import <OPFoundation/EMANetworkAPI.h>
#import <OPFoundation/EMANetworkCipher.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/EMAConfig.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPCommon.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/TMASessionManager.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/OPTrace+RequestID.h>
#import <ECOInfra/EMANetworkManager.h>
#import <ECOInfra/ECONetworkGlobalConst.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <ECOProbe/OPMonitor.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/GadgetSessionStorage.h>
#import <OPFoundation/BDPAuthModuleProtocol.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/EEFeatureGating.h>

NSString *const EMARequestErrorDomain = @"EMARequestErrorDomain";

@implementation EMARequestUtil

+ (void)fetchOpenPluginChatIDsByChatIDs:(nonnull NSArray<NSDictionary *> *)chatItems
                               uniqueID:(OPAppUniqueID *)uniqueID
                                session:(NSString *)session
                          sessionHeader:(NSDictionary*)sessionHeader
                      completionHandler:(nonnull void (^)(NSDictionary *_Nullable openChatIdDict, NSError *_Nullable error))completionHandler {
    // 统一的错误吗，这里没有变更，只做一下注释
    NSInteger commonErrorCode = -9999;
    
    void (^handleResult)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error, EMANetworkCipher *cipher) = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error, EMANetworkCipher *cipher) {
        OPMonitorEvent *monitor = BDPMonitorWithName(kEventName_mp_fetch_openchatid, uniqueID).timing();
        if (error) {
            monitor.kv(kEventKey_result_type, kEventValue_fail).setError(error).flush();
        } else {
            monitor.kv(kEventKey_result_type, kEventValue_success).timing().flush();
        }
        if (!completionHandler) {
            BDPLogError(@"completionHandler is nil")
            return;
        }
        if (!data || error) {
            BDPExecuteOnMainQueue(^{
                NSString *msg = @"invaild data";
                BDPLogError(@"%@ %@", msg, error.localizedDescription ?: @"")
                completionHandler(@{}, error ?: [NSError errorWithDomain:msg code:commonErrorCode userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }
        NSError *serializationError;
        NSDictionary *dict = [data JSONValueWithOptions:NSJSONReadingAllowFragments error:&serializationError];
        if (BDPIsEmptyDictionary(dict) || serializationError) {
            BDPExecuteOnMainQueue(^{
                NSString *msg = serializationError.localizedDescription ?: @"response dict is nil";
                BDPLogError(msg)
                completionHandler(@{}, serializationError ?: [NSError errorWithDomain:msg code:commonErrorCode userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }
        NSString *encryptedContent = [dict bdp_stringValueForKey:@"encryptedData"];
        NSDictionary<NSString *, NSString *> *openChatIDs;
        NSDictionary *decryptedDict = [EMANetworkCipher decryptDictForEncryptedContent:encryptedContent cipher:cipher];
        if ([decryptedDict isKindOfClass:[NSDictionary class]]) {
            BDPLogInfo(@"decryptedDict is not kind of NSDictionary")
            openChatIDs = [decryptedDict bdp_dictionaryValueForKey:@"openchatids"];
        }
        if (![openChatIDs isKindOfClass:[NSDictionary class]]) {
            BDPLogInfo(@"openChatIDs is not kind of NSDictionary")
            openChatIDs = nil;
        }
        BDPExecuteOnMainQueue(^{
            BDPLogInfo(@"completion %@", BDPParamStr(openChatIDs, error))
            completionHandler(openChatIDs, serializationError ?: error);
        });
    };
    
    OPTrace *tracing = [self generateRequestTracing:uniqueID];
    BDPLogInfo(@"uniqueID shoule not be nil, app=%@", uniqueID);
    if (BDPIsEmptyArray(chatItems)) {
        NSString *msg = @"chatItems is empty";
        BDPLogError(msg)
        !completionHandler ?: completionHandler(@{}, [NSError errorWithDomain:msg code:commonErrorCode userInfo:@{NSLocalizedDescriptionKey : msg}]);
        return;
    }
    NSString *url = [EMAAPI openChatIdsByChatIdsURL];
    EMANetworkCipher *cipher = [EMANetworkCipher cipher];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"appid": uniqueID.appID ?: @"",
        @"chats": chatItems,
        @"ttcode": cipher.encryptKey ?: @""
    }];
    BDPType appType = uniqueID.appType;
    NSString *sessionKey = @"session";
    if (appType == BDPTypeNativeApp) {
        sessionKey = @"minaSession";
    } else if(appType == BDPTypeWebApp) {
        sessionKey = @"h5Session";
    }
    [params addEntriesFromDictionary:@{sessionKey: session}];
    NSDictionary *header = sessionHeader;
    
    if ([OPECONetworkInterface enableECOWithPath:OPNetworkAPIPath.getOpenChatIDsByChatIDs]) {
        OpenECONetworkAppContext *networkContext = [[OpenECONetworkAppContext alloc] initWithTrace:tracing uniqueId:uniqueID source:ECONetworkRequestSourceApi];
        [OPECONetworkInterface postForOpenDomainWithUrl:url context:networkContext params:params header:header completionHandler:^(id _Nullable json, NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            handleResult(data, response, error, cipher);
        }];
    } else {
        [[EMANetworkManager shared] postUrl:url params:params header:header completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            handleResult(data, response, error, cipher);
        } eventName:@"getOpenChatIDsByChatIDs" requestTracing:tracing];
    }
}

+ (void)fetchOpenChatIDsByChatIDs:(nonnull NSArray<NSDictionary *> *)chatItems
                          sandbox:(nullable id<BDPSandboxProtocol> )sandbox
                        orContext:(nullable NSObject<BDPContextProtocol> *)context
                completionHandler:(nonnull void (^)(NSDictionary<NSString *, NSString *> *_Nullable openChatIdDict, NSError *_Nullable error))completionHandler {
    if((!sandbox && !context)) {
        BDPLogError(@"must contains at least one of sandbox or context")
        !completionHandler ?: completionHandler(@{}, [NSError errorWithDomain:@"UnkonwError"
                                                                         code:-9999
                                                                     userInfo:@{NSLocalizedDescriptionKey : @"UnkonwError"}]
                                                );
        return;
    }
    
    // 统一的错误吗，这里没有变更，只做一下注释
    NSInteger commonErrorCode = -9999;
    BDPUniqueID *uniqueID = context.engine.uniqueID ?: sandbox.uniqueID;
    
    void (^handleResult)(NSData * _Nullable data, NSError * _Nullable error, EMANetworkCipher *cipher, void (^completionHandler)(NSDictionary<NSString *, NSString *> *_Nullable openChatIdDict, NSError *_Nullable error)) = ^(NSData * _Nullable data, NSError * _Nullable error, EMANetworkCipher *cipher, void (^completionHandler)(NSDictionary<NSString *, NSString *> *_Nullable openChatIdDict, NSError *_Nullable error)) {
        OPMonitorEvent *monitor = BDPMonitorWithName(kEventName_mp_fetch_openchatid, uniqueID).timing();
        if (error) {
            monitor.kv(kEventKey_result_type, kEventValue_fail).setError(error).flush();
        } else {
            monitor.kv(kEventKey_result_type, kEventValue_success).timing().flush();
        }
        if (!completionHandler) {
            BDPLogError(@"completionHandler is nil")
            return;
        }
        if (!data || error) {
            BDPExecuteOnMainQueue(^{
                NSString *msg = @"invaild data";
                BDPLogError(@"%@ %@", msg, error.localizedDescription ?: @"")
                completionHandler(@{}, error ?: [NSError errorWithDomain:msg code:commonErrorCode userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }
        NSError *serializationError;
        NSDictionary *dict = [data JSONValueWithOptions:NSJSONReadingAllowFragments error:&serializationError];
        if (BDPIsEmptyDictionary(dict) || serializationError) {
            BDPExecuteOnMainQueue(^{
                NSString *msg = serializationError.localizedDescription ?: @"response dict is nil";
                BDPLogError(msg)
                completionHandler(@{}, serializationError ?: [NSError errorWithDomain:msg code:commonErrorCode userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }
        NSString *encryptedContent = [dict bdp_stringValueForKey:@"encryptedData"];
        NSDictionary<NSString *, NSString *> *openChatIDs;
        NSDictionary *decryptedDict = [EMANetworkCipher decryptDictForEncryptedContent:encryptedContent cipher:cipher];
        if ([decryptedDict isKindOfClass:[NSDictionary class]]) {
            openChatIDs = [decryptedDict bdp_dictionaryValueForKey:@"openchatids"];
        }
        if (![openChatIDs isKindOfClass:[NSDictionary class]]) {
            openChatIDs = nil;
        }
        BDPExecuteOnMainQueue(^{
            BDPLogInfo(@"completion %@", BDPParamStr(openChatIDs, error))
            completionHandler(openChatIDs, serializationError ?: error);
        });
    };
    
    
    OPTrace *tracing = [self generateRequestTracing:uniqueID];
    BDPLogInfo(@"uniqueID shoule not be nil, app=%@", uniqueID);
    if (BDPIsEmptyArray(chatItems)) {
        NSString *msg = @"chatItems is empty";
        BDPLogError(msg)
        !completionHandler ?: completionHandler(@{}, [NSError errorWithDomain:msg code:commonErrorCode userInfo:@{NSLocalizedDescriptionKey : msg}]);
        return;
    }
    NSString *url = [EMAAPI openChatIdsByChatIdsURL];
    EMANetworkCipher *cipher = [EMANetworkCipher cipher];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"appid": uniqueID.appID ?: @"",
        @"chats": chatItems,
        @"ttcode": cipher.encryptKey ?: @""
    }];
    [params addEntriesFromDictionary:[EMARequestUtil sessionWithSandbox:sandbox orContext:context]];
    NSDictionary *header = context ? [GadgetSessionFactory storageForPluginContext:context].sessionHeader : @{};
    
    if ([OPECONetworkInterface enableECOWithPath:OPNetworkAPIPath.getOpenChatIDsByChatIDs]) {
        OpenECONetworkAppContext *networkContext = [[OpenECONetworkAppContext alloc] initWithTrace:tracing uniqueId:uniqueID source:ECONetworkRequestSourceApi];
        [OPECONetworkInterface postForOpenDomainWithUrl:url context:networkContext params:params header:header completionHandler:^(id _Nullable json, NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            handleResult(data, error, cipher, completionHandler);
        }];
    } else {
        [[EMANetworkManager shared] postUrl:url params:params header:header completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            handleResult(data, error, cipher, completionHandler);
        } eventName:@"getOpenChatIDsByChatIDs" requestTracing:tracing];
    }
}

+ (void)fetchChatIDByOpenChatIDs:(NSArray<NSString *> *)openChatids
                        uniqueID:(nonnull BDPUniqueID *)uniqueID
                         sandbox:(nonnull id<BDPSandboxProtocol> )sandbox
                         tracing:(OPTrace * _Nullable)parentTracing
               completionHandler:(nonnull void (^)(NSDictionary<NSString *, NSString *>  * _Nonnull, NSError * _Nonnull))completionHandler {
    OPTrace *requestTracing = parentTracing ? (OPTrace *)[parentTracing subTrace] : [self generateRequestTracing:uniqueID];
    NSString *url = [EMAAPI chatIdByOpenChatIdURL];
    EMANetworkCipher *cipher = [EMANetworkCipher cipher];
    NSDictionary *params = @{
        @"appid": uniqueID.appID ?: @"",
        @"session": [[TMASessionManager sharedManager] getSession:sandbox] ?: @"",
        @"open_chatids": openChatids,
        @"ttcode": cipher.encryptKey ?: @""
    };
    NSDictionary *header = [self cookieHeader];
    [[EMANetworkManager shared] requestUrl:url method:@"POST" params:params header:header completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        OPMonitorEvent *monitor = [[OPMonitorEvent alloc] initWithService:nil name:kEventName_econetwork_request monitorCode:[ECONetworkMonitorCode request_will_response]];
        monitor.tracing(requestTracing);
        if (!completionHandler) {
            monitor.setResultTypeFail().setErrorMessage(@"completionHandler is nil").flush();
            BDPLogError(@"completionHandler is nil")
            return;
        }
        if (!data || error) {
            BDPExecuteOnMainQueue(^{
                NSString *msg = @"invaild data";
                BDPLogError(@"%@ %@", msg, error.localizedDescription ?: @"")
                NSError *callbackError = error ?: [NSError errorWithDomain:msg code:-9999 userInfo:@{NSLocalizedDescriptionKey : msg}];
                monitor.setResultTypeFail().setError(callbackError).flush();
                completionHandler(@{}, callbackError);
            });
            return;
        }
        NSError *serializationError;
        NSDictionary *dict = [data JSONValueWithOptions:NSJSONReadingAllowFragments error:&serializationError];
        if (BDPIsEmptyDictionary(dict) || serializationError) {
            BDPExecuteOnMainQueue(^{
                NSString *msg = serializationError.localizedDescription ?: @"response dict is nil";
                NSError *error = serializationError ?: [NSError errorWithDomain:msg code:-9999 userInfo:@{NSLocalizedDescriptionKey : msg}];
                BDPLogError(msg)
                monitor.setResultTypeFail().setError(error).flush();
                completionHandler(@{}, error);
            });
            return;
        }
        NSInteger responseCode = [dict bdp_integerValueForKey:@"code"]; // 业务出错时，会有code
        NSString *encryptedContent = [dict bdp_stringValueForKey:@"encryptedData"];
        NSDictionary<NSString *, NSString *> *chatDict;
        NSDictionary *decryptedDict = [EMANetworkCipher decryptDictForEncryptedContent:encryptedContent cipher:cipher];
        if ([decryptedDict isKindOfClass:[NSDictionary class]]) {
            chatDict = [decryptedDict bdp_dictionaryValueForKey:@"chatids"];
        }
        if (![chatDict isKindOfClass:[NSDictionary class]]) {
            chatDict = nil;
        }
        BDPExecuteOnMainQueue(^{
            BDPLogInfo(@"completion %@", BDPParamStr(chatDict, error, responseCode))
            monitor.setResultTypeSuccess().flush();
            completionHandler(chatDict, serializationError ?: error);
        });
    } eventName:@"getChatIDsByOpenChatIDs" requestTracing:requestTracing];
}

+ (void)fetchChatIDByOpenChatIDs:(nonnull NSArray<NSString *> *)openChatids
                         context:(nonnull NSObject<BDPContextProtocol> *)context
                         tracing:(OPTrace * _Nullable)parentTracing
               completionHandler:(nonnull void (^)(NSDictionary<NSString *, NSString *>  * _Nullable, NSError * _Nullable))completionHandler {
    BDPUniqueID *uniqueID = context.engine.uniqueID;
    OPTrace *requestTracing = parentTracing ? (OPTrace *)[parentTracing subTrace] : [self generateRequestTracing:uniqueID];
    BDPType appType = uniqueID.appType;
    BDPResolveModule(auth, BDPAuthModuleProtocol, context.engine.uniqueID.appType);
    NSString *session = [auth getSessionContext:context];
    // 统一的错误吗，这里没有变更，只做一下注释
    NSInteger commonErrorCode = -9999;
    NSString *url = [EMAAPI chatIdByOpenChatIdURL];
    EMANetworkCipher *cipher = [EMANetworkCipher cipher];
    NSString *sessionKey = @"session";
    if (appType == BDPTypeNativeApp) {
        sessionKey = @"minaSession";
    } else if(appType == BDPTypeWebApp) {
        sessionKey = @"h5Session";
    }
    NSDictionary *params = @{
        @"appid": uniqueID.appID ?: @"",
        sessionKey: session ?: @"",
        @"open_chatids": openChatids,
        @"ttcode": cipher.encryptKey ?: @""
    };
    NSMutableDictionary *header = [NSMutableDictionary dictionary];
    header[@"Cookie"] = [NSString stringWithFormat:@"sessionKey=%@", session];
    if(context) {
        [header addEntriesFromDictionary:[NSMutableDictionary dictionaryWithDictionary:[GadgetSessionFactory storageForPluginContext:context].sessionHeader]];
    }
    [[EMANetworkManager shared] postUrl:url params:params header:header completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        OPMonitorEvent *monitor = [[OPMonitorEvent alloc] initWithService:nil name:kEventName_econetwork_request monitorCode:[ECONetworkMonitorCode request_will_response]];
        monitor.tracing(requestTracing);
        if (!completionHandler) {
            BDPLogError(@"completionHandler is nil")
            monitor.setResultTypeFail().setErrorMessage(@"completionHandler is nil").flush();
            return;
        }

        if (!data || error) {
            BDPExecuteOnMainQueue(^{
                NSString *msg = @"invaild data";
                BDPLogError(@"%@ %@", msg, error.localizedDescription ?: @"")
                NSError *callbackError = error ?: [NSError errorWithDomain:msg code:commonErrorCode userInfo:@{NSLocalizedDescriptionKey : msg}];
                monitor.setResultTypeFail().setError(callbackError).flush();
                completionHandler(@{}, error);
            });
            return;
        }
        NSError *serializationError;
        NSDictionary *dict = [data JSONValueWithOptions:NSJSONReadingAllowFragments error:&serializationError];
        if (BDPIsEmptyDictionary(dict) || serializationError) {
            BDPExecuteOnMainQueue(^{
                NSString *msg = serializationError.localizedDescription ?: @"response dict is nil";
                NSError *error = serializationError ?: [NSError errorWithDomain:msg code:commonErrorCode userInfo:@{NSLocalizedDescriptionKey : msg}];
                BDPLogError(msg)
                monitor.setResultTypeFail().setError(error).flush();
                completionHandler(@{}, error);
            });
            return;
        }
        NSString *encryptedContent = [dict bdp_stringValueForKey:@"encryptedData"];
        NSDictionary<NSString *, NSString *> *chatDict;
        NSDictionary *decryptedDict = [EMANetworkCipher decryptDictForEncryptedContent:encryptedContent cipher:cipher];
        if ([decryptedDict isKindOfClass:[NSDictionary class]]) {
            chatDict = [decryptedDict bdp_dictionaryValueForKey:@"chatids"];
        }
        if (![chatDict isKindOfClass:[NSDictionary class]]) {
            chatDict = nil;
        }
        BDPExecuteOnMainQueue(^{
            BDPLogInfo(@"completion %@", BDPParamStr(chatDict, error))
            monitor.setResultTypeSuccess().flush();
            completionHandler(chatDict, serializationError ?: error);
        });
    } eventName:@"getChatIDsByOpenChatIDs" requestTracing:requestTracing];
}

+ (void)fetchEnvVariableByUniqueID:(BDPUniqueID *)uniqueID
                     completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    if (!completion) {
        BDPLogTagError(BDPTag.getEnvVariable, @"fetchEnvVariable completion is nil")
        return;
    }
    OPTrace *tracing = [self generateRequestTracing:uniqueID];
    NSString *url = [EMAAPI envConfigURL];
    NSString *session = [self userSession];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:10];
    params[@"appid"] = uniqueID.appID ?: @"";
    if (![EEFeatureGating boolValueForKey:@"openplatform.network.remove_larksession_from_req_body"]) {
        params[@"session"] = session;
    }
    NSDictionary *header = @{
        @"Cookie": [NSString stringWithFormat:@"session=%@", session]
    };

    void (^handleResult)(NSData * _Nullable data, NSError * _Nullable error) = ^(NSData * _Nullable data, NSError * _Nullable error) {
        // 判断是否请求失败
        if (!data || error) {
            NSString *msg = @"invaild data";
            BDPLogTagError(BDPTag.getEnvVariable, @"fetchEnvVariable error:%@ %@", msg, error.localizedDescription ?: @"")
            BDPExecuteOnMainQueue(^{
                completion(nil, error ?: [NSError errorWithDomain:EMARequestErrorDomain code:EMARequestFailed userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }
        // 判断是否转json失败
        NSError *serializationError;
        NSDictionary *dict = [data JSONValueWithOptions:NSJSONReadingAllowFragments error:&serializationError];
        if (BDPIsEmptyDictionary(dict) || serializationError) {
            NSString *msg = serializationError.localizedDescription ?: @"response dict is nil";
            BDPLogTagError(BDPTag.getEnvVariable, @"fetchEnvVariable error:%@", msg)
            BDPExecuteOnMainQueue(^{
                completion(nil, serializationError ?: [NSError errorWithDomain:EMARequestErrorDomain code:EMARequestJSONParseFailed userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }
        // 判断是否有请求业务错误
        NSInteger code = [dict bdp_integerValueForKey:@"code"];
        if (code != 0) {
            NSString *msg = [dict bdp_stringValueForKey:@"msg"] ?: @"response code %@";
            BDPLogTagError(BDPTag.getEnvVariable, @"fetchEnvVariable error:%@ code:%@", msg, @(code))
            BDPExecuteOnMainQueue(^{
                completion(nil, [NSError errorWithDomain:EMARequestErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: msg}]);
            });
            return;
        }
        // 成功回调
        NSDictionary *dataDict = [dict objectForKey:@"data"];
        NSDictionary *config = [dataDict bdp_dictionaryValueForKey:@"config"];
        BDPLogTagInfo(BDPTag.getEnvVariable, @"fetchEnvVariable success")
        BDPExecuteOnMainQueue(^{
            completion(config, nil);
        });
    };

    if ([OPECONetworkInterface enableECOWithPath:OPNetworkAPIPath.getEnvConfig]) {
        OpenECONetworkAppContext *context = [[OpenECONetworkAppContext alloc] initWithTrace:tracing
                                                                                   uniqueId:uniqueID
                                                                                     source:ECONetworkRequestSourceApi];
        [OPECONetworkInterface postForOpenDomainWithUrl:url
                                                context:context
                                                 params:params
                                                 header:header
                                      completionHandler:^(NSDictionary<NSString *,id> *json, NSData *data, NSURLResponse *response, NSError *error) {
            handleResult(data, error);
        }];
    } else {
        [[EMANetworkManager shared] requestUrl:url method:@"POST" params:params header:header completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            handleResult(data, error);
        } eventName:@"getEnvVariable" requestTracing:tracing];
    }
}

+ (void)requestLightServiceInvokeByAppID:(NSString *)appID
                                 context:(NSDictionary *)context
                              completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    if (!completion) {
        BDPLogTagError(BDPTag.getEnvVariable, @"requestLightServiceInvoke completion is nil")
        return;
    }
    NSString *url = [EMAAPI lightServiceInvokeURL];
    NSDictionary *header = [self cookieHeader];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (appID) {
        [params setObject:appID forKey:@"app_id"];
    }
    if (context) {
        [params setObject:context forKey:@"context"];
    }
    [[EMANetworkManager shared] requestUrl:url method:@"POST" params:params header:header completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!completion) {
            BDPLogError(@"requestLightServiceInvoke completion is nil")
            return;
        }
        if (!data || error) {
            BDPExecuteOnMainQueue(^{
                NSString *msg = @"invaild data";
                BDPLogError(@"requestLightServiceInvoke error %@ %@", msg, error.localizedDescription ?: @"")
                completion(@{}, error ?: [NSError errorWithDomain:msg code:EMARequestFailed userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }
        NSError *serializationError;
        NSDictionary *dict = [data JSONValueWithOptions:NSJSONReadingAllowFragments error:&serializationError];
        if (BDPIsEmptyDictionary(dict) || serializationError) {
            BDPExecuteOnMainQueue(^{
                NSString *msg = serializationError.localizedDescription ?: @"response dict is nil";
                BDPLogError(@"requestLightServiceInvoke error %@", msg)
                completion(@{}, serializationError ?: [NSError errorWithDomain:msg code:EMARequestFailed userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }

        BDPExecuteOnMainQueue(^{
            completion(dict, serializationError ?: error);
        });
    } eventName:@"requestLightServiceInvoke" requestTracing:nil];
}

+ (void)fetchTenantAppScopesByUniqueID:(BDPUniqueID *)uniqueID
                            completion:(void (^)(NSDictionary * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completion {
    if (!completion) {
        BDPLogTagError(BDPTag.getEnvVariable, @"fetchTenantAppScopes completion is nil")
        return;
    }
    OPTrace *tracing = [self generateRequestTracing:uniqueID];
    NSString *url = [EMAAPI getTenantAppScopesURL];
    NSString *appVersion = [[NSBundle mainBundle].infoDictionary bdp_stringValueForKey:@"CFBundleShortVersionString"];
    NSString *language = BDPLanguageHelper.appLanguage;

    NSDictionary *params = @{
        @"AppID": uniqueID.appID ?: @"",
        @"LarkVersion": appVersion ?: @"",
        @"Lang" : language ?: @"language"
    };
    NSDictionary *header = [self cookieHeader];

    void (^handleResult)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // 判断是否请求失败
        if (!data || error) {
            NSString *msg = @"invaild data";
            BDPLogTagError(BDPTag.getEnvVariable, @"fetchTenantAppScopes error:%@ %@", msg, error.localizedDescription ?: @"")
            BDPExecuteOnMainQueue(^{
                completion(nil, response, error ?: [NSError errorWithDomain:EMARequestErrorDomain code:EMARequestFailed userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }
        // 判断是否转json失败
        NSError *serializationError;
        NSDictionary *dict = [data JSONValueWithOptions:NSJSONReadingAllowFragments error:&serializationError];
        if (BDPIsEmptyDictionary(dict) || serializationError) {
            NSString *msg = serializationError.localizedDescription ?: @"response dict is nil";
            BDPLogTagError(BDPTag.getEnvVariable, @"fetchTenantAppScopes error:%@", msg)
            BDPExecuteOnMainQueue(^{
                completion(nil, response, serializationError ?: [NSError errorWithDomain:EMARequestErrorDomain code:EMARequestJSONParseFailed userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }

        // 成功回调
        BDPLogTagInfo(BDPTag.getEnvVariable, @"fetchTenantAppScopes success")
        BDPExecuteOnMainQueue(^{
            completion(dict, response, nil);
        });
    };

    if ([OPECONetworkInterface enableECOWithPath:OPNetworkAPIPath.getTenantAppScopes]) {
        OpenECONetworkAppContext *context = [[OpenECONetworkAppContext alloc] initWithTrace:tracing
                                                                                   uniqueId:uniqueID
                                                                                     source:ECONetworkRequestSourceApi];
        [OPECONetworkInterface postForOpenDomainWithUrl:url
                                                context:context
                                                 params:params
                                                 header:header
                                      completionHandler:^(NSDictionary<NSString *,id> *json, NSData *data, NSURLResponse *response, NSError *error) {
            handleResult(data, response, error);
        }];
    } else {
        [[EMANetworkManager shared] requestUrl:url method:@"POST" params:params header:header completionHandler:handleResult eventName:@"fetchTenantAppScopes" requestTracing:tracing];
    }
}

+ (void)fetchApplyAppScopeStatusByUniqueID:(BDPUniqueID *)uniqueID
                                completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    if (!completion) {
        BDPLogTagError(BDPTag.getEnvVariable, @"fetchTenantAppScopes completion is nil")
        return;
    }
    OPTrace *tracing = [self generateRequestTracing:uniqueID];
    NSString *url = [EMAAPI applyAppScopeStatusURL];
    NSString *appVersion = [[NSBundle mainBundle].infoDictionary bdp_stringValueForKey:@"CFBundleShortVersionString"];
    NSString *language = BDPLanguageHelper.appLanguage;

    NSDictionary *params = @{
        @"AppID": uniqueID.appID ?: @"",
        @"LarkVersion": appVersion ?: @"",
        @"Lang" : language ?: @"language"
    };
    NSDictionary *header = [self cookieHeader];

    void (^handleResult)(NSData * _Nullable data, NSError * _Nullable error) = ^(NSData * _Nullable data, NSError * _Nullable error) {
        // 判断是否请求失败
        if (!data || error) {
            NSString *msg = @"invaild data";
            BDPLogTagError(BDPTag.getEnvVariable, @"fetchTenantAppScopes error:%@ %@", msg, error.localizedDescription ?: @"")
            BDPExecuteOnMainQueue(^{
                completion(nil, error ?: [NSError errorWithDomain:EMARequestErrorDomain code:EMARequestFailed userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }
        // 判断是否转json失败
        NSError *serializationError;
        NSDictionary *dict = [data JSONValueWithOptions:NSJSONReadingAllowFragments error:&serializationError];
        if (BDPIsEmptyDictionary(dict) || serializationError) {
            NSString *msg = serializationError.localizedDescription ?: @"response dict is nil";
            BDPLogTagError(BDPTag.getEnvVariable, @"fetchTenantAppScopes error:%@", msg)
            BDPExecuteOnMainQueue(^{
                completion(nil, serializationError ?: [NSError errorWithDomain:EMARequestErrorDomain code:EMARequestJSONParseFailed userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }

        // 成功回调
        BDPLogTagInfo(BDPTag.getEnvVariable, @"fetchTenantAppScopes success")
        BDPExecuteOnMainQueue(^{
            completion(dict, nil);
        });
    };

    if ([OPECONetworkInterface enableECOWithPath:OPNetworkAPIPath.applyAppScopeStatus]) {
        OpenECONetworkAppContext *context = [[OpenECONetworkAppContext alloc] initWithTrace:tracing
                                                                                   uniqueId:uniqueID
                                                                                     source:ECONetworkRequestSourceApi];
        [OPECONetworkInterface postForOpenDomainWithUrl:url
                                                context:context
                                                 params:params
                                                 header:header
                                      completionHandler:^(NSDictionary<NSString *,id> *json, NSData *data, NSURLResponse *response, NSError *error) {
            handleResult(data, error);
        }];
    } else {
        [[EMANetworkManager shared] requestUrl:url method:@"POST" params:params header:header completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            handleResult(data, error);
        } eventName:@"fetchApplyAppScopeStatus" requestTracing:tracing];
    }
}

+ (void)requestApplyAppScopeByUniqueID:(BDPUniqueID *)uniqueID
                            completion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion {
    if (!completion) {
        BDPLogTagError(BDPTag.getEnvVariable, @"fetchTenantAppScopes completion is nil")
        return;
    }
    OPTrace *tracing = [self generateRequestTracing:uniqueID];
    NSString *url = [EMAAPI applyAppScopeURL];
    NSString *appVersion = [[NSBundle mainBundle].infoDictionary bdp_stringValueForKey:@"CFBundleShortVersionString"];
    NSString *language = BDPLanguageHelper.appLanguage;

    NSDictionary *params = @{
        @"AppID": uniqueID.appID ?: @"",
        @"LarkVersion": appVersion ?: @"",
        @"Lang" : language ?: @"language"
    };
    NSDictionary *header = [self cookieHeader];

    void (^handleResult)(NSData * _Nullable data, NSError * _Nullable error) = ^(NSData * _Nullable data, NSError * _Nullable error) {
        // 判断是否请求失败
        if (!data || error) {
            NSString *msg = @"invaild data";
            BDPLogTagError(BDPTag.getEnvVariable, @"fetchTenantAppScopes error:%@ %@", msg, error.localizedDescription ?: @"")
            BDPExecuteOnMainQueue(^{
                completion(nil, error ?: [NSError errorWithDomain:EMARequestErrorDomain code:EMARequestFailed userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }
        // 判断是否转json失败
        NSError *serializationError;
        NSDictionary *dict = [data JSONValueWithOptions:NSJSONReadingAllowFragments error:&serializationError];
        if (BDPIsEmptyDictionary(dict) || serializationError) {
            NSString *msg = serializationError.localizedDescription ?: @"response dict is nil";
            BDPLogTagError(BDPTag.getEnvVariable, @"fetchTenantAppScopes error:%@", msg)
            BDPExecuteOnMainQueue(^{
                completion(nil, serializationError ?: [NSError errorWithDomain:EMARequestErrorDomain code:EMARequestJSONParseFailed userInfo:@{NSLocalizedDescriptionKey : msg}]);
            });
            return;
        }

        // 成功回调
        BDPLogTagInfo(BDPTag.getEnvVariable, @"fetchTenantAppScopes success")
        BDPExecuteOnMainQueue(^{
            completion(dict, nil);
        });
    };

    if ([OPECONetworkInterface enableECOWithPath:OPNetworkAPIPath.applyAppScope]) {
        OpenECONetworkAppContext *context = [[OpenECONetworkAppContext alloc] initWithTrace:tracing
                                                                                   uniqueId:uniqueID
                                                                                     source:ECONetworkRequestSourceApi];
        [OPECONetworkInterface postForOpenDomainWithUrl:url
                                                context:context
                                                 params:params
                                                 header:header
                                      completionHandler:^(NSDictionary<NSString *,id> *json, NSData *data, NSURLResponse *response, NSError *error) {
            handleResult(data, error);
        }];
    } else {
        [[EMANetworkManager shared] requestUrl:url method:@"POST" params:params header:header completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            handleResult(data, error);
        } eventName:@"requestApplyAppScope" requestTracing:tracing];
    }
}

+ (NSDictionary *)sessionWithSandbox:(id<BDPSandboxProtocol> )sandbox orContext:(nonnull NSObject<BDPContextProtocol> *)context{
    if((!sandbox && !context)) { BDPLogError(@"invalid params, at least one of sandbox or context") }
    BDPUniqueID *uniqueID = context.engine.uniqueID ?: sandbox.uniqueID;
    BDPType appType = uniqueID.appType;
    NSString *sessionKey = @"session";
    if (appType == BDPTypeNativeApp) {
        sessionKey = @"minaSession";
    } else if(appType == BDPTypeWebApp) {
        sessionKey = @"h5Session";
    }
    
    if(context) {
        BDPResolveModule(auth, BDPAuthModuleProtocol, context.engine.uniqueID.appType);
        NSString *session = [auth getSessionContext:context];
        return @{sessionKey: session};
    } else if(sandbox){
        return @{sessionKey: [[TMASessionManager sharedManager] getSession:sandbox] ?: @""};
    }
    return nil;
}

+ (BDPTracing *)generateRequestTracing:(BDPUniqueID *)uniqueID {
    BDPTracing *parentTracing = [BDPTracingManager.sharedInstance getTracingByUniqueID:uniqueID];
    BDPTracing *tracing = [BDPTracingManager.sharedInstance generateTracingWithParent:parentTracing];
    // TODO: 确认这里选用 appID 改为使用 uniqueID.fullString 是否更好
    [tracing genRequestID:uniqueID.appID];
    return tracing;
}

#pragma mark - Private

+ (NSDictionary * _Nonnull)cookieHeader {
    NSString *session = [self userSession];
    if (!BDPIsEmptyString(session)) {
        return @{
            @"Cookie": [NSString stringWithFormat:@"session=%@", session]
        };
    } else {
        return @{};
    }
}

+ (NSString * _Nullable)userSession {
    BDPPlugin(appEnginePlugin, EMAAppEnginePluginDelegate);
    return appEnginePlugin.account.userSession;
}

@end
