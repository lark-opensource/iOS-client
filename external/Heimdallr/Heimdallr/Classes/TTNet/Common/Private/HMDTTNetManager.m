//
//  HMDTTNetUploader.m
//  Heimdallr
//
//  Created by fengyadong on 2018/3/7.
//

#import "HMDTTNetManager.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTHTTPResponseSerializerBase.h>
#import <TTNetworkManager/TTDefaultHTTPRequestSerializer.h>
#import "HeimdallrUtilities.h"
#import <TTNetworkManager/TTNetworkUtil.h>
#import "HMDALogProtocol.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
#import "NSData+HMDGzip.h"
#import "NSDictionary+HMDJSON.h"
#import "NSData+HMDJSON.h"
#import "HMDTTNetHelper.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "HMDNetworkReqModel.h"
#import "HMDNetworkUploadModel.h"
#import <BDNetworkTag/BDNetworkTagManager.h>

@interface HMDRequestSerializer : TTDefaultHTTPRequestSerializer

@end

@implementation HMDRequestSerializer

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(id)parameters
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    return [self URLRequestWithURL:URL headerField:nil params:parameters method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                         headerField:(NSDictionary *)headField
                              params:(id)parameters
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    TTHttpRequest * request = [super URLRequestWithURL:URL headerField:headField params:nil method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    request.timeoutInterval = 30;

    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    
    if([request.HTTPMethod isEqualToString:@"POST"]) {
        [request setHTTPBody:parameters];
    }
    
    return request;
}

@end

@implementation HMDTTNetManager

- (BOOL)isChromium {
    return [HMDTTNetHelper isTTNetChromium];
}

- (void)asyncRequestWithModel:(HMDNetworkReqModel *)model callBackWithResponse:(HMDNetworkDataResponseBlock)callBackWithResponse {
    NSAssert(![NSThread isMainThread], @"Do not request network service on the main thread! Otherwise, the network library may report an error!");
    
    //for TTNet overall control
    NSMutableDictionary *finalHeaderField = [NSMutableDictionary dictionary];
    [finalHeaderField addEntriesFromDictionary:model.headerField];
    if (model.isManualTriggered) {
        [finalHeaderField addEntriesFromDictionary:[BDNetworkTagManager manualTriggerTagInfo]];
    } else {
        [finalHeaderField addEntriesFromDictionary:[BDNetworkTagManager autoTriggerTagInfo]];
    }
    
    [[TTNetworkManager shareInstance] requestForBinaryWithResponse:model.requestURL params:model.postData method:model.method needCommonParams:NO headerField:finalHeaderField enableHttpCache:NO autoResume:YES requestSerializer:[HMDRequestSerializer class] responseSerializer:nil progress:nil callback:^(NSError *error, id obj, TTHttpResponse *response) {
        if(callBackWithResponse) {
            NSURLResponse *urlResponse = [self responseWithTTResponse:response];
            callBackWithResponse(error, obj, urlResponse);
        }
    } callbackInMainThread:NO];
}

- (void)uploadWithModel:(HMDNetworkUploadModel *)model callBackWithResponse:(HMDNetworkDataResponseBlock)callBackWithResponse {
    //for TTNet overall control
    NSMutableDictionary *finalHeaderField = [NSMutableDictionary dictionary];
    [finalHeaderField addEntriesFromDictionary:model.headerField];
    if (model.isManualTriggered) {
        [finalHeaderField addEntriesFromDictionary:[BDNetworkTagManager manualTriggerTagInfo]];
    } else {
        [finalHeaderField addEntriesFromDictionary:[BDNetworkTagManager autoTriggerTagInfo]];
    }
    
    [[TTNetworkManager shareInstance] uploadRawDataWithResponse:model.uploadURL method:@"POST" headerField:finalHeaderField bodyField:model.data progress:nil requestSerializer:nil responseSerializer:nil autoResume:YES callback:^(NSError *error, id obj, TTHttpResponse *response) {
        if(callBackWithResponse) {
            NSURLResponse *urlResponse = [self responseWithTTResponse:response];
            callBackWithResponse(error, obj, urlResponse);
        }
    } timeout:60];
}

- (NSHTTPURLResponse *)responseWithTTResponse:(TTHttpResponse *)ttResponse
{
    NSHTTPURLResponse *response;
    if (ttResponse) {
        NSMutableDictionary<NSString *, NSString *> *headerFeilds = [NSMutableDictionary dictionary];
        for (id feildKey in ttResponse.allHeaderFields.allKeys) {
            id res = [ttResponse.allHeaderFields objectForKey:feildKey];
            if ([res isKindOfClass:[NSString class]] && [feildKey isKindOfClass:[NSString class]]) {
                [headerFeilds setValue:res forKey:feildKey];
            }
        }
        response = [[NSHTTPURLResponse alloc] initWithURL:ttResponse.URL statusCode:ttResponse.statusCode HTTPVersion:nil headerFields:headerFeilds];
    } else {
        response = [[NSHTTPURLResponse alloc] init];
    }

    return response;
}

@end
