//
//  BDStrategyRuleStore.m
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2021/12/10.
//

#import "BDStrategyRuleStore.h"

#import "NSDictionary+BDRESafe.h"
#import "BDStrategyCenterConstant.h"
#import "BDRuleParameterRegistry.h"
#import "BDREDiGraphBuilder.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>

@interface BDStrategyParseRuleStore : NSObject

@property (nonatomic, copy) NSDictionary<NSString *, BDRuleGroupModel *> *dict;
@property (nonatomic, strong) NSDictionary<NSString *, BDRuleModel *> *polices;

@end

@implementation BDStrategyParseRuleStore

- (void)updatePolicyMap:(NSDictionary *)policyMap strategies:(NSDictionary *)strategies
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSMutableDictionary *polices = [NSMutableDictionary dictionary];
    for (NSString *strategyName in strategies.allKeys) {
        if (![strategyName isKindOfClass:[NSString class]]) {
            continue;
        }
        
        //format: {"rulesName1":{"rules":["policyName1", "policyName2"]}, "rulesName2":...}
        NSDictionary *rawData = [strategies bdre_dictForKey:strategyName];
        NSArray *ruleNames = [rawData bdre_arrayForKey:BDStrategyRulesKey];
        if ([ruleNames count] == 0) {
            continue;
        }
        
        NSMutableArray<BDRuleModel *> *rules = [NSMutableArray arrayWithCapacity:ruleNames.count];
        for (NSString *policyName in ruleNames) {
            BDRuleModel *rule = [polices btd_objectForKey:policyName default:nil];
            if (!rule) {
                rule = [[BDRuleModel alloc] initWithDictionary:[policyMap bdre_dictForKey:policyName] key:policyName];
                [polices btd_setObject:rule forKey:policyName];
            }
            [rules btd_addObject:rule];
        }
        if (rules.count) {
            [result btd_setObject:[[BDRuleGroupModel alloc] initWithArray:rules name:strategyName] forKey:strategyName];
        }
    }
    self.polices = [NSDictionary dictionaryWithDictionary:polices];
    self.dict = [NSDictionary dictionaryWithDictionary:result];
}

- (void)clear
{
    self.dict = nil;
}

- (BDRuleGroupModel *)strategyRuleWithName:(NSString *)name
{
    return [self.dict objectForKey:name];
}

- (NSDictionary *)jsonFormat
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (NSString *key in self.dict) {
        BDRuleGroupModel *model = self.dict[key];
        result[key] = [model jsonFormat];
    }
    return @{
        BDStrategyListKey: [NSDictionary dictionaryWithDictionary:result]
    };
}

@end

@interface BDStrategyRuleStore ()

@property (nonatomic, assign) BOOL strategySelectBreak;
@property (nonatomic, assign) BOOL ruleExecBreak;
@property (nonatomic, strong) BDRuleGroupModel *strategyMapRuleModel;
@property (nonatomic, strong) BDREDiGraph *strategyMapGraph;
@property (nonatomic, strong) BDStrategyParseRuleStore *subStore;

@end

@implementation BDStrategyRuleStore

- (instancetype)init
{
    if (self = [super init]) {
        _strategySelectBreak = YES;
        _ruleExecBreak = YES;
        _subStore = [[BDStrategyParseRuleStore alloc] init];
    }
    return self;
}

- (void)clear
{
    self.strategySelectBreak = YES;
    self.ruleExecBreak = YES;
    self.strategyMapRuleModel = nil;
    [self.subStore clear];
}

- (void)loadCommandsAndEnableExecutor:(BOOL)enable
{
    for (BDRuleModel *rule in self.subStore.polices.allValues) {
        [rule loadCommandsAndEnableExecutor:enable];
    }
    for (BDRuleModel *rule in self.strategyMapRule.rules) {
        [rule loadCommandsAndEnableExecutor:enable];
    }
}

- (void)loadStrategySelectGraph
{
    self.strategyMapGraph = [BDREDiGraphBuilder graphWithRuleGroupModel:self.strategyMapRuleModel];
}

- (void)updateStrategies:(NSDictionary *)strategies
{
    [self clear];
    
    // policy
    NSDictionary *policies = [strategies bdre_dictForKey:BDStrategyPolicyKey];
    
    // strategy_map
    NSDictionary *strategyMap = [strategies bdre_dictForKey:BDStrategyMapKey];
    NSArray *strategyMapRules = [strategyMap bdre_arrayForKey:BDStrategyRulesKey];
    NSArray *strategyMapKeys = [strategyMap bdre_arrayForKey:BDStrategyKeysKey];
    
    // strategies
    NSDictionary *rawStrategies = [strategies bdre_dictForKey:BDStrategyListKey];
    
    // break
    NSNumber *strategySelectBreakNum = [strategies bdre_numberForKey:BDStrategySelectBreakKey];
    NSNumber *ruleExecBreakRawNum = [strategies bdre_numberForKey:BDStrategyRuleExecBreakKey];
    self.strategySelectBreak = strategySelectBreakNum ? [strategySelectBreakNum boolValue] : YES;
    self.ruleExecBreak = ruleExecBreakRawNum ? [ruleExecBreakRawNum boolValue] : YES;
    
    // const pool
    [self extractConstPool:[strategies bdre_dictForKey:BDStrategyConstPoolKey]];

    // final
    self.strategyMapRuleModel = [[BDRuleGroupModel alloc] initWithJsonArray:strategyMapRules name:BDStrategyMapKey keys:strategyMapKeys];
    [self.subStore updatePolicyMap:policies
                        strategies:rawStrategies];
}

- (void)extractConstPool:(NSDictionary *)constPool
{
    for (NSString *name in constPool.allKeys) {
        NSDictionary *dict = [constPool bdre_dictForKey:name];
        NSString *type = [dict bdre_stringForKey:BDStrategyConstPoolTypeKey];
        id value = nil;
        BDRuleParameterType parameterType = BDRuleParameterTypeUnknown;
        if ([type isEqualToString:BDStrategyConstPoolStringTypeKey]) {
            value = [dict bdre_stringForKey:BDStrategyConstPoolValueKey];
            parameterType = BDRuleParameterTypeString;
        } else if ([type isEqualToString:BDStrategyConstPoolStringArrayTypeKey] || [type isEqualToString:BDStrategyConstPoolIntArrayTypeKey]) {
            value = [dict bdre_arrayForKey:BDStrategyConstPoolValueKey];
            parameterType = BDRuleParameterTypeArray;
        }
        if (value) {
            [BDRuleParameterRegistry registerConstParameterWithKey:name type:parameterType builder:^id _Nonnull(id<BDRuleParameterBuilderProtocol> fetcher) {
                return value;
            }];
        }
    }
}

- (BDRuleGroupModel *)strategyMapRule
{
    return self.strategyMapRuleModel;
}

- (BDRuleGroupModel *)strategyRuleWithName:(NSString *)name
{
    return [self.subStore strategyRuleWithName:name];
}

- (NSDictionary *)jsonFormat
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[BDStrategyMapKey] = [self.strategyMapRuleModel jsonFormat];
    result[BDStrategySelectBreakKey]  = @(self.strategySelectBreak);
    result[BDStrategyRuleExecBreakKey]  = @(self.ruleExecBreak);
    [result addEntriesFromDictionary:[self.subStore jsonFormat]];
    return [NSDictionary dictionaryWithDictionary:result];
}

@end
