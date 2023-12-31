//
//  LKREFunctionCommand.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREFunctionCommand.h"
#import "LKREExprConst.h"
#import "LKRuleEngineMacroDefines.h"
#import "LKREInstruction.h"

@interface LKREFunctionCommand ()

@property (nonatomic, strong) LKREFunc *func;
@property (nonatomic, assign) NSUInteger argsNumber;

@end

@implementation LKREFunctionCommand

- (LKREFunctionCommand *)initWithFunc:(LKREFunc *)func argsLength:(NSUInteger)argsLength
{
    self = [super init];
    if (self) {
        self.func = func;
        self.argsNumber = argsLength;
    }
    return self;
}

- (void)execute:(NSMutableArray *)cmdStack withEnv:(id<LKREExprEnv>)env error:(NSError **)error
{
    NSMutableArray *args = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.argsNumber; i++) {
        if (cmdStack.count <= 0) {
            if ([self.func.symbol isEqualToString:@"array"]) {
                //空数组
                id result = [self.func execute:args error:error];
                if (*error) return;
                [cmdStack addObject:result];
                return;
            }
            *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRPARAM_NUM_NOT_MATCH userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | Empty param for function %@", NSStringFromSelector(_cmd), self.func.symbol]}];
            return;
        }
        [args insertObject:[cmdStack lastObject] atIndex:0];
        [cmdStack removeLastObject];
    }
    if (self.func.argsLength == NSIntegerMax || self.func.argsLength == args.count) {
        id result = [self.func execute:args error:error];
        if (*error) return;
        [cmdStack addObject:result];
    } else {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRPARAM_NUM_NOT_MATCH userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | Param count for function %@ not match, expect %@, but %@", NSStringFromSelector(_cmd), self.func.symbol, @(self.func.argsLength), @(args.count)]}];
        return;
    }
}

- (LKREInstruction *)instruction
{
    LKREInstructionType type = LKREInstructionFunction;
    LKREInstructionVariType variType = LKREInstructionVariString;
    uint paramCount = (uint)self.argsNumber;
    NSString *name = self.func.symbol;
    uint inst = (type << 14) | (variType << 10) | paramCount;
    return [[LKREInstruction alloc] initWithInstruction:inst value:name];
}

@end
