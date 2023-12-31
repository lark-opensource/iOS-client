//
//  AWECloudCommandNetworkUtility.m
//  AWECloudCommand
//
//  Created by wangdi on 2018/3/25.
//

#import "AWECloudCommandNetworkUtility.h"
#import "NSDictionary+AWECloudCommandUtil.h"
#import "AWECloudCommandNetworkHandler.h"
#import <BDNetworkTag/BDNetworkTagManager.h>

static NSString *const kBoundary = @"AaB03xIC24LSgx5D32DFLKLZCNO23";

@implementation AWECloudCommandNetworkUtility

static NSDictionary *requestMethodDict;

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        requestMethodDict = @{
                              @(AWECloudCommandRequestMethodGet) : @"GET",
                              @(AWECloudCommandRequestMethodPost) : @"POST"
                              };
    });
}

+ (void)requestWithUrl:(NSString *)url
         requestMethod:(AWECloudCommandRequestMethod)requestMethod
                params:(NSDictionary *)params
        requestHeaders:(NSDictionary *)requestHeaders
               success:(successBlock)success
               failure:(failureBlock)failure
{
    [self requestWithUrl:url
           requestMethod:requestMethod
                  params:params
          requestHeaders:requestHeaders
  needDecodeResponseData:YES
                 success:success
                 failure:failure];
}

+ (void)requestWithUrl:(NSString *)url
         requestMethod:(AWECloudCommandRequestMethod)requestMethod
                params:(NSDictionary *)params
        requestHeaders:(NSDictionary *)requestHeaders
needDecodeResponseData:(BOOL)needDecodeResponseData
               success:(successBlock)success
               failure:(failureBlock)failure
{
    [[AWECloudCommandNetworkHandler sharedInstance] requestWithUrl:url
                                                            method:requestMethodDict[@(requestMethod)]
                                                            params:params
                                                    requestHeaders:requestHeaders
                                                        completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                            if (needDecodeResponseData) {
                                                                //ran is the key for aes
                                                                NSString *ran = nil;
                                                                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                                    id ranObject = [[(NSHTTPURLResponse *)response allHeaderFields] awe_cc_objectForInsensitiveKey:@"ran"];
                                                                    if (ranObject && [ranObject isKindOfClass:NSString.class]) {
                                                                        ran = (NSString *)ranObject;
                                                                    }
                                                                }
                                                                [self _dealWithResultData:data ran:ran error:error url:url success:success failure:failure];
                                                            } else {
                                                                NSHTTPURLResponse *resp = nil;
                                                                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                                    resp = (NSHTTPURLResponse *)response;
                                                                }
                                                                if (resp && resp.statusCode >= 200 && resp.statusCode < 300 && !error) {
                                                                    if (success) {
                                                                        //ran is the key for aes
                                                                        NSString *ran = nil;
                                                                        id ranObject = [[(NSHTTPURLResponse *)response allHeaderFields] awe_cc_objectForInsensitiveKey:@"ran"];
                                                                        if (ranObject && [ranObject isKindOfClass:NSString.class]) {
                                                                            ran = (NSString *)ranObject;
                                                                        }
                                                                        success(nil, data, ran);
                                                                    }
                                                                } else {
                                                                    if (failure) {
                                                                        failure(error);
                                                                    }
                                                                }
                                                            }
                                                        }];
}

+ (void)uploadDataWithUrl:(NSString *)url
                 fileName:(NSString *)fileName
                     data:(NSData *)data
                   params:(NSDictionary * _Nullable)params
                 mimeType:(NSString *)mimeType
           requestHeaders:(NSDictionary * _Nullable)requestHeaders
                  success:(successBlock)success
                  failure:(failureBlock)failure
{
    [self uploadDataWithUrl:url
                   fileName:fileName
                   fileType:nil
                       data:data
                     params:params
               commonParams:nil
                   mimeType:mimeType
             requestHeaders:requestHeaders
                    success:success
                    failure:failure];
}

+ (void)uploadDataWithUrl:(NSString *)url
                 fileName:(NSString *)fileName
                 fileType:(NSString * _Nullable)fileType
                     data:(NSData *)data
                   params:(NSDictionary *)params
             commonParams:(NSDictionary *  _Nullable)commonParams
                 mimeType:(NSString *)mimeType
           requestHeaders:(NSDictionary *)requestHeaders
                  success:(successBlock)success
                  failure:(failureBlock)failure
{
    AWECloudCommandMultiData *multiData = [AWECloudCommandMultiData new];
    multiData.data = data;
    multiData.fileName = fileName;
    multiData.fileType = fileType;
    multiData.mimeType = mimeType;
    [self uploadMultiDataWithUrl:url
                       dataArray:@[multiData]
                          params:params
                    commonParams:commonParams
                  requestHeaders:requestHeaders
                         success:success
                         failure:failure];
}

+ (void)uploadMultiDataWithUrl:(NSString *)url
                     dataArray:(NSArray<AWECloudCommandMultiData *> *)dataArray
                        params:(NSDictionary *)params
                  commonParams:(NSDictionary *)commonParams
                requestHeaders:(NSDictionary *)requestHeaders
                       success:(successBlock)success
                       failure:(failureBlock)failure
{
    NSMutableDictionary *uploadRequestHeaders = [NSMutableDictionary dictionaryWithDictionary:@{@"Content-Type" : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kBoundary]}];
    if (requestHeaders) {
        [uploadRequestHeaders addEntriesFromDictionary:requestHeaders];
    }
    [uploadRequestHeaders addEntriesFromDictionary:[BDNetworkTagManager autoTriggerTagInfo]];

    NSData *bodyData = [self _uploadRequestBodyWithMultiData:dataArray
                                                      params:params
                                                commonParams:commonParams];
    [[AWECloudCommandNetworkHandler sharedInstance] uploadWithUrl:url
                                                             data:bodyData
                                                   requestHeaders:uploadRequestHeaders
                                                       completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                           //ran is the key for aes
                                                           NSString *ran = nil;
                                                           if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                               id ranObject = [[(NSHTTPURLResponse *)response allHeaderFields] awe_cc_objectForInsensitiveKey:@"ran"];
                                                               if (ranObject && [ranObject isKindOfClass:NSString.class]) {
                                                                   ran = (NSString *)ranObject;
                                                               }
                                                           }
                                                           [self _dealWithResultData:data ran:ran error:error url:url success:success failure:failure];
                                                       }];
}

+ (NSString *)fileMimeTypeWithPath:(NSString *)filePath
{
    if (filePath.length <= 0) {
        return nil;
    }
    NSURL *url = [NSURL fileURLWithPath:filePath];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];
    __block NSString *mimeType = @"application/octet-stream";
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (response.MIMEType.length > 0) {
            mimeType = response.MIMEType;
        }
        dispatch_semaphore_signal(semaphore);
    }];
    [dataTask resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return mimeType;
}

+ (void)_dealWithResultData:(NSData *)data
                        ran:(NSString *)ran
                      error:(NSError *)error
                        url:(NSString *)url
                    success:(successBlock)success
                    failure:(failureBlock)failure
{
    NSError *serizerError = nil;
    id responseObject = nil;
    if (data) {
        responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serizerError];
    }
    NSInteger statusCode = [responseObject awe_cc_integerValueForKey:@"status_code"];
    if (!error && !serizerError && statusCode == 0) {
        if (success) {
            success(responseObject, data, ran);
        }
    } else {
        NSError *resultError = nil;
        if (error) {
            resultError = [NSError errorWithDomain:error.domain code:error.code userInfo:error.userInfo];
        } else if (statusCode != 0) {
            resultError = [NSError errorWithDomain:url code:statusCode userInfo:nil];
        } else if (serizerError) {
            resultError = [NSError errorWithDomain:url code:serizerError.code userInfo:serizerError.userInfo];
        }
        if (failure) {
            failure(resultError);
        }
    }
}

+ (NSData *)_uploadRequestBodyWithMultiData:(NSArray<AWECloudCommandMultiData *> *)dataArray
                                     params:(NSDictionary *)params
                               commonParams:(NSDictionary *)commonParams
{
    NSMutableData *body = [[NSMutableData alloc] init];
    for (NSString *key in params) {
        NSString *value = [params awe_cc_stringValueForKey:key];
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", kBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", value] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", kBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    for (int i = 0; i < dataArray.count; i++) {
        @autoreleasepool {
            AWECloudCommandMultiData *multiData = dataArray[i];
            NSString *fileType = multiData.fileType;
            NSString *fileName = multiData.fileName;
            NSString *mimeType = multiData.mimeType;
            if (fileType.length) {
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filetype=\"%@\"; filename=\"%@\"\r\n", @"file", fileType, fileName] dataUsingEncoding:NSUTF8StringEncoding]];
            } else {
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", fileName] dataUsingEncoding:NSUTF8StringEncoding]];
            }
            [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:multiData.data];
            
            if (commonParams.count || i != dataArray.count - 1) {
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", kBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
            }
            else {
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", kBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
            }
        }
    }
    
    if (commonParams.count) {
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filetype=\"%@\"; filename=\"%@\"\r\n\r\n", @"common_params", @"command_commonparams", @"common_params.txt"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSJSONSerialization dataWithJSONObject:commonParams options:0 error:nil]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", kBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return body;
}

@end

