//
//  BDRuleExecutorResultModel.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/25.
//

#import "BDRuleResultModel.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>

@implementation BDSingleRuleResult

- (NSDictionary *)jsonFormat
{
    return @{
        @"key": _key ?: @"",
        @"conf": _conf ?: @""
    };
}

- (NSString *)description
{
    return [[self jsonFormat] btd_jsonStringEncoded];
}

@end

@implementation BDRuleResultModel

- (instancetype)initWithUUID:(NSString *)uuid
{
    self = [super init];
    if (self){
        _uuid = uuid;
    }
    return self;
}

- (BDSingleRuleResult *)value
{
    return _values.firstObject;
}

- (NSString *)description
{
    NSMutableArray *desc = [NSMutableArray array];
    for (BDSingleRuleResult *result in _values) {
        [desc btd_addObject:result.description];
    }
    return [[desc copy] btd_jsonStringEncoded];
}

+ (instancetype)instanceWithError:(NSError *)error uuid:(nonnull NSString *)uuid
{
    BDRuleResultModel *model = [[BDRuleResultModel alloc] initWithUUID:uuid];
    model.engineError = error;
    return model;
}

@end
