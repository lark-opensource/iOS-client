//
//  BDRuleQuickExecutor.m
//  BDRuleEngine-Core-Debug-Expression-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/8/18.
//

#import "BDRuleQuickExecutor.h"
#import "BDRuleEngineErrorConstant.h"
#import "BDRuleEngineSettings.h"
#import "BDREValueCommand.h"
#import "BDREOperatorCommand.h"
#import "BDREFunctionCommand.h"
#import "BDREIdentifierCommand.h"
#import "BDRuleEngineReporter.h"
#import "BDRuleParameterRegistry.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>

#pragma mark - Quick Executor

@interface BDRuleQuickExecutor ()

@property (nonatomic, copy, nonnull) NSString *cel;

- (instancetype)initWithCel:(NSString *)cel;

@end

@implementation BDRuleQuickExecutor

- (instancetype)initWithCel:(NSString *)cel
{
    if (self = [super init]) {
        self.cel = cel;
    }
    return self;
}

- (BOOL)evaluateWithEnv:(id<BDREExprEnv>)env error:(NSError *__autoreleasing  _Nullable *)error
{
    return NO;
}

- (void)logEventWithCost:(CFTimeInterval)cost
{
    [self logEventWithCost:cost envCost:0];
}

- (void)logEventWithCost:(CFTimeInterval)cost envCost:(CFTimeInterval)envCost
{
    [self logEventWithCost:cost envCost:envCost code:0];
}

- (void)logEventWithCost:(CFTimeInterval)cost envCost:(CFTimeInterval)envCost code:(NSUInteger)code
{
    NSDictionary *tags = @{BDRELogSampleTagSourceKey: BDRELogExprExecEventSourceValue, @"cel": self.cel ?: @""};
    [BDRuleEngineReporter log:BDRELogNameExpressionExecute tags:tags block:^BDREReportContent * _Nonnull{
        return [[BDREReportContent alloc] initWithMetric:@{
            @"cost"              : @(cost),
            @"net_cost"          : @(cost - envCost)
        } category:@{
            @"code"              : @(code),
            @"cache"             : @(YES),
            @"use_il_cache"      : @(YES),
            @"is_quick_executor" : @(YES)
        } extra:@{
            @"cel"               : self.cel ?: @"",
            @"uuid"              : @""
        }];
    }];
}

@end

@interface BDRuleConstQuickExecutor : BDRuleQuickExecutor

@property (nonatomic, strong) id value;

- (instancetype)initWithCel:(NSString *)cel value:(id)value;

@end

@implementation BDRuleConstQuickExecutor

- (instancetype)initWithCel:(NSString *)cel value:(id)value
{
    if (self = [super initWithCel:cel]) {
        self.value = value;
    }
    return self;
}

- (BOOL)evaluateWithEnv:(id<BDREExprEnv>)env error:(NSError *__autoreleasing  _Nullable *)error
{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    BOOL res = NO;
    if ([self.value isKindOfClass:[NSNumber class]] || [self.value isKindOfClass:[NSString class]]) {
        res = [self.value boolValue];
    } else {
        if (error) {
            *error = [NSError errorWithDomain:BDQuickExecutorErrorDomain code:BDQuickExecutorErrorCodeConstTypeNotBool userInfo:nil];
        }
    }
    [self logEventWithCost:(CFAbsoluteTimeGetCurrent() - startTime) * 1000000];
    return res;
}

@end

@interface BDRuleEqualQuickExecutor : BDRuleQuickExecutor

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) id constValue;
@property (nonatomic, assign) BOOL notEqual;

- (instancetype)initWithCel:(NSString *)cel identifier:(NSString *)identifier constValue:(id)constValue notEqual:(BOOL)notEqual;

@end

@implementation BDRuleEqualQuickExecutor

- (instancetype)initWithCel:(NSString *)cel identifier:(NSString *)identifier constValue:(id)constValue notEqual:(BOOL)notEqual
{
    if (self == [super initWithCel:cel]) {
        self.identifier = identifier;
        self.constValue = constValue;
        self.notEqual = notEqual;
    }
    return self;
}

- (BOOL)evaluateWithEnv:(id<BDREExprEnv>)env error:(NSError *__autoreleasing  _Nullable *)error
{
    CFAbsoluteTime startEnvTime = CFAbsoluteTimeGetCurrent();
    id param = [env envValueOfKey:self.identifier];
    CFAbsoluteTime startExecTime = CFAbsoluteTimeGetCurrent();
    BOOL res = [param compare:self.constValue] == NSOrderedSame;
    if (self.notEqual) {
        res = !res;
    }
    CFAbsoluteTime endExecTime = CFAbsoluteTimeGetCurrent();
    [self logEventWithCost:(endExecTime - startEnvTime) * 1000000 envCost:(startExecTime - startEnvTime) * 1000000];
    return res;
}

@end

@interface BDRuleInOutQuickExecutor : BDRuleQuickExecutor

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) id constArray;
@property (nonatomic, assign) BOOL notIn;


- (instancetype)initWithCel:(NSString *)cel identifier:(NSString *)identifier constArray:(id)constArray notIn:(BOOL)notIn;

@end

@implementation BDRuleInOutQuickExecutor

- (instancetype)initWithCel:(NSString *)cel identifier:(NSString *)identifier constArray:(id)constArray notIn:(BOOL)notIn
{
    if (self == [super initWithCel:cel]) {
        self.identifier = identifier;
        self.constArray = constArray;
        self.notIn = notIn;
    }
    return self;
}

- (BOOL)evaluateWithEnv:(id<BDREExprEnv>)env error:(NSError *__autoreleasing  _Nullable *)error
{
    CFAbsoluteTime startEnvTime = CFAbsoluteTimeGetCurrent();
    id param = [env envValueOfKey:self.identifier];
    CFAbsoluteTime startExecTime = CFAbsoluteTimeGetCurrent();
    BOOL res = [self.constArray containsObject:param];
    if (self.notIn) {
        res = !res;
    }
    CFAbsoluteTime endExecTime = CFAbsoluteTimeGetCurrent();
    [self logEventWithCost:(endExecTime - startEnvTime) * 1000000 envCost:(startExecTime - startEnvTime) * 1000000];
    return res;
}

@end

@interface BDRuleMatchesExecutor : BDRuleQuickExecutor

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) id constArray;

- (instancetype)initWithCel:(NSString *)cel identifier:(NSString *)identifier constArray:(id)constArray;

@end

@implementation BDRuleMatchesExecutor

- (instancetype)initWithCel:(NSString *)cel identifier:(NSString *)identifier constArray:(id)constArray
{
    if (self == [super initWithCel:cel]) {
        self.identifier = identifier;
        self.constArray = constArray;
    }
    return self;
}

- (BOOL)evaluateWithEnv:(id<BDREExprEnv>)env error:(NSError *__autoreleasing  _Nullable *)error
{
    CFAbsoluteTime startEnvTime = CFAbsoluteTimeGetCurrent();
    id param = [env envValueOfKey:self.identifier];
    CFAbsoluteTime startExecTime = CFAbsoluteTimeGetCurrent();
    BOOL res = NO;
    if ([param isKindOfClass:[NSString class]]) {
        for (id obj in self.constArray) {
            if ([obj isKindOfClass:[NSString class]] && [(NSString *)param btd_matchsRegex:obj]) {
                res = YES;
            }
        }
    }
    CFAbsoluteTime endExecTime = CFAbsoluteTimeGetCurrent();
    [self logEventWithCost:(endExecTime - startEnvTime) * 1000000 envCost:(startExecTime - startEnvTime) * 1000000];
    return res;
}

@end

#pragma mark - Quick Executor Factory

@implementation BDRuleQuickExecutorFactory

+ (BDRuleQuickExecutor *)createExecutorWithCommands:(NSArray<BDRECommand *> *)commands cel:(NSString *)cel
{
    if (!commands.count) {
        return nil;
    }
    BDRECommand *lastCommand = commands.lastObject;
    // cel: true
    if ([lastCommand isKindOfClass:[BDREValueCommand class]]) {
        if (commands.count == 1) {
            return [[BDRuleConstQuickExecutor alloc] initWithCel:cel value:((BDREValueCommand *)lastCommand).value];
        } else {
            return nil;
        }
    }
    
    if (commands.count < 3) {
        return nil;
    }
    BDRECommand *firstCommand = [commands btd_objectAtIndex:0];
    BDRECommand *lastSecondCommand = [commands btd_objectAtIndex:commands.count - 2];
    if (![firstCommand isKindOfClass:[BDREIdentifierCommand class]]) {
        return nil;
    }
    NSString *identifier = ((BDREIdentifierCommand *)firstCommand).identifier;
    
    // cel: A == B, A != B, A in [B, C]
    if ([lastCommand isKindOfClass:[BDREOperatorCommand class]]) {
        BDREOperator *op = ((BDREOperatorCommand *)lastCommand).operator;
        
        if ([@[@"==", @"!="] containsObject:op.symbol]) {
            // A == true, A != "a"
            // A is IdentifierCommand and B is ValueCommand
            if (commands.count != 3) {
                return nil;
            }
            if (![lastSecondCommand isKindOfClass:[BDREValueCommand class]]) {
                return nil;
            }
            id value = ((BDREValueCommand *)lastSecondCommand).value;
            if (![value isKindOfClass:[NSNumber class]] && ![value isKindOfClass:[NSString class]]) {
                return nil;
            }
            return [[BDRuleEqualQuickExecutor alloc] initWithCel:cel identifier:identifier constValue:value notEqual:[op.symbol isEqualToString:@"!="]];
        }
        
        if ([@[@"in", @"out", @"matches"] containsObject:op.symbol]) {
            // A in [B,C], A out [B, C], A matches [B, C]
            id constArray = nil;
            if (commands.count == 3) {
                // const pool check
                if (![firstCommand isKindOfClass:[BDREIdentifierCommand class]] || ![lastSecondCommand isKindOfClass:[BDREIdentifierCommand class]]) {
                    return nil;
                }
                NSString *identifier2 = ((BDREIdentifierCommand *)lastSecondCommand).identifier;
                // check const
                BDRuleParameterBuilderModel *model = [BDRuleParameterRegistry builderForKey:identifier2];
                if (!model || model.origin != BDRuleParameterOriginConst || model.type != BDRuleParameterTypeArray) {
                    return nil;
                }
                constArray = model.builder(nil);
            } else {
                if (![firstCommand isKindOfClass:[BDREIdentifierCommand class]] || ![lastSecondCommand isKindOfClass:[BDREFunctionCommand class]]) {
                    return nil;
                }
                BDREFunctionCommand *functionCommand = (BDREFunctionCommand *)lastSecondCommand;
                if (![functionCommand.func.symbol isEqualToString:@"array"] || functionCommand.argsNumber != commands.count - 3) {
                    return nil;
                }
                NSMutableArray *array = [NSMutableArray array];
                // A in ["a","b"] --- A "a" "b" array in
                for (NSInteger index = 1; index < commands.count - 2; index++) {
                    BDRECommand *indexCommand = [commands btd_objectAtIndex:index];
                    if (![indexCommand isKindOfClass:[BDREValueCommand class]]) {
                        return nil;
                    }
                    id value = ((BDREValueCommand *)indexCommand).value;
                    [array btd_addObject:value];
                }
                constArray = [NSArray arrayWithArray:array];
            }
            if ([op.symbol isEqualToString:@"matches"]) {
                return [[BDRuleMatchesExecutor alloc] initWithCel:cel identifier:identifier constArray:constArray];
            } else {
                return [[BDRuleInOutQuickExecutor alloc] initWithCel:cel identifier:identifier constArray:constArray notIn:[op.symbol isEqualToString:@"out"]];
            }
        }
    }
    return nil;
}

@end
