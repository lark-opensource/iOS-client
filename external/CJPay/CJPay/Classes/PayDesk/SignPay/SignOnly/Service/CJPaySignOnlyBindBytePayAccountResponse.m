//
//  CJPaySignOnlyBindBytePayAccountResponse.m
//  CJPay-1ab6fc20
//
//  Created by wangxiaohong on 2022/9/19.
//

#import "CJPaySignOnlyBindBytePayAccountResponse.h"

@implementation CJPaySignOnlyBindBytePayResultDesc

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *mutableDic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"signStatus": @"sign_status",
        @"signStatusDesc": @"sign_status_desc",
        @"serviceName": @"service_name",
        @"remainTime": @"remain_time",
        @"signFailReason": @"sign_fail_reason"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[mutableDic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPaySignOnlyBindBytePayAccountResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *mutableDic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"resultDesc": @"response.result_desc",
        @"remainLockDesc": @"response.remain_lock_desc",
        @"remainRetryCount": @"response.remain_retry_count",
    }];
    [mutableDic addEntriesFromDictionary:[super basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[mutableDic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
