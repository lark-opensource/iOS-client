//
//  BDREOperatorCommand.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREOperatorCommand.h"
#import "BDREExprConst.h"
#import "BDRuleEngineLogger.h"
#import "BDREInstruction.h"

@interface BDREOperatorCommand ()

@property (nonatomic, strong) BDREOperator *operator;
@property (nonatomic, assign) NSUInteger opDataNumber;

@end

@implementation BDREOperatorCommand

- (BDREOperatorCommand *)initWithOperator:(BDREOperator *)operator
{
    self = [super init];
    if (self) {
        _operator = operator;
        _opDataNumber = operator.argsLength;
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Expression] get operator command : [%@], [%@]", [self class], operator.symbol];
        }];
    }
    return self;
}

- (void)execute:(NSMutableArray *)cmdStack withEnv:(id<BDREExprEnv>)env error:(NSError *__autoreleasing  _Nullable *)error
{
    NSMutableArray *args = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.opDataNumber; i++) {
        if (cmdStack.count <= 0) {
            if (error) {
                *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRPARAM_NUM_NOT_MATCH userInfo:@{
                    NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ | Empty param for operator %@", NSStringFromSelector(_cmd), self.operator.symbol] ?: @""
                }];
            }
            return;
        }
        [args insertObject:[cmdStack lastObject] atIndex:0];
        [cmdStack removeLastObject];
    }
    id res = [self.operator execute:args error:error];
    if (*error) return;
    if (!res) {
        if (error) {
            *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRRESVALUE_NILRES userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ | Nil res for operatore %@", NSStringFromSelector(_cmd), self.operator.symbol] ?: @""
            }];
        }
        return;
    }
    [cmdStack addObject:res];
}

- (BDREInstruction *)instruction
{
    BDREInstructionType type = BDREInstructionOperator;
    BDREInstructionVariType variType = BDREInstructionVariString;
    uint paramCount = self.operator.argsLength;
    NSString *name = self.operator.symbol;
    uint inst = (type << 14) | (variType << 10) | paramCount;
    return [[BDREInstruction alloc] initWithInstruction:inst value:name];
}

@end
