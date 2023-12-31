//
//  TSPKTTNetInterceptPipeline.m
//  TSPrivacyKit
//
//  Created by admin on 2022/8/24.
//

#import "TSPKTTNetInterceptorPipeline.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import "TSPKCommonRequestProtocol.h"
#import "TTHttpRequest+TSPKCommonRequest.h"
#import "TTHttpResponse+TSPKCommonResponse.h"

@interface TSPKTTNetInterceptor : NSObject

+ (void)requestFilter:(TTHttpRequest *_Nonnull)request;

+ (void)responseFilter:(TTHttpRequest * _Nonnull)request response:(TTHttpResponse * _Nonnull)response data:(id _Nullable)data responseError:(NSError * _Nullable)responseError;

@end

@implementation TSPKTTNetInterceptor

+ (void)requestFilter:(TTHttpRequest *)request {
    [TSPKTTNetInterceptorPipeline onRequest:request];
}

+ (void)responseFilter:(TTHttpRequest *)request response:(TTHttpResponse *)response data:(id)data responseError:(NSError *)responseError {
    [TSPKTTNetInterceptorPipeline onResponse:response request:request data:data];
}

@end

@implementation TSPKTTNetInterceptorPipeline

+ (void)preload {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[TTNetworkManager shareInstance] setEnableReqFilter:YES];
        TTRequestFilterObject *reqFilter = [[TTRequestFilterObject alloc] initWithName:@"TSPKNetworkFilter"
                                                                    requestFilterBlock:^(TTHttpRequest *request) {
            [TSPKTTNetInterceptor requestFilter:request];
        }];
        [[TTNetworkManager shareInstance] addRequestFilterObject:reqFilter];
        
        TTResponseFilterObject *respFilter = [[TTResponseFilterObject alloc] initWithName:@"TSPKNetworkFilter"
                                                                      responseFilterBlock:^(TTHttpRequest *request, TTHttpResponse *response,
                                                                                            id data, NSError *responseError) {
            [TSPKTTNetInterceptor responseFilter:request response:response data:data responseError:responseError];
        }];
        [[TTNetworkManager shareInstance] addResponseFilterObject:respFilter];
    });
}

@end
