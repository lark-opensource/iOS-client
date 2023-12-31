//
//  HMDCloudCommandNetworkDelegateIMP.m
//  Pods-Heimdallr_Example
//
//  Created by zhangxiao on 2019/9/16.
//

#import "HMDCloudCommandNetworkIMP.h"
#import "HMDNetworkManager.h"
#import "HMDInjectedInfo+NetworkSchedule.h"
#import "pthread_extended.h"
#import "HMDNetworkReqModel.h"
#import "HMDNetworkUploadModel.h"
#import "HMDJSON.h"
// PrivateServices
#import "HMDServerStateService.h"

@implementation HMDCloudCommandNetworkIMP

+ (instancetype)sharedInstance {
    static HMDCloudCommandNetworkIMP *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDCloudCommandNetworkIMP alloc] init];
    });
    
    return instance;
}

#pragma mark--- AWECloudCommandNetworkDelegate 实现
/// 请求方法
- (void)requestWithUrl:(NSString *_Nonnull)urlString
                method:(NSString *_Nonnull)method
                params:(NSDictionary *_Nullable)params
        requestHeaders:(NSDictionary *)requestHeaders
            completion:(void (^)(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error))completion {
    HMDNetworkReqModel *reqModel = [HMDNetworkReqModel new];
    reqModel.requestURL = urlString;
    reqModel.method = method;
    reqModel.params = params;
    reqModel.headerField = requestHeaders;
    reqModel.needEcrypt = NO;
    
    [[HMDNetworkManager sharedInstance] asyncRequestWithModel:reqModel callBackWithResponse:^(NSError *error, id data, NSURLResponse *response) {
        if (completion) {
            NSData *realData = nil;
            if (![data isKindOfClass:[NSDictionary class]]) {
                realData = data;
            }
            else {
                @try {
                    NSError *error = nil;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
                    if (!error) realData = jsonData;
                } @catch (NSException *exception) {
                    realData = nil;
                }
            }
            /* 容灾的接口 */
            if([response isKindOfClass:NSHTTPURLResponse.class]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                hmd_update_server_checker(HMDReporterCloudCommandFetchCommand, nil, httpResponse.statusCode);
                
            }
            completion(realData, response, error);
        }
    }];
}

/// 上传方法
- (void)uploadWithUrl:(NSString *_Nonnull)urlString
                 data:(NSData *)data
       requestHeaders:(NSDictionary *)requestHeaders
           completion:(void (^)(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error))completion {
    HMDNetworkUploadModel *uploadModel = [HMDNetworkUploadModel new];
    uploadModel.uploadURL = urlString;
    uploadModel.data = data;
    uploadModel.headerField = requestHeaders;
    
    [[HMDNetworkManager sharedInstance] uploadWithModel:uploadModel callBackWithResponse:^(NSError *error, id data, NSURLResponse *response) {
        if (completion) {
            NSData *realData = nil;
            if (![data isKindOfClass:[NSDictionary class]]) {
                realData = data;
            }
            else {
                @try {
                    NSError *error = nil;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
                    if (!error) realData = jsonData;
                } @catch (NSException *exception) {
                    realData = nil;
                }
            }
            /* 容灾的接口 */
            if([response isKindOfClass:NSHTTPURLResponse.class]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                hmd_update_server_checker(HMDReporterCloudCommandUpload, nil, httpResponse.statusCode);
                
            }
            completion(realData, response, error);
        }
    }];
}

@end
