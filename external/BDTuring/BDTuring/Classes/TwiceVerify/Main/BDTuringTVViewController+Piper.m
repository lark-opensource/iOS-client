//
//  BDTuringTVViewController+Piper.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/12/8.
//

#import "BDTuringTVViewController.h"
#import "BDTuringTVHelper.h"
#import "BDTuringTVDefine.h"
#import "BDTuringTVTracker.h"
#import "BDTuringTVViewController+Piper.h"
#import "BDTuringTVViewController+Utility.h"
#import "BDTuringMacro.h"
#import "BDTuringCoreConstant.h"
#import "NSDictionary+BDTuring.h"
#import "BDTuringConfig+Parameters.h"
#import "BDTuringTVHelper.h"
#import "BDTuringIndicatorView.h"
#import "BDTNetworkManager.h"
#import "BDTuringSandBoxHelper.h"
#import "WKWebView+Piper.h"
#import "BDTuringPiper.h"
#import "BDTuringUtility.h"

static NSString * const kTTAppNetworkRequestTypeFlag = @"TT-RequestType";

@implementation BDTuringTVViewController (Piper)

- (void)registerFetch {
    BDTuringPiper *piper = self.webView.turing_piper;
    BDTuringWeakSelf;
    [piper on:@"second_verify.fetch" callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
            BDTuringStrongSelf;
            NSString *url = [params valueForKey:@"url"];
            if (!BDTuring_isValidString(url)) {
                callback(BDTuringPiperMsgFailed,@{@"msg": @"url cannot be empty"});
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
                        callback(BDTuringPiperMsgFailed,@{@"msg":  @"data must be of type json"});
                        return;
                    }
                    
                    if ([requestType isEqualToString:@"json"] && ![header objectForKey:@"Content-Type"]) {
                        header[@"Content-Type"] = @"application/json";
                        header[kTTAppNetworkRequestTypeFlag] = nil;
                    }
                } else {
                    if (reqParams && ![reqParams isKindOfClass:[NSString class]] && ![reqParams isKindOfClass:[NSData class]]) {
                        callback(BDTuringPiperMsgFailed,@{@"msg":  @"data must be of type string or binary"});
                        return;
                    }
                }
            }
            
            NSString *startTime = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];
            NSDictionary *jsbCommonParams = [params objectForKey:@"params"];
            if (needCommonParams || ([jsbCommonParams isKindOfClass:[NSDictionary class]] && [jsbCommonParams count] > 0)) {
                NSMutableDictionary *mutParamsDict = [NSMutableDictionary dictionary];
                if (needCommonParams) {
                    NSMutableDictionary *commonParams = [self.config twiceVerifyRequestQueryParameters];
                    if (commonParams && [commonParams count] > 0) {
                        [mutParamsDict addEntriesFromDictionary:commonParams];
                    }
                }
                
                if ([jsbCommonParams isKindOfClass:[NSDictionary class]] && [jsbCommonParams count] > 0) {
                    [mutParamsDict addEntriesFromDictionary:jsbCommonParams];
                }
                url = [url bdturing_URLStringByAppendQueryItems:mutParamsDict];
            }
            
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
                    callback(error ? BDTuringPiperMsgFailed : BDTuringPiperMsgSuccess, param);
                }
            };
            
            [BDTNetworkManager tvRequestForJSONWithResponse:url
                                                     params:reqParams
                                                     method:method
                                           needCommonParams:needCommonParams
                                                headerField:header
                                                   callback:finishBlock
                                                    tagType:BDTNetworkTagTypeManual];
    }];
}

- (void)registerClose {
    BDTuringPiper *piper = self.webView.turing_piper;
    BDTuringWeakSelf;
    [piper on:@"second_verify.close" callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
            BDTuringStrongSelf;
            NSNumber *number = [params objectForKey:@"status_code"]; // 0 success  1 failed 2 closed
            NSError *webError = nil;
            if (number && [number respondsToSelector:@selector(integerValue)] && [number integerValue] == 0) { // success
                [BDTuringTVTracker trackerTwiceVerifySubmitWithScene:self.scene type:self.blockType aid:self.config.appID result:YES];
            } else { // failure
                [BDTuringTVTracker trackerTwiceVerifySubmitWithScene:self.scene type:self.blockType aid:self.config.appID result:NO];
                webError = [self createErrorWithErrorCode:kBDTuringTVErrorCodeTypeWebFailure errorMsg:@"error from close jsb"];
            }
            
            [self dismissSelfControllerWithParams:params error:webError];
            
            callback(BDTuringPiperMsgSuccess, nil);
    }];
}

- (void)registerToast {
    BDTuringPiper *piper = self.webView.turing_piper;
    [piper on:@"second_verify.toast" callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        NSString *textStr = [params valueForKey:@"text"];
        [BDTuringIndicatorView showIndicatorForTextMessage:textStr];
    }];
}

- (void)registerShowLoading {
    BDTuringPiper *piper = self.webView.turing_piper;
    [piper on:@"second_verify.showLoading" callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        NSString *textStr = [params valueForKey:@"text"];
        [BDTuringIndicatorView showIndicatorForTextMessage:textStr];
    }];
}

- (void)registerDismissLoading {
    BDTuringPiper *piper = self.webView.turing_piper;
    [piper on:@"second_verify.hideLoading" callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        [BDTuringIndicatorView dismissIndicators];
    }];
}


- (void)registerIsSmsAvailable {
    BDTuringPiper *piper = self.webView.turing_piper;
    [piper on:@"second_verify.isSmsAvailable" callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        BDTuringPiperMsg msg = [BDTuringTVViewController canSendText] ? BDTuringPiperMsgSuccess : BDTuringPiperMsgFailed;
        callback(msg, nil);
    }];
}

- (void)registerOpenSms {
    BDTuringPiper *piper = self.webView.turing_piper;
    BDTuringWeakSelf;
    [piper on:@"second_verify.openSms" callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        BDTuringStrongSelf;
        NSString *phoneNumber = [params objectForKey:@"phone_number"];
        NSString *content = [params objectForKey:@"sms_content"];
        self.cacheCallback = callback;
        [self presentMessageComposeViewControllerWithPhone:phoneNumber content:content];
    }];
}

- (void)registerCopy {
    BDTuringPiper *piper = self.webView.turing_piper;
    [piper on:@"second_verify.copy" callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        callback(BDTuringPiperMsgFailed, nil);
    }];
}

- (void)registerAppInfo {
    BDTuringPiper *piper = self.webView.turing_piper;
    BDTuringWeakSelf;
    [piper on:@"appInfo" callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        BDTuringStrongSelf;
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        [data setValue:self.config.appName forKey:@"appName"];
        [data setValue:self.config.appID forKey:@"aid"];
        [data setValue:[self.config stringFromDelegateSelector:@selector(userID)] forKey:@"user_id"];
        [data setValue:self.config.appName forKey:@"innerAppName"];
        [data setValue:[BDTuringSandBoxHelper appVersion] forKey:@"appVersion"];
        [data setValue:[BDTNetworkManager networkType] forKey:@"netType"];
        
        [data setValue:[self.config stringFromDelegateSelector:@selector(deviceID)] forKey:@"device_id"]; //did
        [data setValue:[self.config stringFromDelegateSelector:@selector(installID)] forKey:@"install_id"]; //iid
        
        [data setValue:@(1) forKey:@"code"];
        callback(BDTuringPiperMsgSuccess, data);
    }];
}

@end
