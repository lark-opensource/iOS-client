//
//  BDRuleExecutor.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/26.
//
#import "BDRuleExecutor.h"
#import "BDRuleGroupModel.h"
#import "BDRuleResultModel.h"
#import "BDRuleUnitExecutor.h"
#import "BDRuleEngineReporter.h"
#import "BDRuleParameterFetcher.h"
#import "BDRuleEngineLogger.h"

@interface BDRuleExecutor()

@property (nonatomic, strong) BDRuleParameterFetcher *fetcher;
@property (nonatomic, copy) NSString *uuid;

@end

@implementation BDRuleExecutor

- (instancetype)initWithParameters:(NSDictionary *)parameters
{
    self = [super init];
    if (self) {
        _fetcher = [[BDRuleParameterFetcher alloc] initWithExtraParameters:parameters];
        _uuid = [NSUUID UUID].UUIDString;
    }
    return self;
}

- (BDRuleResultModel *)executeRule:(BDRuleGroupModel *)rule
{
    return [self executeRule:rule execAllRules:NO];
}

- (BDRuleResultModel *)executeRule:(BDRuleGroupModel *)rule execAllRules:(BOOL)execAllRules
{
    //核心逻辑，具体见：https://bytedance.feishu.cn/docs/doccnxedSFmSK3M2Advocts0eig#
    BDRuleResultModel *result;
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[Executor] start execute rules [%@]", rule.name];
    }];
    result = [self __evaluateRules:rule.rules execAllRules:execAllRules];
    if (result) {
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Executor] end execute rules [%@] with result [%@]", rule.name ?: @"", result.value.description ?: @""];
        }];
    } else {
        result = [[BDRuleResultModel alloc] initWithUUID:_uuid];
    }
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[Executor] execute rules final result [%@]", [result description] ?: @""];
    }];
    result.key = rule.name;
    result.fetchParametersCost = [_fetcher cost];
    result.usedParameters = [_fetcher usedParameters];
    return result;
}

#pragma mark - Private
- (BDRuleResultModel *)__evaluateRules:(NSArray<BDRuleModel *> *)rules
                          execAllRules:(BOOL)execAllRules

{
    NSMutableArray *finalResults = [NSMutableArray array];
    for (BDRuleModel *rule in rules) {
        BDRuleResultModel *result = [self __evaluateRule:rule execAllRules:execAllRules];
        if (result.engineError) {
            continue;
        }
        if (result.values.count > 0) {
            if (execAllRules) {
                [finalResults addObjectsFromArray:result.values];
            } else {
                return result;
            }
        }
    }
    if (finalResults.count > 0) {
        BDRuleResultModel *finalResult = [[BDRuleResultModel alloc] initWithUUID:_uuid];
        finalResult.values = [finalResults copy];
        return finalResult;
    }
    // 如果所有规则不满足，返回空值
    return nil;
}

- (BDRuleResultModel *)__evaluateRule:(BDRuleModel *)rule
                         execAllRules:(BOOL)execAllRules
{
    NSError *error;
    BOOL result = NO;
    if (rule.qucikExecutor) {
        result = [rule.qucikExecutor evaluateWithEnv:_fetcher error:&error];
    } else {
        BDRuleUnitExecutor *executor = [[BDRuleUnitExecutor alloc] initWithCel:rule.cel commands:rule.commands env:_fetcher uuid:_uuid];
        result = [executor evaluate:&error];
    }
    // 递归结束条件，出错
    if (error) {
        BDRuleResultModel *errorResult = [BDRuleResultModel instanceWithError:error uuid:_uuid];
        [BDRuleEngineLogger error:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Executor] execute rule [%@] with error [%@]", rule.title ?: @"", error.localizedDescription ?: @""];
        }];
        return errorResult;
    }
    // 如果执行结果为 NO，返回空
    if (!result) {
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Executor] execute rule [%@] with false result", rule.title ?: @""];
        }];
        return nil;
    }
    // 如果执行结果为 YES
    // 如果有子节点，执行子节点
    if (rule.children.count > 0) {
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Executor] execute rule [%@] with true result and has children", rule.title ?: @""];
        }];
        return [self __evaluateRules:rule.children execAllRules:execAllRules];
    }
    // 如果无子节点，执行结束
    if ([rule.conf isKindOfClass:[NSDictionary class]] && rule.conf.count > 0) {
        BDRuleResultModel *successResult = [[BDRuleResultModel alloc] initWithUUID:_uuid];
        BDSingleRuleResult *singleResult = [[BDSingleRuleResult alloc] init];
        singleResult.conf = rule.conf;
        singleResult.key = rule.key;
        singleResult.title = rule.title;
        successResult.values = @[singleResult];
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Executor] execute rule [%@] with true result and has config [%@]", rule.title ?: @"", rule.conf ?: @""];
        }];
        return successResult;
    }
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[Executor] execute rule [%@] with true result and has no config", rule.title ?: @""];
    }];
    return nil;
}

@end
