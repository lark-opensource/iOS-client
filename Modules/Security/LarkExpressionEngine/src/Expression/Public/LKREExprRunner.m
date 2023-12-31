//
//  LKREExprRunner.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/9.
//

#import "LKREExprRunner.h"
#import "LKREExprEnv.h"
#import "LKREExprParser.h"
#import "LKREExprEval.h"
#import "LKREExprCacheManager.h"
#import "LKREFuncManager.h"
#import "LKREOperatorManager.h"
#import "LKRuleEngineReporter.h"
#import "LKRuleEngineMacroDefines.h"

@implementation LKREExprResponse

- (NSDictionary *)jsonFormat
{
    return @{
        @"result"       : [_result description] ?: @"",
        @"code"         : @(_code),
        @"message"      : _message ?: @"",
        @"error"        : [_error description] ?: @"",
        @"ilCache"      : @(_ilHitCache),
        @"parseCache"   : @(_parseHitCache),
        @"execCost"     : @(_execCost),
        @"envCost"      : @(_envCost)
    };
}

@end

@interface LKREExprRunner ()

@property (nonatomic, strong) LKREExprParser *parser;
@property (nonatomic, strong) LKREExprEval *evaler;
@property (nonatomic, strong) LKREExprCacheManager *cacheMgr;

@end

@implementation LKREExprRunner

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.parser = [[LKREExprParser alloc] init];
        self.evaler = [[LKREExprEval alloc] init];
        self.cacheMgr = [LKREExprCacheManager sharedManager];
    }
    return self;
}

+ (LKREExprRunner *)sharedRunner
{
    static LKREExprRunner *sharedRunner = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRunner = [[self alloc] init];
    });
    return sharedRunner;
}

- (void)registerFunc:(LKREFunc *)func
{
    [[LKREFuncManager sharedManager] registerFunc:func];
}

- (void)registerOperator:(LKREOperator *)oper
{
    [[LKREOperatorManager sharedManager] registerOperator:oper];
}

- (LKREExprResponse *)execute:(NSString *)exprStr withEnv:(id<LKREExprEnv>)env
{
    return [self execute:exprStr withEnv:env uuid:nil];
}

- (LKREExprResponse *)execute:(NSString *)exprStr
                      withEnv:(id<LKREExprEnv>)env
                         uuid:(NSString * _Nullable)uuid
{
    return [self execute:exprStr preCommands:nil withEnv:env uuid:uuid];
}

- (LKREExprResponse *)execute:(NSString *)exprStr
                  preCommands:(NSArray * _Nullable)preCommands
                      withEnv:(id<LKREExprEnv>)env
                         uuid:(NSString * _Nullable)uuid
{
    return [self execute:exprStr preCommands:nil withEnv:env uuid:uuid disableCache:NO];
}

- (LKREExprResponse *)execute:(NSString *)exprStr
                  preCommands:(NSArray * _Nullable)preCommands
                      withEnv:(id<LKREExprEnv>)env
                         uuid:(NSString * _Nullable)uuid
                 disableCache:(BOOL)disableCache
{
    @try {
        return [self _execute:exprStr preCommands:preCommands withEnv:env uuid:uuid disableCache:disableCache];
    } @catch (NSException *exception) {
        NSAssert(false, @"found unexpect exception, %@", exception);
        LKREExprResponse *exprResponse = [[LKREExprResponse alloc] init];
        exprResponse.error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRUNKNOWN_CAUSE userInfo:exception.userInfo];
        exprResponse.code = LKREEXPRUNKNOWN_CAUSE;
        exprResponse.message = exception.description;
        return exprResponse;
    }
}

- (LKREExprResponse *)_execute:(NSString *)exprStr
                   preCommands:(NSArray * _Nullable)preCommands
                       withEnv:(id<LKREExprEnv>)env
                          uuid:(NSString * _Nullable)uuid
                  disableCache:(BOOL)disableCache {
    [env resetCost];
    LKREExprResponse *exprResponse = [[LKREExprResponse alloc] init];
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    exprResponse.parseHitCache = YES;
    // defer
    void (^deferBlock)() = ^{
        exprResponse.execCost = (CFAbsoluteTimeGetCurrent() - startTime) * 1000000;
        exprResponse.envCost = [env cost];
        [self logEventWithResponse:exprResponse expr:exprStr uuid:uuid];
    };
    // hander error
    void (^handleErrorBlock)(NSError *error) = ^(NSError *error) {
        exprResponse.error = error;
        exprResponse.message = error.userInfo[@"reason"];
        exprResponse.code = error.code;
        RLLogI(@"[RuleEngine-Expression] Handle error with code %lu: %@%@", exprResponse.code, error.domain, error.userInfo[@"reason"]);
        deferBlock();
    };
    
    NSError *error = nil;
    BOOL ilHitCache = preCommands.count > 0;
    exprResponse.ilHitCache = ilHitCache;
    NSArray *commands = (ilHitCache || disableCache) ? preCommands : [self.cacheMgr findCacheForExpr:exprStr];
    if (commands == nil) {
        exprResponse.parseHitCache = NO;
        CFAbsoluteTime parseStartTime = CFAbsoluteTimeGetCurrent();
        commands = [self.parser parse:exprStr error:&error];
        if (error) {
            handleErrorBlock(error);
            return exprResponse;
        }
        exprResponse.parseCost = (CFAbsoluteTimeGetCurrent() - parseStartTime) * 1000000;
        [self.cacheMgr addCache:commands forExpr:exprStr];
    }
    id result = [self.evaler eval:commands withEnv:env error:&error];
    if (error) {
        handleErrorBlock(error);
        return exprResponse;
    }
    exprResponse.result = result;
    deferBlock();
    return exprResponse;
}

- (NSArray<LKRECommand *> *)commandsWithPreCache:(NSString *)exprStr
{
    NSArray *commands = [self.cacheMgr findCacheForExpr:exprStr];
    if (commands) {
        return commands;
    }
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime executionTime = startTime;
    
    NSError *error = nil;
    commands = [self.parser parse:exprStr error:&error];
    if (error) {
        RLLogI(@"[RuleEngine-Expression]Catch exception with message %@%@", error.domain, error.userInfo[@"reason"]);
        return nil;
    }
    [self.cacheMgr addCache:commands forExpr:exprStr];
    executionTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000000;
    [[LKRuleEngineReporter sharedInstance] log:@"event_expr_pre_cache" metric:@{
        @"cost": @(executionTime * 1000),
    } category:@{
        @"code": @(0),
        @"cel": exprStr ?: @"",
    }];
    return commands;
}

- (void)logEventWithResponse:(LKREExprResponse *)response
                          expr:(NSString *)expr
                          uuid:(NSString *)uuid
{
    [[LKRuleEngineReporter sharedInstance] log:@"event_expr_execute" metric:@{
        @"cost"         : @(response.execCost),
        @"net_cost"     : @(response.execCost - response.envCost)
    } category:@{
        @"code"         : @(response.code),
        @"cache"        : @(response.parseHitCache),
        @"use_il_cache" : @(response.ilHitCache),
        @"cel"          : expr ?: @"",
        @"uuid"         : uuid ?: @"",
    }];
}

@end
