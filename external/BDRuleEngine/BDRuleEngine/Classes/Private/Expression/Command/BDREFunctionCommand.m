//
//  BDREFunctionCommand.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREFunctionCommand.h"
#import "BDREExprConst.h"
#import "BDRuleEngineLogger.h"
#import "BDREInstruction.h"
#import "BDREFuncManager.h"

@interface BDREFunctionCommand ()

@property (nonatomic, strong) BDREFunc *func;
@property (nonatomic, copy) NSString *funcName;
@property (nonatomic, assign) NSUInteger argsNumber;

@end

@implementation BDREFunctionCommand

- (instancetype)initWithFuncName:(NSString *)funcName func:(BDREFunc *)func argsLength:(NSUInteger)argsLength
{
    self = [super init];
    if (self) {
        _func = func;
        _funcName = funcName;
        _argsNumber = argsLength;
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Expression] get func command : [%@], [%@]", [self class], self.funcName];
        }];
    }
    return self;
}

- (void)execute:(NSMutableArray *)cmdStack withEnv:(id<BDREExprEnv>)env error:(NSError *__autoreleasing  _Nullable *)error
{
    if (!self.func) {
        self.func = [[BDREFuncManager sharedManager] getFuncFromSymbol:self.funcName];
        if (!self.func) {
            if (error) {
                *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRUNKNOWN_FUNCTION userInfo:@{
                    NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ | Can not find function %@", NSStringFromSelector(_cmd), self.funcName ?: @""] ?: @""
                }];
            }
            return;
        }
    }
    NSMutableArray *args = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.argsNumber; i++) {
        if (cmdStack.count == 0) {
            if ([self.func.symbol isEqualToString:@"array"]) {
                //空数组
                id res = [self.func execute:args error:error];
                if (*error) return;
                [cmdStack addObject:res];
            }
            if (error) {
                *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRPARAM_NUM_NOT_MATCH userInfo:@{
                    NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ | Empty param for function %@", NSStringFromSelector(_cmd), self.func.symbol] ?: @""
                }];
            }
            return;
        }
        [args insertObject:[cmdStack lastObject] atIndex:0];
        [cmdStack removeLastObject];
    }
    
    id res = [self.func execute:args error:error];
    if (*error) return;
    if (!res) {
        if (error) {
            *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRRESVALUE_NILRES userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ | Nil res for function %@", NSStringFromSelector(_cmd), self.func.symbol] ?: @""
            }];
        }
        return;
    }
    [cmdStack addObject:res];
}

- (BDREInstruction *)instruction
{
    BDREInstructionType type = BDREInstructionFunction;
    BDREInstructionVariType variType = BDREInstructionVariString;
    uint paramCount = (uint)self.argsNumber;
    NSString *name = self.funcName;
    uint inst = (type << 14) | (variType << 10) | paramCount;
    return [[BDREInstruction alloc] initWithInstruction:inst value:name];
}

@end
