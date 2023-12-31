//
//  BDDebugFeedTwiceVerify.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/11/5.
//

#import "BDDebugFeedTwiceVerify.h"
#import "BDDebugFeedTuring.h"
#import "BDTuringConfig.h"
#import "BDTuring.h"
#import "BDTNetworkManager.h"
#import "NSData+BDTuring.h"
#import "NSDictionary+BDTuring.h"
#import "NSString+BDTuring.h"
#import "BDTuringUtility.h"
#import "BDTwiceVerifyViewController.h"
#import "BDTwiceVerifyH5ViewController.h"
#import "BDTuringStartUpTask.h"
#import "BDTuringTwiceVerify.h"
#import "BDTuringMacro.h"
#import "BDTuringConfig.h"
#import "BDTuringIndicatorView.h"
#import "BDTNetworkManager.h"
#import "BDTuringTVViewController.h"
#import "BDTuringConfig+Parameters.h"
#import "BDTuringSandBoxHelper.h"

#import <WebKit/WebKit.h>

#import <TTBridgeUnify/TTWebViewBridgeEngine.h>
#import <TTBridgeUnify/TTBridgeAuthManager.h>
#import <TTBridgeUnify/BDUnifiedWebViewBridgeEngine.h>
#import <TTBridgeUnify/TTBridgeRegister.h>


#import <BDDebugTool/BDDebugFeedModel.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTBridgeUnify/TTBridgeAuthManager.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTAccountSDK/TTAccountSDK.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <TTReachability/TTReachability+Conveniences.h>

static NSString * const kTTAppNetworkRequestTypeFlag = @"TT-RequestType";


@interface BDDebugFeedTwiceVerify()

+ (NSArray<BDDebugSectionModel *> *)feeds;

@end

BDAppAddDebugFeedFunction() {
    [BDDebugFeedTuring sharedInstance].twiceVerifyFeed = [BDDebugFeedTwiceVerify feeds];
}

@implementation BDDebugFeedTwiceVerify

+ (NSArray<BDDebugSectionModel *> *)feeds {
    NSMutableArray<BDDebugSectionModel *> *sections = [NSMutableArray new];
    
    NSString *appID = [BDTuringStartUpTask sharedInstance].config.appID;
    BDTuringTwiceVerify *tvVerify = [BDTuringTwiceVerify twiceVerifyWithConfig:[BDTuringStartUpTask sharedInstance].config];
    tvVerify.url = @"https://i.snssdk.com/verifycenter/authentication";
    [TTBridgeAuthManager sharedManager].authEnabled = NO;
    [self setupTTNetWithAppID:appID];
    [self setupTTAccountWithAppID:appID];
    [self registerGlobalTwiceVerifyBridge];
    
    [sections addObject:({
        BDDebugSectionModel *model = [BDDebugSectionModel new];
        model.title = @"passport融合测试";
        NSMutableArray<BDDebugFeedModel *> *feeds = [NSMutableArray new];
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
            model.title = @"加载两步验证页面";
            model.navigateBlock = ^(BDDebugFeedModel * _Nonnull feed, UINavigationController * _Nonnull navigate) {
                BDTwiceVerifyViewController *vc = [BDTwiceVerifyViewController new];
                [navigate pushViewController:vc animated:YES];
            };
            model;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
            model.title = @"身份验证h5测试页面";
            model.navigateBlock = ^(BDDebugFeedModel * _Nonnull feed, UINavigationController * _Nonnull navigate) {
                BDTwiceVerifyH5ViewController *vc = [BDTwiceVerifyH5ViewController new];
                [navigate pushViewController:vc animated:YES];
            };
            model;
        })];

        model.feeds = feeds;
        model;
    })];
    
    return sections;
}


+ (void)setupTTNetWithAppID:(NSString *)appID {
    
//    [[TTNetworkManager shareInstance] addRequestFilterBlock:^(TTHttpRequest *request) {
//        [request setValue:@"1" forHTTPHeaderField:@"x-use-ppe"];
//        [request setValue:@"ppe_zby_goapi_v4" forHTTPHeaderField:@"x-tt-env"];
//    }];
    [TTNetworkManager setLibraryImpl:TTNetworkManagerImplTypeLibChromium];
    
    [TTNetworkManager shareInstance].ServerConfigHostFirst = @"dm.toutiao.com";
    [TTNetworkManager shareInstance].ServerConfigHostSecond = @"dm.bytedance.com";
    [TTNetworkManager shareInstance].ServerConfigHostThird = @"dm-hl.toutiao.com";
    
    
    [[TTNetworkManager shareInstance] setCommonParamsblock:^NSDictionary<NSString *,NSString *> *{
        return @{@"aid" : appID, @"app_id" : appID};
    }];
    
    [[TTNetworkManager shareInstance] start];
    
    [[TTNetworkManager shareInstance] setServerConfigHostFirst:@"dm.toutiao.com"];
    
    [[TTNetworkManager shareInstance] setDomainHttpDns:@"dig.bdurl.net"];
    [[TTNetworkManager shareInstance] setDomainNetlog:@"crash.snssdk.com"];
    
//    [[TTNetworkManager shareInstance] setProxy:@"http://rc-boe.snssdk.com"]; // test boe
    
}


+ (void)setupTTAccountWithAppID:(NSString *)appID {
//    [TTAccount registerOneKeyLoginService:TTAccountUnion appId:@"99166000000000000371" appKey:@"bf4ca042fafec19a84737211d6f80e49" isTestChannel:NO];
    [TTAccount accountConf].domain = @"https://security.snssdk.com"; // @"security.snssdk.com";
    // Required
    [TTAccount accountConf].networkParamsHandler = ^NSDictionary *() {
        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:2];
        NSString *idfa = @"88AC8B5D-434A-4013-A633-EDF90EF40903";
        NSString *idfv = @"961CF8F0-AA1F-4FC7-81DB-FCE94C299028";
        [result setValue:[BDTrackerProtocol installID] forKey:@"iid"];
        [result setValue:[TTReachability currentConnectionMethodName] forKey:@"ac"];
        [result setValue:@"local_test" forKey:@"channel"];
        NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString* app_name = [infoDict objectForKey:@"AppName"];
        [result setValue:app_name forKey:@"app_name"];
        [result setValue:appID forKey:@"aid"];
        [result setValue:@"11.9.0" forKey:@"version_code"];
        [result setValue:@"11.9.0" forKey:@"update_version_code"];
        [result setValue:@"iphone" forKey:@"device_platform"];
        [result setValue:[[UIDevice currentDevice] systemVersion] forKey:@"os_version"];
        [result setValue:@"iPhone10,3" forKey:@"device_type"];
        [result setValue:idfv forKey:@"vid"];
        [result setValue:[BDTrackerProtocol deviceID]  forKey:@"device_id"];
        [result setValue:@"35d2a60e3f4f5199d25c8e788d49ed9002d08754" forKey:@"openudid"];
        [result setValue:idfa forKey:@"idfa"];
        [result setValue:idfv forKey:@"idfv"];
        [result setValue:appID forKey:@"app_id"];
        return result;
    };
    [TTAccount accountConf].appRequiredParamsHandler = ^NSDictionary * _Nullable{
        NSMutableDictionary *requiredDict = [NSMutableDictionary dictionaryWithCapacity:3];
        [requiredDict setValue:appID forKey:TTAccountSSAppIdKey];
        return requiredDict;
    };
    [TTAccount accountConf].isSupportMutilLogin = YES;
    //    [TTAccount accountConf].domain = @"http://boe.i.snsdk.com/";

    // Optional (Important)
    [TTAccount accountConf].multiThreadSafeEnabled = arc4random()%2;

    // Optional (Not Important)
    [TTAccount accountConf].visibleViewControllerHandler = ^UIViewController *() {
        return nil;
    };
    [TTAccount accountConf].isXTTTokenActive = YES;
    [TTAccount accountConf].byFindPasswordLoginEnabled = YES;
    [TTAccount accountConf].unbindAlertEnabled = YES;
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@"111",@"222",nil];
    NSDictionary *dic2 = [NSDictionary dictionaryWithObjectsAndKeys:dic,@"sdk_key_accountSDK",nil];
    [[TTAccount sharedAccount] updateSettings:dic2];
    [TTAccount accountConf].openCacheLoginInfo = YES;
    [[TTAccount sharedAccount] setMultiSids:nil];
    [TTAccount setIsLocalTest:YES];
}


+ (void)registerGlobalTwiceVerifyBridge {
    [self registerAppinfo];
    [self registerClose];
    [self registerFetch];
    [self registerToast];
    [self registerShowLoading];
    [self registerDismissLoading];
    [self registerIsSmsAvailable];
    [self registerCopy];
}


+ (void)registerAppinfo {
    [[TTBridgeRegister sharedRegister] registerBridge:^(TTBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(@"appInfo").authType(TTBridgeAuthProtected).engineType(TTBridgeRegisterWebView).handler(^(NSDictionary * _Nullable params, TTBridgeCallback  _Nonnull callback, id<TTBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            BDTuringConfig *config = [BDTuringStartUpTask sharedInstance].config;
            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            [data setValue:config.appName forKey:@"appName"];
            [data setValue:config.appID forKey:@"aid"];
            [data setValue:[config stringFromDelegateSelector:@selector(userID)] forKey:@"user_id"];
            [data setValue:config.appName forKey:@"innerAppName"];
            [data setValue:[BDTuringSandBoxHelper appVersion] forKey:@"appVersion"];
            [data setValue:[BDTNetworkManager networkType] forKey:@"netType"];
            
            [data setValue:[config stringFromDelegateSelector:@selector(deviceID)] forKey:@"device_id"]; //did
            [data setValue:[config stringFromDelegateSelector:@selector(installID)] forKey:@"install_id"]; //iid
            
            [data setValue:@(1) forKey:@"code"];
            callback(TTBridgeMsgSuccess, data, nil);
        });
    }];
}

+ (void)registerFetch {
    [[TTBridgeRegister sharedRegister] registerBridge:^(TTBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(@"fetch").authType(TTBridgeAuthProtected).engineType(TTBridgeRegisterWebView).handler(^(NSDictionary * _Nullable params, TTBridgeCallback  _Nonnull callback, id<TTBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            NSString *url = [params valueForKey:@"url"];
            if (!BDTuring_isValidString(url)) {
                TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"url cannot be empty");
                return;
            }
            
            NSString *methodObj = [params valueForKey:@"method"];
            NSString *method;
            if (!BDTuring_isValidString(methodObj)) {
                method = @"GET";
            } else {
                method = methodObj.uppercaseString;
            }
            NSNumber *needCommonParamsNum = [params valueForKey:@"needCommonParams"];
            BOOL needCommonParams = YES;
            if ([needCommonParamsNum isKindOfClass:[NSNumber class]] || [needCommonParamsNum isKindOfClass:[NSString class]]) {
                needCommonParams = [needCommonParamsNum boolValue];
            }
            BOOL postRequest = [method isEqualToString:@"POST"];
            
            id reqParams = [params objectForKey:postRequest ? @"data" : @"params"];
            NSDictionary *headerDic = [params valueForKey:@"header"];
            NSMutableDictionary *header = [NSMutableDictionary new];
            if ([headerDic isKindOfClass:[NSDictionary class]]) {
                [header addEntriesFromDictionary:headerDic];
            }
            
            /*
             requestType：只对POST有效，默认为"form"
             "form"：data必须是json，转成a=b&c=d的格式放到body中
             "json"：data必须是json，原格式放到body中
             "raw"：data必须是string或binary，原格式放到body中
             */
            if (postRequest) {
                NSString *requestType = [params valueForKey:@"requestType"];
                if (!BDTuring_isValidString(requestType)) {
                    requestType = @"form";
                }
                
                // 增加类型标记
                header[kTTAppNetworkRequestTypeFlag] = requestType;
                
                if ([requestType isEqualToString:@"json"] || [requestType isEqualToString:@"form"]) {
                    if ([reqParams isKindOfClass:[NSString class]]) {// JSON字符串需要转换
                        NSString *paramString = reqParams;
                        NSData *data = [paramString dataUsingEncoding:NSUTF8StringEncoding];
                        if (data) {
                            NSError *error = nil;
                            id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                            if (!error) {
                                reqParams = object;
                            }
                        }
                    }
                    
                    if (reqParams && ![reqParams isKindOfClass:[NSDictionary class]]) {
                        TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"data must be of type json");
                        return;
                    }
                    
                    if ([requestType isEqualToString:@"json"] && ![header objectForKey:@"Content-Type"]) {
                        header[@"Content-Type"] = @"application/json";
                    }
                } else {
                    if (reqParams && ![reqParams isKindOfClass:[NSString class]] && ![reqParams isKindOfClass:[NSData class]]) {
                        TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"data must be of type string or binary");
                        return;
                    }
                }
            }
            
            NSString *startTime = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];
            
            BDTuringTwiceVerifyNetworkFinishBlock finishBlock = ^(NSError *error, NSData *data, NSInteger statusCode) {
                if (callback) {
                    NSMutableDictionary *param = [NSMutableDictionary dictionary];
                    NSData *jsonData = nil;
                    if (data) {
                        jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
                    }
                    NSString *objStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    param[@"response"] = objStr ?: @"";
                    param[@"status"] = @(statusCode);
                    param[@"code"] = error ? @(0) : @(1);
                    param[@"beginReqNetTime"] = startTime;
                    if (error) {
                        NSInteger errCode = error.code;// 需要先取再传，否则前端收到的数值会不一致
                        param[@"error_code"] = @(errCode);
                    }
                    callback(error ? TTBridgeMsgFailed : TTBridgeMsgSuccess, param, nil);
                }
            };

            [BDTNetworkManager tvRequestForJSONWithResponse:url
                                                     params:reqParams
                                                     method:method
                                           needCommonParams:NO
                                                headerField:header
                                                   callback:finishBlock
                                                    tagType:BDTNetworkTagTypeManual];
        });
    }];
}

+ (void)registerClose {
    __weak typeof(self) weakSelf = self;
    [[TTBridgeRegister sharedRegister] registerBridge:^(TTBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(@"close").authType(TTBridgeAuthProtected).engineType(TTBridgeRegisterWebView).handler(^(NSDictionary * _Nullable params, TTBridgeCallback  _Nonnull callback, id<TTBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            __strong __typeof(weakSelf)self = weakSelf;
            NSNumber *number = [params objectForKey:@"status_code"]; // 0成功  1验证失败 2用户手动关闭
            NSError *webError = nil;
            if (number && [number respondsToSelector:@selector(integerValue)] && [number integerValue] == 0) { // success
                
            } else { // failure
                webError = [self createErrorWithErrorCode:kBDTuringTVErrorCodeTypeWebFailure errorMsg:@"error from close jsb"];
            }
            
            [self dismissController:controller WithParams:params error:webError];
            
            callback(TTBridgeMsgSuccess, nil, nil);
        });
    }];
}

// 展示toast
+ (void)registerToast {
    __weak typeof(self) weakSelf = self;
    [[TTBridgeRegister sharedRegister] registerBridge:^(TTBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(@"toast").authType(TTBridgeAuthProtected).engineType(TTBridgeRegisterWebView).handler(^(NSDictionary * _Nullable params, TTBridgeCallback  _Nonnull callback, id<TTBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            NSString *textStr = [params valueForKey:@"text"];
            [BDTuringIndicatorView showIndicatorForTextMessage:textStr];
        });
    }];
}

// show loading
+ (void)registerShowLoading {
    __weak typeof(self) weakSelf = self;
    [[TTBridgeRegister sharedRegister] registerBridge:^(TTBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(@"showLoading").authType(TTBridgeAuthProtected).engineType(TTBridgeRegisterWebView).handler(^(NSDictionary * _Nullable params, TTBridgeCallback  _Nonnull callback, id<TTBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            NSString *textStr = [params valueForKey:@"text"];
            [BDTuringIndicatorView showIndicatorForTextMessage:textStr];
        });
    }];
}

// dismiss loading
+ (void)registerDismissLoading {
    __weak typeof(self) weakSelf = self;
    [[TTBridgeRegister sharedRegister] registerBridge:^(TTBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(@"hideLoading").authType(TTBridgeAuthProtected).engineType(TTBridgeRegisterWebView).handler(^(NSDictionary * _Nullable params, TTBridgeCallback  _Nonnull callback, id<TTBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            __strong __typeof(weakSelf)self = weakSelf;
            [BDTuringIndicatorView dismissIndicators];
        });
    }];
}

// 是否可以打开短信功能
+ (void)registerIsSmsAvailable {
    [[TTBridgeRegister sharedRegister] registerBridge:^(TTBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(@"isSmsAvailable").authType(TTBridgeAuthProtected).engineType(TTBridgeRegisterWebView).handler(^(NSDictionary * _Nullable params, TTBridgeCallback  _Nonnull callback, id<TTBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            
            TTBridgeMsg msg = [BDTuringTVViewController canSendText] ? TTBridgeMsgSuccess : TTBridgeMsgFailed;
            callback(msg, nil, nil);
        });
    }];
}

+ (void)registerCopy {
    [[TTBridgeRegister sharedRegister] registerBridge:^(TTBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(@"copy").authType(TTBridgeAuthProtected).engineType(TTBridgeRegisterWebView).handler(^(NSDictionary * _Nullable params, TTBridgeCallback  _Nonnull callback, id<TTBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            callback(TTBridgeMsgFailed, nil, nil);
        });
    }];
}


+ (NSError *)createErrorWithErrorCode:(NSInteger)errorCode errorMsg:(NSString *)errorMsg {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMsg };
    NSError *error = [NSError errorWithDomain:kBDTuringTVErrorDomain code:errorCode userInfo:userInfo];
    return error;
}

+ (void)dismissController:(UIViewController *)vc WithParams:(NSDictionary *)parmas error:(NSError *)error {
    [vc dismissViewControllerAnimated:YES completion:nil];
}


@end

