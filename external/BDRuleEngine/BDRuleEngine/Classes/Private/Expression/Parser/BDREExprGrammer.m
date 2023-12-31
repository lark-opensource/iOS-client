//
//  BDREExprGrammer.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREExprGrammer.h"
#import "BDREExprRunner.h"
#import "BDREConstNode.h"
#import "BDREIdentifierNode.h"
#import "BDRESplitNode.h"
#import "BDREOperatorNode.h"
#import "BDREFuncNode.h"
#import "BDREValueCommand.h"
#import "BDREOperatorCommand.h"
#import "BDREFunctionCommand.h"
#import "BDREIdentifierCommand.h"

@implementation BDREExprGrammer

+ (NSArray *)parseNodesToCommands:(NSArray *)nodes error:(NSError *__autoreleasing  _Nullable *)error
{
    NSMutableArray *commandArray = [[NSMutableArray alloc] init];
    NSMutableArray *stack = [[NSMutableArray alloc] init];
    NSMutableArray *stackFuncOpDataNumber = [[NSMutableArray alloc] init];
    for (int i = 0; i < nodes.count; i++) {
        BDREBaseNode *node = nodes[i];
        if ([node isKindOfClass:[BDREConstNode class]]) {
            [commandArray addObject:[[BDREValueCommand alloc] initWithValue:[(BDREConstNode *)node getValue]]];
        } else if ([node isKindOfClass:[BDREIdentifierNode class]]) {
            BDREIdentifierNode *idN = (BDREIdentifierNode *)node;
            [commandArray addObject:[[BDREIdentifierCommand alloc] initWithIdentifier:idN.identifier]];
        } else if ([node isKindOfClass:[BDRELeftSplitNode class]]) {
            [stack addObject:node];
            BDRELeftSplitNode *lsN = (BDRELeftSplitNode *)node;
            if (lsN.isFunctionStart) {
                if (nodes.count > i + 1 && [nodes[i+1] isKindOfClass:[BDRERightSplitNode class]]){
                    [stackFuncOpDataNumber addObject:@(0)];
                } else {
                    [stackFuncOpDataNumber addObject:@(1)];
                }
            }
        } else if ([node isKindOfClass:[BDRECenterSplitNode class]]) {
            BDREBaseNode *peekNode = [stack lastObject];
            BDRELeftSplitNode *lsn = nil;
            if ([peekNode isKindOfClass:[BDRELeftSplitNode class]]) {
                lsn = (BDRELeftSplitNode *)peekNode;
            }
            while (![peekNode isKindOfClass:[BDRELeftSplitNode class]] || (lsn != nil && !lsn.isFunctionStart)) {
                [stack removeLastObject];
                if ([peekNode isKindOfClass:[BDREOperatorNode class]]) {
                    BDREOperatorNode *opn = (BDREOperatorNode *)peekNode;
                    [commandArray addObject:[[BDREOperatorCommand alloc] initWithOperator:opn.opetator]];
                }
                lsn = nil;
                peekNode = [stack lastObject];
                if ([peekNode isKindOfClass:[BDRELeftSplitNode class]]) {
                    lsn = (BDRELeftSplitNode *)peekNode;
                }
            }
            if (stackFuncOpDataNumber.count <= 0) {
                if (error) {
                    *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRINVALID_EXPRESS userInfo:@{
                        NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ | fun opDataNumber error", NSStringFromSelector(_cmd)] ?: @""
                    }];
                }
                return nil;
            }
            NSUInteger lastDataNum = [[stackFuncOpDataNumber lastObject] intValue] + 1;
            [stackFuncOpDataNumber removeLastObject];
            [stackFuncOpDataNumber addObject:@(lastDataNum)];
        } else if ([node isKindOfClass:[BDRERightSplitNode class]]) {
            BDREBaseNode *peekNode = [stack lastObject];
            while (![peekNode isKindOfClass:[BDRELeftSplitNode class]]) {
                [stack removeLastObject];
                if ([peekNode isKindOfClass:[BDREOperatorNode class]]) {
                    BDREOperatorNode *opn = (BDREOperatorNode *)peekNode;
                    [commandArray addObject:[[BDREOperatorCommand alloc] initWithOperator:opn.opetator]];
                }
                peekNode = [stack lastObject];
            }
            [stack removeLastObject];
            if (stack.count > 0) {
                peekNode = [stack lastObject];
                if ([peekNode isKindOfClass:[BDREFuncNode class]]) {
                    if (stackFuncOpDataNumber.count <= 0) {
                        if (error) {
                            *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRINVALID_EXPRESS userInfo:@{
                                NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ | fun opDataNumber error", NSStringFromSelector(_cmd)] ?: @""
                            }];
                        }
                        return nil;
                    }
                    BDREFuncNode *fn = (BDREFuncNode *)peekNode;
                    NSUInteger lastDataNum = [[stackFuncOpDataNumber lastObject] intValue];
                    [stackFuncOpDataNumber removeLastObject];
                    [commandArray addObject:[[BDREFunctionCommand alloc] initWithFuncName:fn.funcName func:fn.func argsLength:lastDataNum]];
                    [stack removeLastObject];
                }
            }
        } else if ([node isKindOfClass:[BDREOperatorNode class]]) {
            BDREBaseNode *peekNode = [stack lastObject];
            while (stack.count > 0 && node.priority <= peekNode.priority) {
                [stack removeLastObject];
                BDREOperatorNode *opn = (BDREOperatorNode *)peekNode;
                [commandArray addObject:[[BDREOperatorCommand alloc] initWithOperator:opn.opetator]];
                if (stack.count > 0) peekNode = [stack lastObject];
            }
            [stack addObject:node];
        } else if ([node isKindOfClass:[BDREFuncNode class]]) {
            BDREBaseNode *peekNode = [stack lastObject];
            while (stack.count > 0 && node.priority <= peekNode.priority) {
                peekNode = [stack lastObject];
                [stack removeLastObject];
                BDREOperatorNode *opn = (BDREOperatorNode *)peekNode;
                [commandArray addObject:[[BDREOperatorCommand alloc] initWithOperator:opn.opetator]];
            }
            [stack addObject:node];
        }
    }
    while (stack.count > 0) {
        BDREBaseNode *peekNode = [stack lastObject];
        [stack removeLastObject];
        if ([peekNode isKindOfClass:[BDREOperatorNode class]]) {
            BDREOperatorNode *opn = (BDREOperatorNode *)peekNode;
            [commandArray addObject:[[BDREOperatorCommand alloc] initWithOperator:opn.opetator]];
        } else if ([peekNode isKindOfClass:[BDREConstNode class]]) {
            BDREConstNode *cn = (BDREConstNode *)peekNode;
            [commandArray addObject:[[BDREValueCommand alloc] initWithValue:[cn getValue]]];
        } else if ([peekNode isKindOfClass:[BDREFuncNode class]]) {
            if (stackFuncOpDataNumber.count <= 0) {
                if (error) {
                    *error = [NSError errorWithDomain:BDExpressionErrorDomain code:BDREEXPRINVALID_EXPRESS userInfo:@{
                        NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ | fun opDataNumber error", NSStringFromSelector(_cmd)] ?: @""
                    }];
                }
                return nil;
            }
            BDREFuncNode *fn = (BDREFuncNode *)peekNode;
            NSUInteger lastDataNum = [[stackFuncOpDataNumber lastObject] intValue];
            [stackFuncOpDataNumber removeLastObject];
            [commandArray addObject:[[BDREFunctionCommand alloc] initWithFuncName:fn.funcName func:fn.func argsLength:lastDataNum]];
        }
    }
    return commandArray;
}

@end
