//
//  BDTNetworkManager+TTNet.m
//  BDTuring
//
//  Created by bob on 2021/8/4.
//

#import "BDTNetworkManager+TTNet.h"
#import "BDTuringUtility.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringMacro.h"
#import "NSString+BDTuring.h"
#import "BDTuringPostRequestSerializer.h"
#import "BDTuringPostCommonRequestSerializer.h"
#import "BDTuringParameter.h"
#import "BDTuringTVAppNetworkRequestSerializer.h"

#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <TTReachability/TTReachability+Conveniences.h>


@implementation BDTNetworkManager (TTNet)

- (void)setup {
    [[TTNetworkManager shareInstance] setEnableReqFilter:YES];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[TTNetworkManager shareInstance] addRequestFilterBlock:^(TTHttpRequest *request) {
            [request setValue:BDTuringSDKVersion forHTTPHeaderField:kBDTuringHeaderSDKVersion];
        }];
        
        [[TTNetworkManager shareInstance] addResponseFilterBlock:^(TTHttpRequest *request, TTHttpResponse *response, id value, NSError *responseError) {
            NSString *parameters = [[response allHeaderFields] objectForKey:kBDTuringHeaderSDKParameters];
            if (!BDTuring_isValidString(parameters)) {
                return;
            }
            BDALOG_PROTOCOL_INFO_TAG(@"BDTuring", @"bdturing-verify header string (%@)", parameters);
            NSDictionary *data = [parameters turing_dictionaryFromJSONString];
            [[BDTuringParameter sharedInstance] updateCurrentParameter:data];
        }];
    });
}

- (void)asyncRequestForURL:(NSString *)requestURL
                    method:(NSString *)method
           queryParameters:(nullable NSDictionary *)queryParameters
            postParameters:(nullable NSDictionary *)postParameters
                  callback:(BDTuringNetworkFinishBlock)callback
             callbackQueue:(nullable dispatch_queue_t)queue
                   encrypt:(BOOL)encrypt
                   tagType:(BDTNetworkTagType)type{
    if (callback == nil) {
        return;
    }
    
    NSString *finalRequestURL = turing_requestURLWithQuery(requestURL, queryParameters);
    TTNetworkObjectFinishBlockWithResponse dataCallback = ^(NSError *error, NSData *data, TTHttpResponse *response) {
        dispatch_async(queue ?: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if (callback) callback(data);
        });
    };
    Class<TTHTTPRequestSerializerProtocol> clazz = encrypt ? [BDTuringPostRequestSerializer class] : [BDTuringPostCommonRequestSerializer class];
    
    NSDictionary *taggedHeaderField = [self createTaggedHeaderFieldWith:nil type:type];
    [[TTNetworkManager shareInstance] requestForBinaryWithResponse:finalRequestURL
                                                            params:postParameters
                                                            method:method
                                                  needCommonParams:NO
                                                       headerField:taggedHeaderField
                                                   enableHttpCache:NO
                                                        autoResume:YES
                                                 requestSerializer:clazz
                                                responseSerializer:nil
                                                          progress:nil
                                                          callback:dataCallback
                                              callbackInMainThread:NO];

}

- (void)tvRequestForJSONWithResponse:(NSString *)requestURL
                              params:(id)params
                              method:(NSString *)method
                    needCommonParams:(BOOL)commonParams
                         headerField:(NSDictionary *)headerField
                            callback:(BDTuringTwiceVerifyNetworkFinishBlock)callback
                             tagType:(BDTNetworkTagType)type{
    if (callback == nil) {
        return;
    }
    
    TTNetworkObjectFinishBlockWithResponse dataCallback = ^(NSError *error, NSData *data, TTHttpResponse *response) {
        if (callback) callback(error, data, response.statusCode);
    };
    
    NSDictionary *finalHeaderField = [self createTaggedHeaderFieldWith:headerField type:type];
    [[TTNetworkManager shareInstance] requestForJSONWithResponse:requestURL
                                                            params:params
                                                            method:method
                                                  needCommonParams:commonParams
                                                       headerField:finalHeaderField
                                                 requestSerializer:BDTuringTVAppNetworkRequestSerializer.class
                                                responseSerializer:nil
                                                        autoResume:YES
                                                          callback:dataCallback];
}

- (void)uploadEvent:(NSString *)key param:(NSDictionary *)param {
    [BDTrackerProtocol eventV3:key params:param];
}

- (NSString *)networkType {
    return [TTReachability currentConnectionMethodName];
}

@end
