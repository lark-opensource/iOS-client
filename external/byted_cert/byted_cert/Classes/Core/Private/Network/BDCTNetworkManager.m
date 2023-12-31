//
// Created by chenzhendong.ok@bytedance.com on 2021/8/14.
//

#import "BDCTNetworkManager.h"
#import "BDCTEventTracker.h"
#import "BytedCertManager+Private.h"
#import "BytedCertNetInfo.h"
#import "FaceLiveUtils.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSData+BTDAdditions.h>
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <TTNetworkManager/TTHTTPRequestSerializerBase.h>
#import <TTNetworkManager/TTHTTPBinaryResponseSerializerBase.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>


@implementation BDCTNetworkManager

+ (void)requestForResponseWithUrl:(NSString *)url method:(NSString *)method params:(NSDictionary *)params binaryNames:(NSArray *)binaryNames binaryDatas:(NSArray *)binaryDatas completion:(BytedCertHttpResponseCompletion)completion {
    [self requestForResponseWithUrl:url method:method params:params binaryNames:binaryNames binaryDatas:binaryDatas headerField:nil completion:completion];
}

+ (void)requestForResponseWithUrl:(NSString *)url method:(NSString *)method params:(NSDictionary *_Nullable)params binaryNames:(NSArray *_Nullable)binaryNames binaryDatas:(NSArray *_Nullable)binaryDatas headerField:(NSDictionary *_Nullable)headerField completion:(BytedCertHttpResponseCompletion)completion {
    BytedCertNetInfo *info = [self bytedPrepareSession:url params:params binaryDatas:binaryDatas binaryNames:binaryNames method:method headerField:headerField];
    [self startRequest:info callback:^(NSError *_Nullable error, id _Nullable obj, BytedCertNetResponse *_Nonnull response) {
        [self handleHttpData:obj response:response error:error callback:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
            error.requestUrl = url;
            !completion ?: completion(response, jsonObj, error);
        }];
    }];
}

+ (void)handleHttpData:(NSData *)data response:(BytedCertNetResponse *)response error:(NSError *)error callback:(BytedCertHttpCompletion)callback {
    if (error) {
        !callback ?: callback(nil, [[BytedCertError alloc] initWithType:BytedCertErrorServer oriError:error]);
    } else {
        if (data != nil && [data isKindOfClass:NSData.class] && response.statusCode == 200) {
            NSDictionary *jsonObj = [data btd_jsonDictionary];
            NSInteger statusCode = [jsonObj btd_integerValueForKey:@"status_code"];
            BytedCertError *bytedCertError = nil;
            if (statusCode != 0) {
                NSString *errorMsg = jsonObj[@"description"];
                bytedCertError = [[BytedCertError alloc] initWithType:statusCode errorMsg:errorMsg oriError:nil];
            }
            !callback ?: callback(jsonObj, bytedCertError);
        } else {
            !callback ?: callback(nil, [[BytedCertError alloc] initWithType:BytedCertErrorUnknown]);
        }
    }
}

+ (NSDictionary *)sysInfo {
    static dispatch_once_t onceToken;
    static NSDictionary *sysInfo;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *mutableSysInfo = [[NSMutableDictionary alloc] init];
        mutableSysInfo[@"sdk_version"] = BytedCertSDKVersion;
        mutableSysInfo[@"byted_cert_sdk_version"] = BytedCertSDKVersion;
        mutableSysInfo[@"algo_action_version"] = @"3.0";
        mutableSysInfo[@"os_name"] = [[UIDevice currentDevice] systemName];
        mutableSysInfo[@"os"] = @"1";
        mutableSysInfo[@"did"] = BDTrackerProtocol.deviceID;
        mutableSysInfo[@"os_version"] = [UIDevice btd_OSVersion];
        mutableSysInfo[@"device_brand"] = [UIDevice btd_platformString];
        mutableSysInfo[@"smash_live_model_name"] = [FaceLiveUtils smashLiveModelName];
        mutableSysInfo[@"smash_sdk_version"] = [FaceLiveUtils smashSdkVersion];
        sysInfo = mutableSysInfo.copy;
    });
    return sysInfo;
}

+ (BytedCertNetInfo *)bytedPrepareSession:(NSString *)addr params:(NSDictionary *)params binaryDatas:(NSArray *)binaryDatas binaryNames:(NSArray *)binaryNames method:(NSString *)method {
    return [self bytedPrepareSession:addr params:params binaryDatas:binaryDatas binaryNames:binaryNames method:method headerField:nil];
}

+ (BytedCertNetInfo *)bytedPrepareSession:(NSString *)addr params:(NSDictionary *)params binaryDatas:(NSArray *)binaryDatas binaryNames:(NSArray *)binaryNames method:(NSString *)method headerField:(NSDictionary *)headerField {
    NSMutableDictionary *paramsDict = [[NSMutableDictionary alloc] init];
    [paramsDict addEntriesFromDictionary:[self sysInfo]];
    [params enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull value, BOOL *_Nonnull stop) {
        if (![value isKindOfClass:[NSString class]] || ((NSString *)value).length) {
            [paramsDict setValue:value forKey:key];
        }
    }];

    // TODO hardcode
    paramsDict[@"lang"] = @"zh";

    NSString *urlString = [BytedCertManager.domain stringByAppendingString:addr];
    if (![urlString hasPrefix:@"http"]) {
        urlString = [@"https://" stringByAppendingString:urlString];
    }

    BytedCertNetInfo *info = [[BytedCertNetInfo alloc] init];
    info.method = method;
    if ([method isEqualToString:@"GET"]) {
        paramsDict = [paramsDict btd_map:^id _Nullable(id _Nonnull key, id _Nonnull obj) {
                         if ([obj isKindOfClass:NSString.class]) {
                             return obj;
                         }
                         if ([obj respondsToSelector:@selector(description)]) {
                             return [obj description];
                         }
                         return @"";
                     }].mutableCopy;
        info.url = [urlString btd_urlStringByAddingParameters:paramsDict.copy];
    } else if ([method isEqualToString:@"POST"]) {
        info.url = urlString;
        info.params = paramsDict;
    }
    info.binaryDatas = binaryDatas;
    info.binaryNames = binaryNames;
    info.headerField = headerField;
    return info;
}

+ (void)startRequest:(BytedCertNetInfo *)info callback:(BytedCertHttpFinishWithResponse)callback {
    NSDate *startTime = NSDate.date;
    BytedCertHttpFinishWithResponse callbackWrapper = ^(NSError *_Nullable error, id _Nullable obj, BytedCertNetResponse *response) {
        [BDCTEventTracker trackNetRequestWithStartTime:startTime path:(info.url.length ? [[NSURL alloc] initWithString:info.url].path : nil)response:response error:error];
        btd_dispatch_async_on_main_queue(^{
            !callback ?: callback(error, obj, response);
        });
    };
    if ((info.binaryDatas && info.binaryDatas.count > 0) || info.filePath != nil) {
        if ([[BytedCertInterface sharedInstance].bytedCertNetDelegate respondsToSelector:@selector(uploadWithResponse:callback:timeout:)]) {
            [[BytedCertInterface sharedInstance].bytedCertNetDelegate uploadWithResponse:info callback:callbackWrapper timeout:240];
        } else {
            NSProgress __autoreleasing *progress = nil;
            if (info.filePath != nil) {
                [[TTNetworkManager shareInstance] uploadRawFileWithResponse:info.url method:@"POST" headerField:info.headerField filePath:info.filePath progress:&progress requestSerializer:TTHTTPRequestSerializerBase.class responseSerializer:TTHTTPBinaryResponseSerializerBase.class autoResume:YES callback:^(NSError *error, id obj, TTHttpResponse *response) {
                    callbackWrapper(error, obj, [BytedCertNetResponse responseWithTTNetHttpResponse:response]);
                } timeout:240];
            } else {
                //upload file data
                [[TTNetworkManager shareInstance] uploadWithResponse:info.url parameters:info.params headerField:info.headerField constructingBodyWithBlock:^(id<TTMultipartFormData> formData) {
                    NSString *mimetype = @"multipart/form-data";
                    for (int i = 0; i < info.binaryDatas.count; ++i) {
                        NSString *fileName = info.binaryNames[i];
                        NSData *sdkData = info.binaryDatas[i];
                        [formData appendPartWithFileData:sdkData name:fileName fileName:fileName mimeType:mimetype];
                    }
                } progress:&progress needcommonParams:YES requestSerializer:TTHTTPRequestSerializerBase.class responseSerializer:TTHTTPBinaryResponseSerializerBase.class autoResume:YES callback:^(NSError *error, id obj, TTHttpResponse *response) {
                    callbackWrapper(error, obj, [BytedCertNetResponse responseWithTTNetHttpResponse:response]);
                } timeout:240];
            }
        }
    } else {
        if ([[BytedCertInterface sharedInstance].bytedCertNetDelegate respondsToSelector:@selector(requestForBinaryWithResponse:callback:)]) {
            [[BytedCertInterface sharedInstance].bytedCertNetDelegate requestForBinaryWithResponse:info callback:callbackWrapper];
        } else {
            [[TTNetworkManager shareInstance]
                requestForBinaryWithResponse:info.url
                                      params:info.params
                                      method:info.method
                            needCommonParams:YES
                                 headerField:info.headerField
                             enableHttpCache:NO
                           requestSerializer:TTHTTPRequestSerializerBase.class
                          responseSerializer:TTHTTPBinaryResponseSerializerBase.class
                                    progress:nil callback:^(NSError *error, NSData *data, TTHttpResponse *response) {
                                        callbackWrapper(error, data, [BytedCertNetResponse responseWithTTNetHttpResponse:response]);
                                    }
                        callbackInMainThread:YES];
        }
    }
}

@end
