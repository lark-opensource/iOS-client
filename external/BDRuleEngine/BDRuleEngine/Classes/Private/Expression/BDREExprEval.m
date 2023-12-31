//
//  BDREExprEval.m
//  BDRuleEngine
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREExprEval.h"
#import "BDREExprRunner.h"
#import "BDRECommand.h"

@implementation BDREExprEval

+ (id)eval:(NSArray *)commandArray withEnv:(id<BDREExprEnv>)env error:(NSError *__autoreleasing  _Nullable *)error
{
    NSMutableArray *stack = [[NSMutableArray alloc] init];
    for (BDRECommand *cmd in commandArray) {
        [cmd execute:stack withEnv:env error:error];
        if (*error) return nil;
    }
    
    if (stack.count != 1) {
        if (error) {
            *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRUNKNOWN_CAUSE userInfo:@{
                NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ | Final Stack count is not 1", NSStringFromSelector(_cmd)] ?: @""
            }];
        }
    }
    return [stack lastObject];
}

@end
