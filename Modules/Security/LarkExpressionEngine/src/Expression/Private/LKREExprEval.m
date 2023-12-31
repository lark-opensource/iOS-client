//
//  LKREExprEval.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREExprEval.h"
#import "LKREExprRunner.h"
#import "LKRECommand.h"

@implementation LKREExprEval

- (id)eval:(NSArray *)commandArray withEnv:(id<LKREExprEnv>)env error:(NSError **)error
{
    NSMutableArray *stack = [[NSMutableArray alloc] init];
    for (LKRECommand *cmd in commandArray) {
        [cmd execute:stack withEnv:env error:error];
        if (*error) return nil;
    }

    if (stack.count != 1) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRUNKNOWN_CAUSE userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | Final Stack count is not 1", NSStringFromSelector(_cmd)]}];
        return nil;
    }
    id stackPeek = [stack lastObject];
    [stack removeLastObject];
    return stackPeek;
}

@end
