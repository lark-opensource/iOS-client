//
//  AWEEffectPlatformRequestManager.m
//  AWEStudio
//
// Created by Li Yansong on October 22, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import "AWEEffectPlatformRequestManager.h"

#import <TTNetworkManager/TTNetworkManager.h>
#import "AWEEffectPlatformPostSerializer.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogProtocol.h>

@implementation AWEEffectPlatformRequestManager

#pragma mark - Protocols
#pragma mark EffectPlatformRequestDelegate

- (void)downloadFileWithURLString:(NSString *)urlString
                     downloadPath:(NSURL *)path
                 downloadProgress:(NSProgress * __autoreleasing *)downloadProgress
                       completion:(void (^)(NSError *error, NSURL *fileURL, NSDictionary *extraInfo))completion {
    void(^completionWrapper)(TTHttpResponse *response, NSURL *fileURL, NSError *error) = ^(TTHttpResponse *response, NSURL *fileURL, NSError *error) {
        NSDictionary *extraInfo;
        TTHttpResponse *tempResonse = response;
        if (tempResonse) {
            AWELogToolInfo(AWELogToolTagRecord, @"AWEEffectPlatformRequestManager response: %p, response statusCode : %@", response, @(response.statusCode));
            extraInfo = @{ IESEffectNetworkResponse : tempResonse,
                           IESEffectNetworkResponseStatus : @(tempResonse.statusCode),
                           IESEffectNetworkResponseHeaderFields : tempResonse.allHeaderFields.description ?: @""
                           };
        }
        ACCBLOCK_INVOKE(completion, error, fileURL, extraInfo);
    };
    [[TTNetworkManager shareInstance] downloadTaskWithRequest:urlString
                                                   parameters:nil
                                                  headerField:nil
                                             needCommonParams:NO
                                                     progress:downloadProgress
                                                  destination:path
                                            completionHandler:completionWrapper];
}

- (void)requestWithURLString:(NSString *)urlString
                  parameters:(NSDictionary *)parameters
                headerFields:(NSDictionary *)headerFields
                  httpMethod:(NSString *)httpMethod
                  completion:(void (^)(NSError *error, id result))completion {
    void(^wrapperCompletion)(NSError *error, id obj, TTHttpResponse *response) = ^(NSError *error, id obj, TTHttpResponse *response) {
        completion(error, obj);
    };
    BOOL isPost = [httpMethod isEqualToString:@"POST"];
    [[TTNetworkManager shareInstance] requestForJSONWithResponse:urlString
                                                          params:parameters
                                                          method:httpMethod
                                                needCommonParams:NO
                                                     headerField:headerFields
                                               requestSerializer:isPost ? [AWEEffectPlatformPostSerializer class] : nil
                                              responseSerializer:nil
                                                      autoResume:YES
                                                   verifyRequest:NO
                                              isCustomizedCookie:NO
                                                        callback:wrapperCompletion
                                            callbackInMainThread:NO];
}

@end
