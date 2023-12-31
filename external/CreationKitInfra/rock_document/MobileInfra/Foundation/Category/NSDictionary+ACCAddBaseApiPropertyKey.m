//
//  NSDictionary+ACCAddBaseApiPropertyKey.m
//  AFgzipRequestSerializer
//
//  Created by li keliang on 2018/9/29.
//

#import "NSDictionary+ACCAddBaseApiPropertyKey.h"
#import "ACCBaseApiModel.h"

@implementation NSDictionary (ACCAddBaseApiPropertyKey)

- (NSDictionary *)acc_apiPropertyKey
{
    NSMutableDictionary *dic = [[ACCBaseApiModel JSONKeyPathsByPropertyKey] mutableCopy];
    [dic addEntriesFromDictionary:self];
    return dic;
}

@end
