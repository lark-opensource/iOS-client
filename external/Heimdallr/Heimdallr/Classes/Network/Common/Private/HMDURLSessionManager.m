//
//  HMDURLSessionUploader.m
//  Heimdallr
//
//  Created by fengyadong on 2018/3/7.
//

#import "HMDURLSessionManager.h"
#import "HeimdallrUtilities.h"
#import "HMDMacro.h"
#import "HMDALogProtocol.h"
#import "HMDMemoryUsage.h"
#import "NSData+HMDGzip.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDNetworkInjector.h"
#import "HMDNetworkReqModel.h"
#import "HMDNetworkUploadModel.h"

@implementation HMDURLSessionManager

- (void)asyncRequestWithModel:(HMDNetworkReqModel *)model callBackWithResponse:(HMDNetworkDataResponseBlock)callBackWithResponse {
    NSAssert(![NSThread isMainThread], @"Please do not request network service on the main thread! Otherwise, the network library may report errors!");
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:model.requestURL]];
    [request setHTTPMethod:model.method];
    [request setTimeoutInterval:60];

    [model.headerField enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (!HMDIsEmptyString(key) && !HMDIsEmptyString(obj)) {
            [request setValue:obj forHTTPHeaderField:key];
        }
    }];
    
    [request setHTTPBody:model.postData];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         if (callBackWithResponse) {
                                             callBackWithResponse(error, data, response);
                                         }
                                     }] resume];
}

- (void)uploadWithModel:(HMDNetworkUploadModel *)model callBackWithResponse:(HMDNetworkDataResponseBlock)callBackWithResponse;{
    NSURL *url = [NSURL URLWithString:model.uploadURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.allHTTPHeaderFields = model.headerField;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:nil];
    NSURLSessionDataTask *uploadTask = [session uploadTaskWithRequest:request fromData:model.data completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(callBackWithResponse) {
            callBackWithResponse(error, data, response);
        }
    }];
    [uploadTask resume];
    [session finishTasksAndInvalidate];
}

@end
