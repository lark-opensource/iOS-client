//
//  TSPKTTNetRedirectInterceptPipeline.m
//  Musically
//
//  Created by admin on 2022/10/31.
//

#import "TSPKTTNetRedirectInterceptPipeline.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import "TSPKCommonRequestProtocol.h"
#import "TTHttpRequest+TSPKCommonRequest.h"
#import "TTHttpResponse+TSPKCommonResponse.h"
#import "TTRedirectTask+TSPKCommonRequest.h"

@interface TSPKTTNetRedirectInterceptor : NSObject

+ (void)requestFilter:(TTRedirectTask *_Nonnull)task;

@end

@implementation TSPKTTNetRedirectInterceptor

+ (void)requestFilter:(TTRedirectTask *)task {
    [TSPKTTNetRedirectInterceptPipeline onRequest:task];
}

@end

@implementation TSPKTTNetRedirectInterceptPipeline

+ (void)preload {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[TTNetworkManager shareInstance] setEnableReqFilter:YES];
        TTRedirectFilterObject *redirectFilterObject = [[TTRedirectFilterObject alloc] initWithName:@"TSPKNetworkFilter" redirectFilterBlock:^(TTRedirectTask * _Nonnull task) {
            [TSPKTTNetRedirectInterceptor requestFilter:task];
        }];
        [[TTNetworkManager shareInstance] addRedirectFilterObject:redirectFilterObject];
    });
}

@end
