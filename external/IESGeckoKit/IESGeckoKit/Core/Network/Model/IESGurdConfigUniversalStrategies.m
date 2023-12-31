//
//  IESGurdConfigUniversalStrategies.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/10/25.
//

#import "IESGurdConfigUniversalStrategies.h"

@implementation IESGurdConfigSpecifiedClean

+ (instancetype _Nullable)cleanWithDictionary:(NSDictionary *)dictionary
{
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    IESGurdSpecifiedCleanType cleanType = [dictionary[@"clean_type"] integerValue];
    if (cleanType == IESGurdSpecifiedCleanTypeUnknown) {
        return nil;
    }
    NSString *channel = dictionary[@"c"];
    if (channel.length == 0) {
        return nil;
    }
    NSArray *versions = dictionary[@"version"];
    if (versions && ![versions isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    IESGurdConfigSpecifiedClean *clean = [[self alloc] init];
    clean.cleanType = cleanType;
    clean.channel = channel;
    clean.versions = versions;
    return clean;
}

- (BOOL)shouldCleanWithVersion:(int64_t)version
{
    if (version == 0) {
        return NO;
    }
    BOOL shouldClean = NO;
    IESGurdSpecifiedCleanType cleanType = self.cleanType;
    if (cleanType == IESGurdSpecifiedCleanTypeNoMatter) {
        shouldClean = YES;
    } else if (cleanType == IESGurdSpecifiedCleanTypeMatch) {
        shouldClean = [self.versions containsObject:@(version)];
    } else if (cleanType == IESGurdSpecifiedCleanTypeLessThan) {
        shouldClean = self.versions.firstObject.longLongValue > version;
    }
    return shouldClean;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"type(%zd) channel(%@) versions(%@)", self.cleanType, self.channel, self.versions];
}

@end

@implementation IESGurdConfigGroupClean

+ (instancetype _Nullable)cleanWithDictionary:(NSDictionary *)dictionary
{
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    IESGurdConfigGroupClean *clean = [[self alloc] init];
    clean.rule = [dictionary[@"rule"] integerValue];
    clean.policy = [dictionary[@"policy"] integerValue];
    clean.limit = [dictionary[@"limit"] integerValue];
    return clean;
}

@end

@implementation IESGurdConfigUniversalStrategies

+ (instancetype _Nullable)strategiesWithDictionary:(NSDictionary *)dictionary
{
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    IESGurdConfigUniversalStrategies *strategies = [[self alloc] init];
    
    NSArray *specifiedClean = dictionary[@"specified_clean"];
    if ([specifiedClean isKindOfClass:[NSArray class]]) {
        if (specifiedClean.count > 0) {
            NSMutableArray<IESGurdConfigSpecifiedClean *> *specifiedCleanArray = [NSMutableArray array];
            [specifiedClean enumerateObjectsUsingBlock:^(NSDictionary *dic, NSUInteger idx, BOOL *stop) {
                IESGurdConfigSpecifiedClean *specifiedClean = [IESGurdConfigSpecifiedClean cleanWithDictionary:dic];
                if (specifiedClean) {
                    [specifiedCleanArray addObject:specifiedClean];
                }
            }];
            strategies.specifiedCleanArray = [specifiedCleanArray copy];
        }
    }
    
    strategies.groupClean = [IESGurdConfigGroupClean cleanWithDictionary:dictionary[@"group_clean"]];
    
    return strategies;
}

+ (instancetype _Nullable)strategiesWithPackageDictionary:(NSDictionary *)dictionary
{
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    IESGurdConfigUniversalStrategies *strategies = [[self alloc] init];

    NSMutableArray<IESGurdConfigSpecifiedClean *> *specifiedCleanArray = [NSMutableArray array];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *channel, NSNumber *version, BOOL *stop) {
        IESGurdConfigSpecifiedClean *clean = [[IESGurdConfigSpecifiedClean alloc] init];
        clean.cleanType = IESGurdSpecifiedCleanTypeMatch;
        clean.channel = channel;
        clean.versions = @[version];
        [specifiedCleanArray addObject:clean];
    }];
    strategies.specifiedCleanArray = [specifiedCleanArray copy];
    
    return strategies;
}

@end
