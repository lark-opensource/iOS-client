//
//  BDREIdentifierCommand.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREIdentifierCommand.h"
#import "BDREExprConst.h"
#import "BDRuleEngineLogger.h"
#import "BDREInstruction.h"

@interface BDREIdentifierCommand ()

@property (nonatomic, copy) NSString *identifier;

@end

@implementation BDREIdentifierCommand

- (BDREIdentifierCommand *)initWithIdentifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        _identifier = identifier;
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Expression] get identifier command : [%@], [%@]", [self class], identifier];
        }];
    }
    return self;
}

- (void)execute:(NSMutableArray *)cmdStack withEnv:(id<BDREExprEnv>)env error:(NSError *__autoreleasing  _Nullable *)error
{
    id res = [env envValueOfKey:self.identifier];
    if (!res) {
        if (error) {
            *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRNONVALUE_IDENTIFIER userInfo:@{
                NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ | Empty value for identifier: %@", NSStringFromSelector(_cmd), self.identifier] ?: @""
            }];
        }
        return;
    }
    [cmdStack addObject:res];
}

- (BDREInstruction *)instruction
{
    BDREInstructionType type = BDREInstructionVariable;
    BDREInstructionVariType variType = BDREInstructionVariString;
    uint paramCount = 1;
    NSString *name = self.identifier;
    uint inst = (type << 14) | (variType << 10) | paramCount;
    return [[BDREInstruction alloc] initWithInstruction:inst value:name];
}

@end
