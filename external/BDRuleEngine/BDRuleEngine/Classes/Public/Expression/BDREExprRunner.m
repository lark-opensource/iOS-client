//
//  BDREExprRunner.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/9.
//

#import "BDREExprRunner.h"
#import "BDREExprEnv.h"
#import "BDREExprParser.h"
#import "BDREExprEval.h"
#import "BDREExprCacheManager.h"
#import "BDREFuncManager.h"
#import "BDREOperatorManager.h"
#import "BDRuleEngineReporter.h"
#import "BDRuleEngineLogger.h"

@implementation BDREExprResponse

- (instancetype)initWithError:(NSError *)error startTime:(CFAbsoluteTime)startTime envCost:(CFTimeInterval)envCost
{
    return [self initWithError:error ilHitCache:NO parseHitCache:NO startTime:startTime envCost:envCost];
}

- (instancetype)initWithError:(NSError *)error ilHitCache:(BOOL)ilHitCache parseHitCache:(BOOL)parseHitCache startTime:(CFAbsoluteTime)startTime envCost:(CFTimeInterval)envCost
{
    if (self = [super init]) {
        self.ilHitCache = ilHitCache;
        self.parseHitCache = parseHitCache;
        self.error = error;
        self.code = error.code;
        self.message = error.localizedDescription;
        self.envCost = envCost;
        self.execCost = (CFAbsoluteTimeGetCurrent() - startTime) * 1000000;
    }
    return self;
}

- (NSDictionary *)jsonFormat
{
    return @{
        @"result"       : [_result description] ?: @"",
        @"code"         : @(_code),
        @"message"      : _message ?: @"",
        @"ilCache"      : @(_ilHitCache),
        @"parseCache"   : @(_parseHitCache),
        @"execCost"     : @(_execCost),
        @"envCost"      : @(_envCost)
    };
}

@end

@implementation BDREExprRunner

+ (BDREExprRunner *)sharedRunner
{
    static BDREExprRunner *sharedRunner = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRunner = [[self alloc] init];
    });
    return sharedRunner;
}

- (void)registerFunc:(BDREFunc *)func
{
    [[BDREFuncManager sharedManager] registerFunc:func];
}

- (void)registerOperator:(BDREOperator *)oper
{
    [[BDREOperatorManager sharedManager] registerOperator:oper];
}

- (BDREExprResponse *)execute:(NSString *)exprStr withEnv:(id<BDREExprEnv>)env
{
    return [self execute:exprStr withEnv:env uuid:nil];
}

- (BDREExprResponse *)execute:(NSString *)exprStr
                      withEnv:(id<BDREExprEnv>)env
                         uuid:(NSString *)uuid
{
    return [self execute:exprStr preCommands:nil withEnv:env uuid:uuid];
}

- (BDREExprResponse *)execute:(NSString *)exprStr
                  preCommands:(NSArray *)preCommands
                      withEnv:(id<BDREExprEnv>)env
                         uuid:(NSString *)uuid
{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    [env resetCost];
    BDREExprResponse *response = [[BDREExprResponse alloc] init];
    response.parseHitCache = YES;
    response.ilHitCache = preCommands.count > 0;
    NSArray *commands = response.ilHitCache ? preCommands : [[BDREExprCacheManager sharedManager] findCacheForExpr:exprStr];
    
    NSError *error;
    if (!commands) {
        response.parseHitCache = NO;
        commands = [BDREExprParser parse:exprStr error:&error];
        if (error) {
            BDREExprResponse *errorResponse = [[BDREExprResponse alloc] initWithError:error startTime:startTime envCost:[env cost]];
            [self logExecuteExprWithResponse:errorResponse expr:exprStr uuid:uuid];
            [self logEventWithCode:errorResponse.code cel:exprStr message:errorResponse.message];
            return errorResponse;
        }
        [[BDREExprCacheManager sharedManager] addCache:commands forExpr:exprStr];
    }
    
    id result = [BDREExprEval eval:commands withEnv:env error:&error];
    if (error) {
        BDREExprResponse *errorResponse = [[BDREExprResponse alloc] initWithError:error ilHitCache:response.ilHitCache parseHitCache:response.parseHitCache startTime:startTime envCost:[env cost]];
        [self logExecuteExprWithResponse:errorResponse expr:exprStr uuid:uuid];
        [self logEventWithCode:errorResponse.code cel:exprStr message:errorResponse.message];
        return errorResponse;
    }
    
    response.result = result;
    response.envCost = [env cost];
    response.execCost = (CFAbsoluteTimeGetCurrent() - startTime) * 1000000;
    [self logExecuteExprWithResponse:response expr:exprStr uuid:uuid];
    return response;
}

- (void)logExecuteExprWithResponse:(BDREExprResponse *)reponse expr:(NSString *)expr uuid:(NSString *)uuid
{
    NSError *error = reponse.error;
    if (error) {
        [BDRuleEngineLogger error:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Expression] Catch error with error domain: [%@] code: [%ld], msg: [%@]", error.domain, error.code, error.localizedDescription ?: @""];
        }];
    } else {
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Expression] End expression : [%@] with result [%@]", expr, reponse.result];
        }];
    }
    [self logEventWithResponse:reponse expr:expr uuid:uuid];
}

- (NSArray<BDRECommand *> *)commandsFromExpr:(NSString *)exprStr
{
    NSArray *commands = [[BDREExprCacheManager sharedManager] findCacheForExpr:exprStr];
    if (commands) {
        return commands;
    }
    
    NSError *error;
    commands = [BDREExprParser parse:exprStr error:&error];
    
    if (error) {
        [BDRuleEngineLogger error:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Expression] Catch error when parse with error domain: [%@] code: [%ld], msg: [%@]", error.domain, error.code, error.localizedDescription ?: @""];
        }];
        return nil;
    }
    
    [[BDREExprCacheManager sharedManager] addCache:commands forExpr:exprStr];
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[Expression] pre-cache : [%@]", exprStr];
    }];
    return commands;
}

- (void)logEventWithResponse:(BDREExprResponse *)response
                          expr:(NSString *)expr
                          uuid:(NSString *)uuid
{
    NSDictionary *tags = @{BDRELogSampleTagSourceKey: BDRELogExprExecEventSourceValue, @"cel": expr ?: @""};
    [BDRuleEngineReporter log:BDRELogNameExpressionExecute tags:tags block:^BDREReportContent * _Nonnull{
        return [[BDREReportContent alloc] initWithMetric:@{
            @"cost"              : @(response.execCost),
            @"net_cost"          : @(response.execCost - response.envCost)
        } category:@{
            @"code"              : @(response.code),
            @"cache"             : @(response.parseHitCache),
            @"use_il_cache"      : @(response.ilHitCache),
            @"is_quick_executor" : @(NO)
        } extra:@{
            @"cel"               : expr ?: @"",
            @"uuid"              : uuid ?: @""
        }];
    }];
}

- (void)logEventWithCode:(NSInteger)code
                     cel:(NSString *)cel
                 message:(NSString *)message
{
    NSDictionary *tags = @{BDRELogSampleTagSourceKey: BDRElogExprExecErrorSourceValue};
    [BDRuleEngineReporter log:BDRELogNameExpressionExecuteAbnormal tags:tags block:^id<BDRuleEngineReportDataSource> _Nonnull{
        return [[BDREReportContent alloc] initWithMetric:@{
            @"code"    : @(code)
        } category:@{
            @"cel"     : cel ?: @""
        } extra:@{
            @"message" : message ?: @""
        }];
    }];
}

@end
