//
//  LKREValueCommand.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREValueCommand.h"
#import "LKRuleEngineMacroDefines.h"
#import "LKREInstruction.h"
#import "LKRENull.h"

@interface LKREValueCommand ()

@property (nonatomic, strong) id value;

@end

@implementation LKREValueCommand

- (LKREValueCommand *)initWithValue:(id)value
{
    self = [super init];
    if (self) {
        self.value = value;
    }
    return self;
}

- (void)execute:(NSMutableArray *)cmdStack withEnv:(id<LKREExprEnv>)env error:(NSError **)error
{
    [cmdStack addObject:self.value];
}

- (LKREInstruction *)instruction
{
    LKREInstructionType type = LKREInstructionLiteral;
    LKREInstructionVariType variType = LKREInstructionVariString;
    uint paramCount = 1;
    uint inst = (type << 14) | (variType << 10) | paramCount;
    if ([self.value isKindOfClass:LKRENull.class]) {
        return [[LKREInstruction alloc] initWithInstruction:inst value:NSStringFromClass(LKRENull.class)];
    }
    return [[LKREInstruction alloc] initWithInstruction:inst value:self.value];
}

@end
