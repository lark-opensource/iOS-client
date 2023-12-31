//
//  CJPayVerifyPassCodeResponse.m
//  CJPay
//
//  Created by 王新华 on 2019/5/22.
//

#import "CJPayVerifyPassCodeResponse.h"

@implementation CJPayVerifyPassCodeResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *mutableDic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"remainRetryCount": @"response.remain_retry_count",
        @"remainLockDesc": @"response.remain_lock_desc",
        @"remainLockTime": @"response.remain_lock_time",
    }];
    [mutableDic addEntriesFromDictionary:[super basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[mutableDic copy]];
}

@end
