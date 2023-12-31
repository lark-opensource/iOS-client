//
//  BDRuleParameterRegistry.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/29.
//

#import "BDRuleParameterRegistry.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface BDRuleParameterRegistry()
@property (nonatomic, strong) NSMutableDictionary<NSString *,BDRuleParameterBuilderModel*> *registryMap;
@end

@implementation BDRuleParameterRegistry

+ (instancetype)sharedInstance
{
    static BDRuleParameterRegistry *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDRuleParameterRegistry alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _registryMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Public
+ (void)registerParameterWithKey:(NSString *)key
                            type:(BDRuleParameterType)type
                         builder:(BDRuleParameterBuildBlock)builder
{
    [[BDRuleParameterRegistry sharedInstance] __registerParameterWithKey:key origin:BDRuleParameterOriginState type:type builder:builder];
}

+ (void)registerConstParameterWithKey:(nonnull NSString *)key
                                 type:(BDRuleParameterType)type
                              builder:(nonnull BDRuleParameterBuildBlock)builder
{
    [[BDRuleParameterRegistry sharedInstance] __registerParameterWithKey:key origin:BDRuleParameterOriginConst type:type builder:builder];
}

+ (BDRuleParameterBuilderModel *)builderForKey:(NSString *)key
{
    return [[BDRuleParameterRegistry sharedInstance] __builderForKey:key];
}

+ (NSArray<BDRuleParameterBuilderModel *> *)allParameters
{
    return [[[BDRuleParameterRegistry sharedInstance] registryMap] allValues];
}

+ (NSArray<BDRuleParameterBuilderModel *> *)stateParameters
{
    NSDictionary *filterMap = [[[BDRuleParameterRegistry sharedInstance] registryMap] btd_filter:^BOOL(NSString * _Nonnull key, BDRuleParameterBuilderModel * _Nonnull obj) {
        return obj.origin == BDRuleParameterOriginState;
    }];
    return [filterMap allValues];
}

+ (NSArray<BDRuleParameterBuilderModel *> *)constParameters
{
    NSDictionary *filterMap = [[[BDRuleParameterRegistry sharedInstance] registryMap] btd_filter:^BOOL(NSString * _Nonnull key, BDRuleParameterBuilderModel * _Nonnull obj) {
        return obj.origin == BDRuleParameterOriginConst;
    }];
    return [filterMap allValues];
}

#pragma mark - Private
- (void)__registerParameterWithKey:(NSString *)key
                            origin:(BDRuleParameterOrigin)origin
                              type:(BDRuleParameterType)type
                           builder:(BDRuleParameterBuildBlock)builder
{
    if (!key || key.length == 0) {
        NSAssert(NO, @"key can not be empty");
        return;
    }
    BDRuleParameterBuilderModel *oldModel = _registryMap[key];
    if (oldModel && oldModel.origin != BDRuleParameterOriginConst) {
        NSAssert(NO, @"key is registered already");
        return;
    }
    BDRuleParameterBuilderModel *model = [[BDRuleParameterBuilderModel alloc] init];
    model.key = key;
    model.origin = origin;
    model.type = type;
    model.builder = [builder copy];
    _registryMap[key] = model;
}

- (BDRuleParameterBuilderModel *)__builderForKey:(NSString *)key
{
    if (!key || key.length == 0) {
        return nil;
    }
    return _registryMap[key];
}

@end
