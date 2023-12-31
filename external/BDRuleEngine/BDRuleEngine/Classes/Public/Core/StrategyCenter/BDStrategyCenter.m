//
//  BDStrategyCenter.m
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2021/12/10.
//

#import "BDStrategyCenter.h"
#import "BDRuleEngineSettings.h"
#import "BDRuleEngineReporter.h"
#import "BDRuleEngineDelegate.h"
#import "BDStrategyUpdateProtocol.h"
#import "BDStrategyProvider.h"
#import "BDStrategyProviderManager.h"
#import "BDStrategySelectCacheManager.h"
#import "BDStrategyStore.h"
#import "BDRuleExecutor.h"
#import "NSDictionary+BDRESafe.h"
#import "BDStrategyCenterConstant.h"
#import "BDRuleEngineErrorConstant.h"
#import "BDRuleEngineLogger.h"
#import "BDStrategyCenterUtil.h"
#import "BDRuleModel+Precache.h"
#import "BDRuleEngineDelegateCenter.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface RunnerContext: NSObject

@property (nonatomic, strong) BDRuleExecutor *executor;
@property (nonatomic, strong) NSDictionary *inputParams;
@property (nonatomic, assign) BOOL strategySelectHitCache;
@property (nonatomic, assign) BOOL strategySelectFromGraph;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, assign) CFTimeInterval startSelectStrategyTime;

- (instancetype)initWithParams:(NSDictionary *)params;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

@implementation RunnerContext

- (instancetype)initWithParams:(NSDictionary *)params
{
    if (self = [super init]) {
        _executor = [[BDRuleExecutor alloc] initWithParameters:params];
        _inputParams = params;
        _strategySelectHitCache = NO;
        _strategySelectFromGraph = NO;
        _startTime = CFAbsoluteTimeGetCurrent();
        _startSelectStrategyTime = CFAbsoluteTimeGetCurrent();
    }
    return self;
}

@end

@interface BDStrategyCenter ()<BDStrategyUpdateProtocol>

@property (nonatomic, strong) BDStrategyStore *store;
@property (nonatomic, strong) BDStrategyProviderManager *providerCenter;

@end

@implementation BDStrategyCenter

+ (void)registerStrategyProvider:(id<BDStrategyProvider>)provider
{
    [[BDStrategyCenter sharedInstance].providerCenter registerStrategyProvider:provider];
}

+ (void)setupWithDelegate:(id<BDRuleEngineDelegate>)delegate
{
    [BDRuleEngineDelegateCenter setDelegate:delegate];
    if ([BDRuleEngineSettings enablePrecacheCel] && ![BDRuleEngineSettings enableInstructionList]) {
        [BDRuleModel preload];
    }
    [[BDStrategyCenter sharedInstance].store loadStrategy:[[BDStrategyCenter sharedInstance].providerCenter fetchStrategy]];
}

+ (BDRuleResultModel *)validateParams:(NSDictionary *)params
{
    return [[BDStrategyCenter sharedInstance] validateParams:params];
}

+ (BDRuleResultModel *)validateParams:(NSDictionary *)params source:(NSString *)source
{
    return [[BDStrategyCenter sharedInstance] validateParams:params source:source];
}

+ (BDRuleResultModel *)validateParams:(NSDictionary *)params source:(NSString *)source strategyNames:(NSArray *)strategyNames
{
    return [[BDStrategyCenter sharedInstance] validateParams:params source:source strategyNames:strategyNames];
}

+ (BDStrategyResultModel *)generateStrategiesInSource:(NSString *)source params:(NSDictionary *)params
{
    return [[BDStrategyCenter sharedInstance] generateStrategiesInSource:source params:params];
}

#pragma mark - BDStrategyUpdateProtocol
- (void)preprocessStrategy:(NSDictionary *)strategy
{
    [self.store preprocessStrategy:strategy];
}

#pragma mark - private
+ (instancetype)sharedInstance {
    static BDStrategyCenter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDStrategyCenter alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _providerCenter = [BDStrategyProviderManager new];
        _providerCenter.delegate = self;
        _store = [BDStrategyStore new];
    }
    return self;
}

#pragma mark - private first level
- (BDRuleResultModel *)validateParams:(NSDictionary *)params
{
    if (![BDRuleEngineSettings enableRuleEngine]) {
        return nil;
    }
    // execute rule engine
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[StrategyCenter] start execute rule engine with params: %@", [params description] ?: @""];
    }];
    BDRuleResultModel *result = [self _validateParams:params];
    // log result
    [self logExecuteRuleEngineResult:result withInputParams:params];
    [self debugLogExecuteRuleEngineResult:result];
    return result;
}

- (BDRuleResultModel *)validateParams:(NSDictionary *)params source:(NSString *)source
{
    if (![BDRuleEngineSettings enableRuleEngine]) {
        return nil;
    }
    // execute rule engine
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[StrategyCenter] start execute rule engine with source: %@ params: %@", source ?: @"", [params description] ?: @""];
    }];
    BDRuleResultModel *result = [self _validateParams:params source:source];
    // log result
    NSMutableDictionary *logParams = params.mutableCopy;
    logParams[@"source"] = source ?: @"";
    [self logExecuteRuleEngineResult:result withInputParams:logParams.copy];
    [self debugLogExecuteRuleEngineResult:result];
    return result;
}

- (BDRuleResultModel *)validateParams:(NSDictionary *)params source:(NSString *)source strategyNames:(NSArray *)strategyNames
{
    if (![BDRuleEngineSettings enableRuleEngine]) {
        return nil;
    }
    // execute rule engine
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[StrategyCenter] start execute rule engine with source: %@ strategyNames: %@ params: %@", source ?: @"", [strategyNames btd_jsonStringEncoded] ?: @"", [params description] ?: @""];
    }];
    BDRuleResultModel *result = [self _validateParams:params source:source strategyNames:strategyNames];
    // log result
    NSMutableDictionary *logParams = params.mutableCopy;
    logParams[@"source"] = source ?: @"";
    [self logExecuteRuleEngineResult:result withInputParams:logParams.copy];
    [self debugLogExecuteRuleEngineResult:result];
    return result;
}

- (BDStrategyResultModel *)generateStrategiesInSource:(NSString *)source params:(NSDictionary *)params
{
    if (![BDRuleEngineSettings enableRuleEngine]) {
        return nil;
    }
    // execute rule engine
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[StrategyCenter] start execute strategies select in source: %@ with params: %@", source ?: @"", [params description] ?: @""];
    }];
    BDStrategyResultModel *result = [self _generateStrategiesInSource:source params:params];
    // log result
    NSMutableDictionary *logParams = params.mutableCopy;
    logParams[@"source"] = source ?: @"";
    [self logExecuteStrategiesSelectResult:result withSource:source inputParams:logParams.copy];
    if (result.engineError) {
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[StrategyCenter] end execute strategies select with error %ld, %@", [result.engineError code], [result.engineError localizedDescription] ?: @""];
        }];
    } else {
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[StrategyCenter] end execute rule engine with result %@", [result description] ?: @""];
        }];
    }
    return result;
}

#pragma mark - private second level

- (BDRuleResultModel *)_validateParams:(NSDictionary *)params
{
    RunnerContext *context = [[RunnerContext alloc] initWithParams:params];
    return [self __validateParams:params context:context];
}

- (BDRuleResultModel *)_validateParams:(NSDictionary *)params
                                source:(NSString *)source
{
    RunnerContext *context = [[RunnerContext alloc] initWithParams:params];
    return [self __validateParams:params source:source context:context];
}

- (BDRuleResultModel *)_validateParams:(NSDictionary *)params source:(NSString *)source strategyNames:(NSArray *)strategyNames
{
    RunnerContext *context = [[RunnerContext alloc] initWithParams:params];
    return [self __validateParams:params source:source strategyNames:strategyNames context:context];
}

- (BDStrategyResultModel *)_generateStrategiesInSource:(NSString *)setName params:(NSDictionary *)params
{
    RunnerContext *context = [[RunnerContext alloc] initWithParams:params];
    return [self __generateStrategiesInSource:setName params:params context:context];
}

#pragma mark - private third level

- (BDRuleResultModel *)__validateParams:(NSDictionary *)params context:(RunnerContext *)context
{
    // 1. compute strategy set
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return @"[StrategyCenter] start fetch strategy set map";
    }];
    NSString *setName = [params bdre_stringForKey:@"source"];
    return [self __validateParams:params source:setName context:context];
}

- (BDRuleResultModel *)__validateParams:(NSDictionary *)params
                                source:(NSString *)source
                               context:(RunnerContext *)context
{
    if ([source length] == 0) {
        return [self __strategyCenterError:BDStrategyCenterErrorCodeNoSetNameInResult uuid:context.executor.uuid];
    }
    // 2. compute rule set
    BDStrategyResultModel *model = [self __generateStrategiesInSource:source params:params context:context];
    if (model.engineError) {
        return model.ruleResult;
    }
    NSArray<NSString *> *ruleSetNames = model.strategyNames;
    
    return [self __validateParams:params source:source strategyNames:ruleSetNames context:context];
}

- (BDRuleResultModel *)__validateParams:(NSDictionary *)params
                                source:(NSString *)source
                         strategyNames:(NSArray *)strategyNames
                               context:(RunnerContext *)context
{
    CFTimeInterval startBuildRuleTime = CFAbsoluteTimeGetCurrent();
    NSMutableArray *ruleSetArray = [NSMutableArray array];
    for (NSString *ruleSetName in strategyNames) {
        BDRuleGroupModel *ruleSet = [self.store strategyRuleWithName:ruleSetName inSet:source];
        [ruleSetArray btd_addObject:ruleSet];
    }
    if (!ruleSetArray.count) {
        BDRuleResultModel * errorRes = [self __strategyCenterError:BDStrategyCenterErrorCodeRuleSetNotFound uuid:context.executor.uuid];
        errorRes.strategySelectHitCache = context.strategySelectHitCache;
        return errorRes;
    }
    BDRuleGroupModel *mergedRuleSet = [[BDRuleGroupModel alloc]initWithMergeRuleGroupModelArray:[ruleSetArray copy]];
    
    // 3. compute rule result
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return @"[StrategyCenter] start validate rules";
    }];
    BOOL ruleExecBreak = [self.store ruleExecBreakInSet:source];
    CFTimeInterval startComputeRuleTime = CFAbsoluteTimeGetCurrent();
    BDRuleResultModel *result = [context.executor executeRule:mergedRuleSet execAllRules:!ruleExecBreak];
    CFTimeInterval endTime = CFAbsoluteTimeGetCurrent();
    result.cost = (endTime - context.startTime) * 1000000;
    result.sceneSelectCost = (context.startSelectStrategyTime - context.startTime) * 1000000;
    result.strategySelectCost = (startBuildRuleTime - context.startSelectStrategyTime) * 1000000;
    result.ruleBuildCost = (startComputeRuleTime - startBuildRuleTime) * 1000000;
    result.ruleExecCost = (endTime - startComputeRuleTime) * 1000000;
    result.strategySelectHitCache = context.strategySelectHitCache;
    result.strategySelectFromGraph = context.strategySelectFromGraph;
    result.ruleSetNames = strategyNames;
    result.isMainThread = [NSThread isMainThread];
    result.scene = source;
    result.signature = self.store.signature;
    return result;
}

- (BDStrategyResultModel *)__generateStrategiesInSource:(NSString *)setName params:(NSDictionary *)params context:(RunnerContext *)context
{
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[StrategyCenter] start fetch strategy map with name: [%@]", setName];
    }];
    context.startSelectStrategyTime = CFAbsoluteTimeGetCurrent();
    if ([setName length] == 0) {
        return [[BDStrategyResultModel alloc]initWithErrorRuleResultModel:[self __strategyCenterError:BDStrategyCenterErrorCodeNoSetNameInResult uuid:context.executor.uuid]];
    }
    
    BOOL strategySelectBreak = [self.store strategySelectBreakInSet:setName];
    NSArray *strategyMapKeys = [self.store strategyMapKeysInSet:setName];
    NSMutableArray<NSString *> *ruleSetNames = nil;
    
    if ([BDRuleEngineSettings enableCacheSelectStrategy]) {
        NSArray *names = [BDStrategySelectCacheManager ruleSetNamesForInput:params withFilterKeys:strategyMapKeys inSet:setName];
        if (names && [names isKindOfClass:[NSArray class]]) {
            ruleSetNames = [NSMutableArray array];
            for (NSString *name in names) {
                if (![ruleSetNames containsObject:name]) {
                    [ruleSetNames btd_addObject:name];
                }
            }
        }
    }
    
    BDRuleResultModel *strategyMapResult = nil;
    if (ruleSetNames == nil) {
        ruleSetNames = [NSMutableArray array];
        BDRuleGroupModel *strategyMap = [self.store strategyMapRuleInSet:setName];
        if (strategyMap == nil) {
            return [[BDStrategyResultModel alloc]initWithErrorRuleResultModel:[self __strategyCenterError:BDStrategyCenterErrorCodeStrategyMapNotFound uuid:context.executor.uuid]];
        }
        if ([self.store strategyMapGraphInSet:setName]) {
            ruleSetNames = [[[self.store strategyMapGraphInSet:setName] travelWithParams:context.inputParams needBreak:strategySelectBreak] mutableCopy];
            context.strategySelectFromGraph = YES;
        } else {
            strategyMapResult = [context.executor executeRule:strategyMap execAllRules:!strategySelectBreak];
            for (BDSingleRuleResult *result in strategyMapResult.values) {
                NSString *ruleSetName = [result.conf bdre_stringForKey:BDStrategyMapResultKey];
                [ruleSetNames btd_addObject:ruleSetName];
            }
        }
        [BDStrategySelectCacheManager setRuleSetNames:ruleSetNames forInput:params withFilterKeys:strategyMapKeys inSet:setName];
    } else {
        context.strategySelectHitCache = YES;
    }
    
    if (ruleSetNames.count == 0) {
        BDRuleResultModel * errorRes = [self __strategyCenterError:BDStrategyCenterErrorCodeNoRuleSetInResult uuid:context.executor.uuid];
        errorRes.strategySelectHitCache = context.strategySelectHitCache;
        errorRes.strategySelectFromGraph = context.strategySelectFromGraph;
        return [[BDStrategyResultModel alloc]initWithErrorRuleResultModel:errorRes];
    }
    
    CFTimeInterval cost = (CFAbsoluteTimeGetCurrent() - context.startSelectStrategyTime) * 1000000;
    return [[BDStrategyResultModel alloc] initWithStrategyNames:[ruleSetNames copy] ruleResult:strategyMapResult hitCache:context.strategySelectHitCache fromGraph:context.strategySelectFromGraph cost:cost];
}

- (BDRuleResultModel *)__strategyCenterError:(NSInteger)errorCode uuid:(NSString *)uuid
{
    [BDRuleEngineLogger error:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[StrategyCenter] validate failed due to engine error: %ld", errorCode];
    }];
    NSError *error = [NSError errorWithDomain:BDStrategyCenterErrorDomain
                                         code:errorCode
                                     userInfo:nil];
    return [BDRuleResultModel instanceWithError:error uuid:uuid];
}


# pragma mark - logging

- (void)debugLogExecuteRuleEngineResult:(BDRuleResultModel *)result
{
    if (result.engineError) {
        [BDRuleEngineLogger error:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[StrategyCenter] end execute rule engine with error %ld, %@", [result.engineError code], [result.engineError localizedDescription] ?: @""];
        }];
    } else {
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[StrategyCenter] end execute rule engine with result %@", [[result value] description] ?: @""];
        }];
    }
}

- (void)logExecuteRuleEngineResult:(BDRuleResultModel *)result
                   withInputParams:(NSDictionary *)inputParams
{
    [BDRuleEngineReporter log:BDRELogNameStrategyExecute tags:inputParams block:^BDREReportContent * _Nonnull{
        NSMutableDictionary *category = [NSMutableDictionary dictionary];
        NSMutableDictionary *extra = [NSMutableDictionary dictionary];
        // set engine result
        category[@"result"] = result.description ?: @"";
        category[@"key"] = result.key ?: @"";
        category[@"is_main_thread"] = @(result.isMainThread);
        category[@"strategy_select_from_graph"] = @(result.strategySelectFromGraph);
        // set engine error
        if (result.engineError) {
            category[@"engine_error_domain"] = result.engineError.domain;
            category[@"engine_error_code"] = @(result.engineError.code);
            extra[@"engine_error_msg"] = [result.engineError localizedDescription] ?: @"";
        }
        extra[@"uuid"] = result.uuid;
        // set engine input params
        for (NSString *key in inputParams.allKeys) {
            NSString *newKey = [NSString stringWithFormat:@"rule_engine_%@", key];
            NSString *value = [BDStrategyCenter formatValueToLog:inputParams[key]];
            extra[newKey] = value;
        }
        NSDictionary *metric = @{
            @"cost"                      : @(result.cost),
            @"net_cost"                  : @(result.cost - result.fetchParametersCost),
            @"scene_select_cost"         : @(result.sceneSelectCost),
            @"strategy_select_cost"      : @(result.strategySelectCost),
            @"rule_exec_cost"            : @(result.ruleExecCost),
            @"rule_build_cost"           : @(result.ruleBuildCost),
            @"strategy_select_hit_cache" : @(result.strategySelectHitCache)
        };
        return [[BDREReportContent alloc] initWithMetric:metric category:category extra:extra];
    }];
}

- (void)logExecuteStrategiesSelectResult:(BDStrategyResultModel *)result
                              withSource:(NSString *)source
                             inputParams:(NSDictionary *)inputParams
{
    [BDRuleEngineReporter log:BDRELogNameStrategyGenerate tags:inputParams block:^BDREReportContent * _Nonnull{
        NSMutableDictionary *category = [NSMutableDictionary dictionary];
        NSMutableDictionary *extra = [NSMutableDictionary dictionary];
        // set result
        category[@"code"] = @(result.engineError.code);
        category[@"strategies"] = [result.strategyNames btd_jsonStringEncoded] ?: @"";
        category[@"source"] = source ?: @"";
        category[@"key"] = result.key ?: @"";
        category[@"strategy_select_from_graph"] = @(result.fromGraph);
        
        // set engine error
        if (result.engineError) {
            category[@"engine_error_domain"] = result.engineError.domain;
            category[@"engine_error_code"] = @(result.engineError.code);
            extra[@"engine_error_msg"] = [result.engineError localizedDescription] ?: @"";
        }
        extra[@"uuid"] = result.uuid;
        // set engine input params
        for (NSString *key in inputParams.allKeys) {
            NSString *newKey = [NSString stringWithFormat:@"rule_engine_%@", key];
            NSString *value = [BDStrategyCenter formatValueToLog:inputParams[key]];
            extra[newKey] = value;
        }
        
        NSDictionary *metric = @{
            @"cost"                     : @(result.cost),
            @"strategy_select_hit_cache": @(result.hitCache)
        };
        return [[BDREReportContent alloc] initWithMetric:metric category:category extra:extra];
    }];
}

+ (id)formatValueToLog:(id)input
{
    if (input == nil) {
        return nil;
    }
    
    if ([input isKindOfClass:[NSString class]]) {
        return input;
    } else if ([input isKindOfClass:[NSNumber class]]) {
        NSNumber *value = (NSNumber *)input;
        return @([value integerValue]);
    } else if ([input isKindOfClass:[NSArray class]] || [input isKindOfClass:[NSDictionary class]]) {
        return [BDStrategyCenterUtil formatToJsonString:input];
    } else if ([input isKindOfClass:[NSSet class]]) {
        NSSet *set = (NSSet *)input;
        return [BDStrategyCenterUtil formatToJsonString:[set allObjects]];
    }
    return input;
}

@end
