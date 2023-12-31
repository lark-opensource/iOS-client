//
//  LKREOperatorCommand.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREOperatorCommand.h"
#import "LKREExprConst.h"
#import "LKRuleEngineMacroDefines.h"
#import "LKREInstruction.h"

@interface LKREOperatorCommand ()

@property (nonatomic, strong) LKREOperator *operator;
@property (nonatomic, assign) NSUInteger opDataNumber;

@end

@implementation LKREOperatorCommand

- (LKREOperatorCommand *)initWithOperator:(LKREOperator *)operator
{
    self = [super init];
    if (self) {
        self.operator = operator;
        self.opDataNumber = operator.argsLength;
    }
    return self;
}

- (void)execute:(NSMutableArray *)cmdStack withEnv:(id<LKREExprEnv>)env error:(NSError **)error
{
    NSMutableArray *args = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.opDataNumber; i++) {
        if (cmdStack.count <= 0) {
            *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRPARAM_NUM_NOT_MATCH userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | Empty param for operator %@", NSStringFromSelector(_cmd), self.operator.symbol]}];
            return;
        }
        [args insertObject:[cmdStack lastObject] atIndex:0];
        [cmdStack removeLastObject];
    }
    id result = [self.operator execute:args error:error];
    if (*error) return;
    [cmdStack addObject:result];
}

- (LKREInstruction *)instruction
{
    LKREInstructionType type = LKREInstructionOperator;
    LKREInstructionVariType variType = LKREInstructionVariString;
    uint paramCount = self.operator.argsLength;
    NSString *name = self.operator.symbol;
    uint inst = (type << 14) | (variType << 10) | paramCount;
    return [[LKREInstruction alloc] initWithInstruction:inst value:name];
}

@end
