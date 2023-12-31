//
//  IESEffectPlatformRequestManager.m
//  AWEStudio
//
//  Created by 李彦松 on 2018/10/22.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "IESEffectPlatformRequestManager.h"
#import "IESEffectPlatformPostSerializer.h"
#import <EffectPlatformSDK/IESEffectLogger.h>
#import <TTNetworkManager/TTNetworkManager.h>

@interface IESEffectPlatformRequestManager ()

@property (atomic, strong) NSDictionary *preFetchHeaderFields;

@property (atomic, strong) NSPointerArray *preFetchCompletionPointers;

@end

@implementation IESEffectPlatformRequestManager

+ (instancetype)requestManager {
    static IESEffectPlatformRequestManager *requestManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        requestManager = [[self alloc] init];
    });
    return requestManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _preFetchCompletionPointers = [[NSPointerArray alloc] init];
    }
    return self;
}

#pragma mark EffectPlatformRequestDelegate

- (void)downloadFileWithURLString:(NSString *)urlString
                     downloadPath:(NSURL *)path
                 downloadProgress:(NSProgress * __autoreleasing *)downloadProgress
                       completion:(void (^)(NSError *error, NSURL *fileURL, NSDictionary *extraInfo))completion {
    NSAssert(path.isFileURL, @"destination must be a file NSURL!");
    
    if (![NSURL URLWithString:urlString]) {
        IESEffectLogError(@"download file with urlString:%@ invalid!!!!", urlString ?: @"");
        //仅当URLWithString返回nil时加个编码处理
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
    
    NSDictionary *headerFields = nil;
    if (self.preFetchHeaderFields.count > 0 && [self isPreFetchCompletionWithCompletionObject:completion]) {
        headerFields = self.preFetchHeaderFields;
    }
    
    [[TTNetworkManager shareInstance] downloadTaskWithRequest:urlString
                                                   parameters:nil
                                                  headerField:headerFields
                                             needCommonParams:NO
                                                     progress:downloadProgress
                                                  destination:path
                                            completionHandler:^(TTHttpResponse *response, NSURL *filePath, NSError *error) {
        NSDictionary *extraInfo = nil;
        if (response) {
            extraInfo = @{IESEffectNetworkResponse : response,
                          IESEffectNetworkResponseStatus : @(response.statusCode),
                          IESEffectNetworkResponseHeaderFields : response.allHeaderFields.description ?: @""
            };
        }
        if (completion) {
            completion(error, filePath, extraInfo);
        }
    }];
}

- (void)requestWithURLString:(NSString *)urlString
                  parameters:(NSDictionary *)parameters
                headerFields:(NSDictionary *)headerFields
                  httpMethod:(NSString *)httpMethod
                  completion:(void (^)(NSError *error, id result))completion {
    NSMutableDictionary *allHeaderFields = [NSMutableDictionary dictionaryWithDictionary:headerFields];
    if (self.preFetchHeaderFields.count > 0 && [self isPreFetchCompletionWithCompletionObject:completion]) {
        [allHeaderFields addEntriesFromDictionary:self.preFetchHeaderFields ?: @{}];
    }
    void(^wrapperCompletion)(NSError *error, id obj, TTHttpResponse *response) = ^(NSError *error, id obj, TTHttpResponse *response) {
        completion(error, obj);
    };
    BOOL isPost = [httpMethod isEqualToString:@"POST"];
    [[TTNetworkManager shareInstance] requestForJSONWithResponse:urlString
                                                          params:parameters
                                                          method:httpMethod
                                                needCommonParams:NO
                                                     headerField:allHeaderFields
                                               requestSerializer:isPost ? [IESEffectPlatformPostSerializer class] : nil
                                              responseSerializer:nil
                                                      autoResume:YES
                                                   verifyRequest:NO
                                              isCustomizedCookie:NO
                                                        callback:wrapperCompletion
                                            callbackInMainThread:NO];
}


@end


@implementation IESEffectPlatformRequestManager (PreFetch)

- (void)setPreFetchHeaderFieldsWithDictionary:(NSDictionary *)dictionary {
    self.preFetchHeaderFields = dictionary;
}

- (BOOL)isPreFetchCompletionWithCompletionObject:(id)object {
    if (!object || self.preFetchCompletionPointers.count <= 0) {
        return NO;
    }
    BOOL result = NO;
    @synchronized (self) {
        result = [[self.preFetchCompletionPointers allObjects] containsObject:object];
    }
    return result;
}

- (void)addPreFetchCompletionObject:(id)object {
    void *pointer = (__bridge void *)object;
    @synchronized (self) {
        [self.preFetchCompletionPointers addPointer:pointer];
    }
}

- (void)clearPreFetchInfos {
    self.preFetchHeaderFields = nil;
    @synchronized (self) {
        self.preFetchCompletionPointers = nil;
    }
}

@end
