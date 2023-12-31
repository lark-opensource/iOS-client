//
//  BytedCertCorePiperHandler+Network.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/10.
//

#import "BDCTCorePiperHandler+Network.h"
#import "BytedCertError.h"
#import "BDCTAPIService.h"
#import "BDCTImageManager.h"
#import "BytedCertManager+Private.h"
#import "BDCTLog.h"

#import <ByteDanceKit/BTDMacros.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTHTTPRequestSerializerBase.h>
#import <TTNetworkManager/TTHTTPJSONResponseSerializerBaseChromium.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>

static NSString *const kTTAppNetworkRequestTypeFlag = @"TT-RequestType";


@interface BytedCertAppNetworkRequestSerializer : TTHTTPRequestSerializerBase

@end


@implementation BytedCertAppNetworkRequestSerializer

+ (NSObject<TTHTTPRequestSerializerProtocol> *)serializer {
    return [[BytedCertAppNetworkRequestSerializer alloc] init];
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL headerField:(NSDictionary *)headField params:(id)params method:(NSString *)method constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock commonParams:(NSDictionary *)commonParam {
    NSString *reqType = [headField valueForKey:kTTAppNetworkRequestTypeFlag];
    NSDictionary *reqParams = nil;
    NSData *postDate = nil;
    if ([method isEqualToString:@"POST"]) {
        // 移除类型标记
        NSMutableDictionary *mHeader = [NSMutableDictionary dictionaryWithDictionary:headField];
        mHeader[kTTAppNetworkRequestTypeFlag] = nil;
        headField = mHeader;

        if ([reqType isEqualToString:@"form"] && [params isKindOfClass:[NSDictionary class]]) {
            reqParams = params;
        } else if ([reqType isEqualToString:@"json"] && [params isKindOfClass:[NSDictionary class]]) {
            postDate = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
        } else if ([reqType isEqualToString:@"raw"]) {
            if ([params isKindOfClass:[NSString class]]) {
                NSString *paramsString = (NSString *)params;
                postDate = [paramsString dataUsingEncoding:NSUTF8StringEncoding];
            } else if ([params isKindOfClass:[NSData class]]) {
                postDate = params;
            }
        }
    } else {
        reqParams = params;
    }

    TTHttpRequest *request = [super URLRequestWithURL:URL headerField:headField params:reqParams method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    if (postDate) {
        [request setHTTPBody:postDate];
    }

    return request;
}

@end


@implementation BDCTCorePiperHandler (Network)

- (void)registerAppFetch {
    [@[ @"app.fetch", @"bytedcert.fetch" ] enumerateObjectsUsingBlock:^(NSString *_Nonnull jsbName, NSUInteger idx, BOOL *_Nonnull stop) {
        [self registeJSBWithName:jsbName handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
            NSString *url = [params valueForKey:@"url"];
            if (BTD_isEmptyString(url)) {
                TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"url不能为空");
                return;
            }
            if (![url hasPrefix:@"http"]) {
                url = [BytedCertManager.domain stringByAppendingString:url];
            }
            NSString *method = [params btd_stringValueForKey:@"method" default:@"GET"].uppercaseString;
            BOOL needCommonParams = [params btd_boolValueForKey:@"needCommonParams"];
            BOOL isPostRequest = [method isEqualToString:@"POST"];

            NSMutableDictionary *requestHeaders = [NSMutableDictionary dictionary];
            NSDictionary *jsbHeaders = [params valueForKey:@"header"];
            if ([jsbHeaders isKindOfClass:[NSDictionary class]]) {
                [requestHeaders addEntriesFromDictionary:jsbHeaders];
            }

            /*requestType：只对POST有效，默认为"form"
             "form"：data必须是json，转成a=b&c=d的格式放到body中
             "json"：data必须是json，原格式放到body中
             "raw"：data必须是string或binary，原格式放到body中
            */
            id reqParams = [params objectForKey:isPostRequest ? @"data" : @"params"];
            if (isPostRequest) {
                NSString *requestType = [params btd_stringValueForKey:@"requestType" default:@"form"];
                // 增加类型标记
                requestHeaders[kTTAppNetworkRequestTypeFlag] = requestType;

                if ([requestType isEqualToString:@"json"] || [requestType isEqualToString:@"form"]) {
                    if ([reqParams isKindOfClass:[NSString class]]) { // JSON字符串需要转换
                        reqParams = [(NSString *)reqParams btd_jsonDictionary];
                    }

                    if (reqParams && ![reqParams isKindOfClass:[NSDictionary class]]) {
                        TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"data必须是json类型");
                        return;
                    }

                    if ([requestType isEqualToString:@"json"] && ![requestHeaders objectForKey:@"Content-Type"]) {
                        requestHeaders[@"Content-Type"] = @"application/json";
                    }
                } else {
                    if (reqParams && ![reqParams isKindOfClass:[NSString class]] && ![reqParams isKindOfClass:[NSData class]]) {
                        TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"data必须是string或binary类型");
                        return;
                    }
                }
            }
            if ([reqParams isKindOfClass:[NSDictionary class]] || !reqParams) {
                NSMutableDictionary *mutableParams = [reqParams mutableCopy] ?: [NSMutableDictionary dictionary];
                BOOL appendCertParams = YES;
                if ([params btd_objectForKey:@"append_cert_params" default:nil]) {
                    appendCertParams = [params btd_boolValueForKey:@"append_cert_params"];
                }
                if (appendCertParams && self.flow.context.baseParams.count) {
                    [mutableParams addEntriesFromDictionary:self.flow.context.baseParams];
                }
                reqParams = mutableParams.copy;
            }

            NSString *startTime = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];
            [[TTNetworkManager shareInstance] requestForJSONWithResponse:url params:reqParams method:method needCommonParams:needCommonParams headerField:requestHeaders.copy requestSerializer:BytedCertAppNetworkRequestSerializer.class responseSerializer:TTHTTPJSONResponseSerializerBaseChromium.class autoResume:YES callback:^(NSError *error, id obj, TTHttpResponse *response) {
                if ([jsbName isEqualToString:@"app.fetch"]) {
                    NSMutableDictionary *jsbResult = [NSMutableDictionary dictionary];
                    jsbResult[@"response"] = [obj isKindOfClass:NSDictionary.class] ? [obj btd_jsonStringEncoded] : @"";
                    jsbResult[@"status"] = @(response.statusCode);
                    jsbResult[@"code"] = error ? @(0) : @(1);
                    jsbResult[@"beginReqNetTime"] = startTime;
                    if (error) {
                        NSInteger errCode = error.code; // 需要先取再传，否则前端收到的数值会不一致
                        jsbResult[@"error_code"] = @(errCode);
                    }
                    if (response.allHeaderFields) {
                        jsbResult[@"header"] = response.allHeaderFields;
                    }
                    callback(error ? TTBridgeMsgFailed : TTBridgeMsgSuccess, jsbResult, nil);
                } else {
                    callback(error ? TTBridgeMsgFailed : TTBridgeMsgSuccess, @{
                        @"byted_cert_data" : (obj ?: [NSDictionary dictionary])
                    }, nil);
                }
            }];
        }];
    }];
}

- (void)registerDoRequest {
    [self registeJSBWithName:@"bytedcert.doRequest" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        BDCTLogInfo(@"New event comes from H5: %@", params);
        NSString *method = [params btd_stringValueForKey:@"method" default:@"GET"].uppercaseString;
        NSString *path = params[@"path"];
        NSDictionary *jsonDic = params[@"data"];
        [self.flow.apiService bytedFetch:method url:path params:jsonDic callback:^(NSDictionary *_Nullable data, BytedCertError *_Nullable error) {
            callback(TTBridgeMsgSuccess, [BDCTCorePiperHandler jsbCallbackResultWithParams:data error:error], nil);
        }];
    }];
}

- (void)registerAppUpload {
    [self registeJSBWithName:@"bytedcert.upload" handler:^(NSDictionary *_Nullable jsbParams, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        NSString *url = [jsbParams btd_stringValueForKey:@"url"];
        if (BTD_isEmptyString(url)) {
            TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"url不能为空");
            return;
        }
        NSData *imageData = [self.imageManager getImageByType:[jsbParams btd_stringValueForKey:@"type"]];
        if (!imageData) {
            TTBRIDGE_CALLBACK_WITH_MSG(TTBridgeMsgFailed, @"找不到图片数据");
            return;
        }
        NSDictionary *postParams = [[jsbParams btd_stringValueForKey:@"params"] btd_jsonDictionary];
        NSString *uploadFileName = [jsbParams btd_stringValueForKey:@"file_name" default:@"image"];
        [[TTNetworkManager shareInstance] uploadWithURL:url parameters:postParams headerField:nil constructingBodyWithBlock:^(id<TTMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:uploadFileName fileName:uploadFileName mimeType:@"multipart/form-data"];
        } progress:nil needcommonParams:YES requestSerializer:TTHTTPRequestSerializerBase.class responseSerializer:TTHTTPJSONResponseSerializerBaseChromium.class autoResume:YES callback:^(NSError *error, id jsonObj) {
            callback(error ? TTBridgeMsgFailed : TTBridgeMsgSuccess, @{
                @"byted_cert_data" : (jsonObj ?: NSDictionary.dictionary)
            }, nil);
        }];
    }];
}

@end
