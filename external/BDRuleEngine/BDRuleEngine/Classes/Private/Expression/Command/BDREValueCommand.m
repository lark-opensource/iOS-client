//
//  BDREValueCommand.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREValueCommand.h"
#import "BDRuleEngineLogger.h"
#import "BDREInstruction.h"
#import "BDRENull.h"
#import "BDREExprConst.h"

@interface BDREValueCommand ()

@property (nonatomic, strong) id value;

@end

@implementation BDREValueCommand

- (BDREValueCommand *)initWithValue:(id)value
{
    self = [super init];
    if (self) {
        _value = value;
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Expression] get value command : [%@], [%@]", [self class], value];
        }];
    }
    return self;
}

- (void)execute:(NSMutableArray *)cmdStack withEnv:(id<BDREExprEnv>)env error:(NSError *__autoreleasing  _Nullable *)error
{
    if (!self.value) {
        if (error) {
            *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRRESVALUE_NILRES userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ | Const value is nil", NSStringFromSelector(_cmd)] ?: @""
            }];
        }
        return;
    }
    [cmdStack addObject:self.value];
}

- (BDREInstruction *)instruction
{
    BDREInstructionType type = BDREInstructionLiteral;
    BDREInstructionVariType variType = BDREInstructionVariString;
    uint paramCount = 1;
    uint inst = (type << 14) | (variType << 10) | paramCount;
    if ([self.value isKindOfClass:BDRENull.class]) {
        return [[BDREInstruction alloc] initWithInstruction:inst value:NSStringFromClass(BDRENull.class)];
    }
    return [[BDREInstruction alloc] initWithInstruction:inst value:self.value];
}

@end
