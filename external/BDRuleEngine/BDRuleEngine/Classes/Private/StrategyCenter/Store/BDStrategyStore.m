//
//  BDStrategyStore.m
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2021/12/10.
//

#import "BDStrategyStore.h"

#import "BDStrategyRuleStore.h"
#import "BDStrategyCenterConstant.h"
#import "BDRuleEngineKVStore.h"
#import "BDRuleEngineSettings.h"
#import "NSDictionary+BDRESafe.h"
#import "BDRuleEngineReporter.h"
#import "BDREExprRunner.h"
#import "BDREInstruction.h"
#import "BDStrategyProviderManager.h"
#import "BDREInstructionCacheManager.h"
#import "BDStrategySelectCacheManager.h"
#import "BDREDiGraph.h"

#import <pthread/pthread.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>

static NSString * const kBDStrategyStore    = @"com.bd.ruleengine.strategy_store";
static NSString * const kBDStrategyStoreKey = @"strategy_store";

@interface BDStrategyStore ()

@property (nonatomic, strong) NSDictionary<NSString *, BDStrategyRuleStore *> *strategiesMap;
@property (nonatomic, copy) NSString *signature;

@end

@implementation BDStrategyStore

static dispatch_queue_t updateStrategyQueue() {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("queue-BDRuleEngineUpdateStrategy", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

static dispatch_queue_t loadStrategyQueue() {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("queue-BDRuleEngineLoadStrategy", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

- (void)preprocessStrategy:(NSDictionary *)strategy
{
    if (![BDRuleEngineSettings enableInstructionList]) {
        return;
    }
    @weakify(self);
    dispatch_async(updateStrategyQueue(), ^{
        @strongify(self);
        [self __preprocessStrategy:strategy];
    });
}

- (void)loadStrategy:(NSDictionary *)strategy
{
    if (self.strategiesMap) {
        return;
    }
    @weakify(self);
    dispatch_async(loadStrategyQueue(), ^{
        @strongify(self);
        [self __loadStrategy:strategy];
    });
}

- (void)__loadStrategy:(NSDictionary *)strategy
{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    // 解析策略
    self.signature = [strategy bdre_stringForKey:BDStrategySignatureKey];
    self.strategiesMap = [self parseStrategy:strategy];
    
    CFTimeInterval costTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000000;
    [BDRuleEngineReporter delayLog:BDRELogNameRulerStart tags:@{BDRELogSampleTagSourceKey : BDRELogStartEventSourceValue} block:^id<BDRuleEngineReportDataSource> _Nonnull{
        return [[BDREReportContent alloc] initWithMetric:@{
            @"cost"      : @(costTime)
        } category:@{
            @"event_name": @"rule_engine_update_strategy"
        } extra:nil];
    }];
    
    // 策略选取缓存加载
    if ([BDRuleEngineSettings enableCacheSelectStrategy]) {
        NSString *signature = [strategy btd_stringValueForKey:BDStrategySignatureKey default:@""];
        if (![signature isEqualToString:[BDStrategySelectCacheManager signature]]) {
            [BDStrategySelectCacheManager loadStrategySelectCacheWithMD5Map:[self strategyMapRuleMD5Map] signature:signature];
        } else {
            [BDStrategySelectCacheManager loadStrategySelectCache];
        }
    }
    // 指令队列与快速执行器
    if ([BDRuleEngineSettings enableInstructionList]) {
        // 加载指令队列
        for(BDStrategyRuleStore *store in self.strategiesMap.allValues) {
            [store loadCommandsAndEnableExecutor:[BDRuleEngineSettings enableQuickExecutor]];
        }
        // 解析指令队列
        [self __preprocessStrategy:strategy];
    }
    // 快速策略选取
    if ([BDRuleEngineSettings enableFFF]) {
        for(BDStrategyRuleStore *store in self.strategiesMap.allValues) {
            [store loadStrategySelectGraph];
        }
    }
}

- (void)__preprocessStrategy:(NSDictionary *)strategy
{
    NSString *signature = [strategy bdre_stringForKey:BDStrategySignatureKey];
    if ([signature isEqualToString:[BDREInstructionCacheManager sharedManager].signature]) {
        return;
    }
    NSDictionary *rawSetData = [strategy btd_dictionaryValueForKey:BDStrategySetKey];
    NSMutableDictionary *instructionJsonMap = [NSMutableDictionary dictionary];
    for (NSDictionary *rawStrategies in rawSetData.allValues) {
        // policies
        NSDictionary *policies = [rawStrategies bdre_dictForKey:BDStrategyPolicyKey];
        for (NSDictionary *rule in policies.allValues) {
            [instructionJsonMap btd_setObject:[self findInstructionInRule:rule] forKey:[rule bdre_stringForKey:@"cel"]];
        }
        // strategy_map
        NSDictionary *strategyMap = [rawStrategies bdre_dictForKey:BDStrategyMapKey];
        NSArray *strategyMapRules = [strategyMap bdre_arrayForKey:BDStrategyRulesKey];
        for (NSDictionary *rule in strategyMapRules) {
            [instructionJsonMap btd_setObject:[self findInstructionInRule:rule] forKey:[rule bdre_stringForKey:@"cel"]];
        }
    }
    [[BDREInstructionCacheManager sharedManager] updateInstructionJsonMap:[instructionJsonMap copy] signature:signature];
}

- (NSArray *)findInstructionInRule:(NSDictionary *)rule
{
    NSString *cel = [rule bdre_stringForKey:@"cel"];
    NSArray *il = [rule bdre_arrayForKey:@"il"];
    if (!il) {
        NSArray *commands = [[BDREInstructionCacheManager sharedManager] findCommandsForExpr:cel] ?: [[BDREExprRunner sharedRunner] commandsFromExpr:cel];
        il = [BDRECommand instructionJsonArrayWithCommands:commands];
    }
    return il;
}

- (NSDictionary<NSString *, BDStrategyRuleStore *> *)parseStrategy:(NSDictionary *)strategy
{
    NSDictionary *rawSetData = [strategy btd_dictionaryValueForKey:BDStrategySetKey];
    NSMutableDictionary *strategies = [NSMutableDictionary dictionaryWithCapacity:rawSetData.allKeys.count];
        
    for (NSString *setName in rawSetData.allKeys) {
        NSDictionary *rawStrategies = [rawSetData btd_objectForKey:setName default:@{}];
        BDStrategyRuleStore *strategyStore = [[BDStrategyRuleStore alloc] init];
        [strategyStore updateStrategies:rawStrategies];
        [strategies btd_setObject:strategyStore forKey:setName];
    }
    
    return [strategies copy];
}

- (NSDictionary *)strategyMapRuleMD5Map
{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (NSString *setName in self.strategiesMap.allKeys) {
        BDStrategyRuleStore *ruleStore = [self.strategiesMap objectForKey:setName];
        BDRuleGroupModel *groupModel = ruleStore.strategyMapRule;
        NSDictionary *md5RawDict = @{
            BDStrategySelectBreakKey : @(ruleStore.strategySelectBreak),
            BDStrategyRulesKey : groupModel.rawJsonArray ?: @[]
        };
        NSString *md5 = [[md5RawDict  btd_jsonStringEncoded] btd_md5String];
        [result btd_setObject:md5 forKey:setName];
    }
    CFTimeInterval costTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000000;
    [BDRuleEngineReporter delayLog:BDRELogNameRulerStart tags:@{BDRELogSampleTagSourceKey : BDRELogStartEventSourceValue} block:^id<BDRuleEngineReportDataSource> _Nonnull{
        return [[BDREReportContent alloc] initWithMetric:@{
            @"cost"      : @(costTime)
        } category:@{
            @"event_name": @"rule_engine_strategy_map_rule_md5"
        } extra:nil];
    }];
    return [result copy];
}

- (BOOL)strategySelectBreakInSet:(NSString *)setName
{
    BDStrategyRuleStore *ruleStore = [self storeWithName:setName];
    return [ruleStore strategySelectBreak];
}

- (BOOL)ruleExecBreakInSet:(NSString *)setName
{
    BDStrategyRuleStore *ruleStore = [self storeWithName:setName];
    return [ruleStore ruleExecBreak];
}

- (nullable NSArray *)strategyMapKeysInSet:(NSString *)setName
{
    BDRuleGroupModel *strategyMapRule = [[self storeWithName:setName] strategyMapRule];
    return strategyMapRule ? strategyMapRule.keys : nil;
}

- (BDRuleGroupModel *)strategyMapRuleInSet:(NSString *)setName
{
    BDStrategyRuleStore *ruleStore = [self storeWithName:setName];
    return [ruleStore strategyMapRule];
}

- (BDREDiGraph *)strategyMapGraphInSet:(NSString *)setName
{
    BDStrategyRuleStore *ruleStore = [self storeWithName:setName];
    return [ruleStore strategyMapGraph];
}

- (BDRuleGroupModel *)strategyRuleWithName:(NSString *)name inSet:(NSString *)setName
{
    BDStrategyRuleStore *ruleStore = [self storeWithName:setName];
    return [ruleStore strategyRuleWithName:name];
}

- (BDStrategyRuleStore *)storeWithName:(NSString *)name
{
    return [self.strategiesMap objectForKey:name];
}

- (NSDictionary *)jsonFormat
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *key in self.strategiesMap.allKeys) {
        BDStrategyRuleStore *subStore = self.strategiesMap[key];
        dict[key] = [subStore jsonFormat];
    }
    
    return @{
        BDStrategySignatureKey: self.signature ?: @"",
        BDStrategySetKey: [NSDictionary dictionaryWithDictionary:dict]
    };
}

@end
