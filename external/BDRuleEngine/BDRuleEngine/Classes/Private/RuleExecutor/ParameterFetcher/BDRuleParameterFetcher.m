//
//  BDRuleParameterFetcher.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/26.
//

#import "BDRuleParameterFetcher.h"
#import "BDRuleParameterBuilder.h"
#import "BDRuleEngineLogger.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface BDRuleParameterFetcher()

@property (nonatomic, copy) NSDictionary *extraParameters;
@property (nonatomic, strong) BDRuleParameterBuilder *builder;
@property (nonatomic, strong) NSMutableDictionary *cachedParameters;
@property (nonatomic, assign) CFTimeInterval cost;

@end

@implementation BDRuleParameterFetcher

- (instancetype)initWithExtraParameters:(NSDictionary *)extraParameters
{
    self = [super init];
    if (self) {
        _extraParameters = extraParameters;
        _cachedParameters = [[NSMutableDictionary alloc] init];
        _builder = [[BDRuleParameterBuilder alloc] init];
        _cost = 0;
    }
    return self;
}

- (void)resetCost
{
    _cost = 0;
}

- (CFTimeInterval)cost
{
    return _cost;
}

- (NSDictionary *)usedParameters
{
    return [_cachedParameters copy];
}

- (id)envValueOfKey:(NSString *)key
{
    CFAbsoluteTime current = CFAbsoluteTimeGetCurrent();
    NSError *error;
    id value = [self getParameterWithKey:key error:&error];
    if (error) {
        [BDRuleEngineLogger error:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[ParameterFetcher] fetch parameter with error [%ld], msg [%@]", error.code, error.localizedDescription ?: @""];
        }];
    }
    CFTimeInterval cost = (CFAbsoluteTimeGetCurrent() - current) * 1000000;
    _cost += cost;
    return value;
}

- (id)getParameterWithKey:(NSString *)key error:(NSError **)error
{
    if (key.length == 0) {
        [BDRuleEngineLogger error:^NSString * _Nonnull{
            return @"[ParameterFetcher] fetch parameter with empty key";
        }];
        NSAssert(NO, @"key cannot be null");
        return nil;
    }
    id value = _cachedParameters[key];
    NSString *valueFrom = @"";
    if (!value) {
        value = [_builder generateValueFor:key extra:_extraParameters error:error];
        if (_extraParameters[key] && value) {
            [BDRuleEngineLogger error:^NSString * _Nonnull{
                return [NSString stringWithFormat:@"[ParameterFetcher] parameter conflicts [%@]" , key ?: @""];
            }];
            NSAssert(NO, @"[RuleEngine] parameter conflicts");
        }
        if (!value) {
            value = _extraParameters[key];
            valueFrom = @"input";
        } else {
            valueFrom = @"environment";
        }
        if (value) {
            _cachedParameters[key] = value;
        }
    } else {
        valueFrom = @"cache";
    }
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        NSString *valueDesc = @"";
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
            valueDesc = [value btd_jsonStringEncoded];
        } else {
            valueDesc = [value description];
        }
        return [NSString stringWithFormat:@"[ParameterFetcher] fetch parameter from %@ [%@ = %@]" , valueFrom, key ?: @"", valueDesc ?: @""];
    }];
    return value;
}

@end
