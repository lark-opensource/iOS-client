//
//  ACCBaseApiModel.m
//  ACCme
//
//  Created by HongTao on 2017/2/15.
//  Copyright  ©  Byedance. All rights reserved, 2017
//

#import "ACCBaseApiModel.h"
#import <objc/runtime.h>
#import <CreativeKit/NSObject+ACCSwizzle.h>


@implementation ACCBaseApiModel

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
                if ([obj2 isKindOfClass:ACCBaseApiModel.class]) {
                    [obj2 _mergeAllPropertyKeysWithRequestId:requestID];
                }
            }
        }
        if ([obj isKindOfClass:ACCBaseApiModel.class] ) {
            [obj _mergeAllPropertyKeysWithRequestId:requestID];
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
                if ([obj2 isKindOfClass:ACCBaseApiModel.class]) {
                    [obj2 _mergeAllPropertyKeysWithLogPassback:logpb];
                }
            }
        }
        if ([obj isKindOfClass:ACCBaseApiModel.class] ) {
            [obj _mergeAllPropertyKeysWithLogPassback:logpb];
        }
    }
}

- (BOOL)validateValue:(inout id  _Nullable __autoreleasing *)ioValue forKey:(NSString *)inKey error:(out NSError * _Nullable __autoreleasing *)outError
{
    return YES;
}

- (BOOL)validate:(NSError *__autoreleasing *)error
{
    return YES;
}

@end
