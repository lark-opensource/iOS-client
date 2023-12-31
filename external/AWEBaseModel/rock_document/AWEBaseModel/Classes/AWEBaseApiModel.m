//
//  AWEBaseApiModel.m
//  Aweme
//
//  Created by HongTao on 2017/2/15.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "AWEBaseApiModel.h"
#import <AWELazyRegister/AWELazyRegisterPremain.h>
#import <ByteDanceKit/NSObject+BTDAdditions.h>

@implementation AWEBaseApiModel

AWELazyRegisterPremainClass(AWEBaseApiModel)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self btd_swizzleInstanceMethod:@selector(validateValue:forKey:error:) with:@selector(awe_validateValue:forKey:error:)];
        [self btd_swizzleInstanceMethod:@selector(validate:) with:@selector(awe_validate:)];
    });
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"statusCode"  : @"status_code",
             @"statusMsg"   : @"status_msg",
             @"requestID"   : @"_AME_Header_RequestID",
             @"timestamp"   : @"_AME_APICommonParam_Timestamp",
             @"logPassback" : @"log_pb",
             };
}

- (void)mergeAllPropertyKeysWithRequestIdAndLogPassback
{
    if (self.requestID || ([self.logPassback isKindOfClass:NSDictionary.class] && self.logPassback.count > 0)) {
        [self _mergeAllPropertyKeysWithRequestId:self.requestID logPassback:self.logPassback];
    }
}

- (void)_mergeAllPropertyKeysWithRequestId:(NSString *)requestID logPassback:(NSDictionary *)logPB
{
    self.requestID = requestID;
    self.logPassback = logPB;

    for (NSString *key in self.class.propertyKeys) {
        id value = [self valueForKey:key];
        if ([value isKindOfClass:NSArray.class]) {
            for (id obj in value) {
                if ([obj isKindOfClass:AWEBaseApiModel.class]) {
                    [obj _mergeAllPropertyKeysWithRequestId:requestID logPassback:logPB];
                }
            }
        }
        if ([value isKindOfClass:AWEBaseApiModel.class] ) {
            [value _mergeAllPropertyKeysWithRequestId:requestID logPassback:logPB];
        }
        if ([value conformsToProtocol:@protocol(AWEProcessRequestInfoProtocol)]) {
            [value processRequestID:requestID];
        }
    }
}

- (void)mergeAllPropertyKeysWithRequestId
{
    if (!self.requestID) {
        return;
    }
    [self _mergeAllPropertyKeysWithRequestId:[self.requestID copy]];
}

- (void)_mergeAllPropertyKeysWithRequestId:(NSString *)requestID
{
    self.requestID = requestID;
    
    for (NSString *key in self.class.propertyKeys) {
        id obj = [self valueForKey:key];
        if ([obj isKindOfClass:NSArray.class] ) {
            for (id obj2 in obj) {
                if ([obj2 isKindOfClass:AWEBaseApiModel.class]) {
                    [obj2 _mergeAllPropertyKeysWithRequestId:requestID];
                }
            }
        }
        if ([obj isKindOfClass:AWEBaseApiModel.class] ) {
            [obj _mergeAllPropertyKeysWithRequestId:requestID];
        }
        if ([obj conformsToProtocol:@protocol(AWEProcessRequestInfoProtocol)]) {
            [obj processRequestID:requestID];
        }
    }
}

- (void)mergeAllPropertyKeysWithLogPassback
{
    if ([self.logPassback isKindOfClass:[NSDictionary class]] && self.logPassback.count > 0) {
        [self _mergeAllPropertyKeysWithLogPassback:[self.logPassback copy]];
    }
}

- (void)_mergeAllPropertyKeysWithLogPassback:(NSDictionary *)logpb
{
    self.logPassback = logpb;

    for (NSString *key in self.class.propertyKeys) {
        id obj = [self valueForKey:key];
        if ([obj isKindOfClass:NSArray.class] ) {
            for (id obj2 in obj) {
                if ([obj2 isKindOfClass:AWEBaseApiModel.class]) {
                    [obj2 _mergeAllPropertyKeysWithLogPassback:logpb];
                }
            }
        }
        if ([obj isKindOfClass:AWEBaseApiModel.class] ) {
            [obj _mergeAllPropertyKeysWithLogPassback:logpb];
        }
    }
}

- (BOOL)awe_validateValue:(inout id  _Nullable __autoreleasing *)ioValue forKey:(NSString *)inKey error:(out NSError * _Nullable __autoreleasing *)outError
{
    return YES;
}

- (BOOL)awe_validate:(NSError *__autoreleasing *)error
{
    return YES;
}

@end

@implementation AWEBaseTTApiModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"statusCode" : @"code",
             @"requestID" : @"_AME_Header_RequestID",
             };
}

@end
