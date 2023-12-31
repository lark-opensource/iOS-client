//
//  LKREIdentifierCommand.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREIdentifierCommand.h"
#import "LKREExprConst.h"
#import "LKRuleEngineMacroDefines.h"
#import "LKREInstruction.h"
#import "LKREParamMissing.h"
#import "LKRENull.h"

@interface LKREIdentifierCommand ()

@property (nonatomic, strong) NSString *identifier;

@end

@implementation LKREIdentifierCommand

- (LKREIdentifierCommand *)initWithIdentifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        self.identifier = identifier;
    }
    return self;
}

- (void)execute:(NSMutableArray *)cmdStack withEnv:(id<LKREExprEnv>)env error:(NSError **)error
{
    id res = [env envValueOfKey:self.identifier];
    if (!res) {
        [cmdStack addObject:[LKREParamMissing new]];
    } else if ([res isKindOfClass:[NSNull class]]) {
        [cmdStack addObject:[LKRENull new]];
    } else {
        [cmdStack addObject:res];
    }
}

- (LKREInstruction *)instruction
{
    LKREInstructionType type = LKREInstructionVariable;
    LKREInstructionVariType variType = LKREInstructionVariString;
    uint paramCount = 1;
    NSString *name = self.identifier;
    uint inst = (type << 14) | (variType << 10) | paramCount;
    return [[LKREInstruction alloc] initWithInstruction:inst value:name];
}

@end
