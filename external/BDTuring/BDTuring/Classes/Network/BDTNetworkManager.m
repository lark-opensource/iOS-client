//
//  BDTNetworkManager.m
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import "BDTNetworkManager.h"

NSString * const kBDTuringHeaderContentType      = @"Content-Type";
NSString * const kBDTuringHeaderAccept           = @"Accept";
NSString * const kBDTuringHeaderConnection       = @"Connection";

NSString * const BDTuringHeaderContentTypeJSON   = @"application/json; encoding=utf-8";
NSString * const BDTuringHeaderContentTypeData   = @"application/octet-stream;tt-data=a";
NSString * const BDTuringHeaderAccept            = @"application/json";
NSString * const BDTuringHeaderConnection        = @"keep-alive";

NSString * const kBDTuringHeaderSDKVersion   = @"x-vc-bdturing-sdk-version";
NSString * const kBDTuringHeaderSDKParameters = @"bdturing-verify";

@implementation BDTNetworkManager

+ (instancetype)sharedInstance {
    static BDTNetworkManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

/// for category to override
- (void)setup {
    NSCAssert(NO, @"Please use BDTuring/TTNet subspec");
}

- (NSDictionary *)createTaggedHeaderFieldWith:(NSDictionary *)headerField type:(BDTNetworkTagType)type {
    return headerField;
}

- (void)asyncRequestForURL:(NSString *)requestURL
                    method:(NSString *)method
           queryParameters:(nullable NSDictionary *)queryParameters
            postParameters:(nullable NSDictionary *)postParameters
                  callback:(BDTuringNetworkFinishBlock)callback
             callbackQueue:(nullable dispatch_queue_t)queue
                   encrypt:(BOOL)encrypt
                   tagType:(BDTNetworkTagType)type {
    NSCAssert(NO, @"Please use BDTuring/TTNet subspec");
}

- (void)tvRequestForJSONWithResponse:(NSString *)requestURL
                              params:(id)params
                              method:(NSString *)method
                    needCommonParams:(BOOL)commonParams
                         headerField:(NSDictionary *)headerField
                            callback:(BDTuringTwiceVerifyNetworkFinishBlock)callback
                             tagType:(BDTNetworkTagType)type {
    NSCAssert(NO, @"Please use BDTuring/TTNet subspec");
}

- (void)uploadEvent:(NSString *)key param:(NSDictionary *)param {
    NSCAssert(NO, @"Please use BDTuring/TTNet subspec");
}

- (NSString *)networkType {
    NSCAssert(NO, @"Please use BDTuring/TTNet subspec");
    return nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

+ (void)asyncRequestForURL:(NSString *)requestURL
                    method:(NSString *)method
           queryParameters:(NSDictionary *)queryParameters
            postParameters:(NSDictionary *)postParameters
                  callback:(BDTuringNetworkFinishBlock)callback
             callbackQueue:(dispatch_queue_t)queue
                   encrypt:(BOOL)encrypt
                   tagType:(BDTNetworkTagType)type{
    if (callback == nil) {
        NSCAssert(NO, @"callback should not be nil");
        return;
    }
    
    id<BDTNetworkManagerImp> imp = [BDTNetworkManager sharedInstance];
    if (imp) {
        [imp asyncRequestForURL:requestURL
                         method:method
                queryParameters:queryParameters
                 postParameters:postParameters
                       callback:callback
                  callbackQueue:queue
                        encrypt:encrypt
                        tagType:type];
    }
}

+ (void)tvRequestForJSONWithResponse:(NSString *)requestURL
                              params:(id)params
                              method:(NSString *)method
                    needCommonParams:(BOOL)commonParams
                         headerField:(NSDictionary *)headerField
                            callback:(BDTuringTwiceVerifyNetworkFinishBlock)callback
                             tagType:(BDTNetworkTagType)type{
    if (callback == nil) {
        NSCAssert(NO, @"callback should not be nil");
        return;
    }

    id<BDTNetworkManagerImp> imp = [BDTNetworkManager sharedInstance];
    if (imp) {
        [imp tvRequestForJSONWithResponse:requestURL
                                   params:params
                                   method:method
                         needCommonParams:commonParams
                              headerField:headerField
                                 callback:callback
                                  tagType:type];
    }
}


+ (void)uploadEvent:(NSString *)key param:(NSDictionary *)param {
    [[BDTNetworkManager sharedInstance] uploadEvent:key param:param];
}

+ (NSString *)networkType {
    return [[BDTNetworkManager sharedInstance] networkType];
}

@end
