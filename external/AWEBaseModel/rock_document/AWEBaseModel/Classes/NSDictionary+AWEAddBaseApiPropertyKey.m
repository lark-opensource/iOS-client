//
//  NSDictionary+AWEAddBaseApiPropertyKey.m
//  AFgzipRequestSerializer
//
//  Created by li keliang on 2018/9/29.
//

#import "NSDictionary+AWEAddBaseApiPropertyKey.h"
#import "AWEBaseApiModel.h"
#import "AWEURLModel.h"

@implementation NSDictionary (AWEAddBaseApiPropertyKey)

- (NSDictionary *)apiPropertyKey
{
    NSMutableDictionary *dic = [[AWEBaseApiModel JSONKeyPathsByPropertyKey] mutableCopy];
    [dic addEntriesFromDictionary:self];
    return dic;
}

- (NSDictionary *)urlModelPropertykey
{
    NSMutableDictionary *dic = [[AWEURLModel JSONKeyPathsByPropertyKey] mutableCopy];
    [dic addEntriesFromDictionary:self];
    return [dic copy];
}

@end
