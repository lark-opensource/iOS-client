//
//  LKREExprGrammer.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREExprGrammer.h"
#import "LKREExprRunner.h"
#import "LKREConstNode.h"
#import "LKREIdentifierNode.h"
#import "LKRESplitNode.h"
#import "LKREOperatorNode.h"
#import "LKREFuncNode.h"
#import "LKREValueCommand.h"
#import "LKREOperatorCommand.h"
#import "LKREFunctionCommand.h"
#import "LKREIdentifierCommand.h"

@implementation LKREExprGrammer

+ (NSArray *)parseNodesToCommands:(NSArray *)nodes error:(NSError **)error {
    NSMutableArray *commandArray = [[NSMutableArray alloc] init];
    NSMutableArray *stack = [[NSMutableArray alloc] init];
    NSMutableArray *stackFuncOpDataNumber = [[NSMutableArray alloc] init];
    for (int i = 0; i < nodes.count; i++) {
        LKREBaseNode *node = nodes[i];
        if ([node isKindOfClass:[LKREConstNode class]]) {
            [commandArray addObject:[[LKREValueCommand alloc] initWithValue:[(LKREConstNode *)node getValue]]];
        } else if ([node isKindOfClass:[LKREIdentifierNode class]]) {
            LKREIdentifierNode *idN = (LKREIdentifierNode *)node;
            [commandArray addObject:[[LKREIdentifierCommand alloc] initWithIdentifier:idN.identifier]];
        } else if ([node isKindOfClass:[LKRELeftSplitNode class]]) {
            [stack addObject:node];
            LKRELeftSplitNode *lsN = (LKRELeftSplitNode *)node;
            if (lsN.isFunctionStart) {
                if (nodes.count > i + 1 && [nodes[i+1] isKindOfClass:[LKRERightSplitNode class]]){
                    [stackFuncOpDataNumber addObject:@(0)];
                } else {
                    [stackFuncOpDataNumber addObject:@(1)];
                }

            } else if ([lsN.aOriginValue isEqualToString:@"["]) {
                *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_EXPRESS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | Variable identifier not closed, wordIndex:%@", NSStringFromSelector(_cmd), @(lsN.wordIndex)]}];
                return nil;
            }
        } else if ([node isKindOfClass:[LKRECenterSplitNode class]]) {
            LKREBaseNode *peekNode = [stack lastObject];
            LKRELeftSplitNode *lsn = nil;
            if ([peekNode isKindOfClass:[LKRELeftSplitNode class]]) {
                lsn = (LKRELeftSplitNode *)peekNode;
            }
            while (![peekNode isKindOfClass:[LKRELeftSplitNode class]] || (lsn != nil && !lsn.isFunctionStart)) {
                [stack removeLastObject];
                if ([peekNode isKindOfClass:[LKREOperatorNode class]]) {
                    LKREOperatorNode *opn = (LKREOperatorNode *)peekNode;
                    [commandArray addObject:[[LKREOperatorCommand alloc] initWithOperator:opn.opetator]];
                }
                lsn = nil;
                peekNode = [stack lastObject];
                if ([peekNode isKindOfClass:[LKRELeftSplitNode class]]) {
                    lsn = (LKRELeftSplitNode *)peekNode;
                }
                if (peekNode == nil) {
                    *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRUNKNOWN_CAUSE userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | found unexpect ',' word index: %@", NSStringFromSelector(_cmd), @(i)]}];
                    return nil;
                }
            }
            if (stackFuncOpDataNumber.count <= 0) {
                *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_EXPRESS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | fun opDataNumber error", NSStringFromSelector(_cmd)]}];
                return nil;
            }
            NSUInteger lastDataNum = [[stackFuncOpDataNumber lastObject] intValue] + 1;
            [stackFuncOpDataNumber removeLastObject];
            [stackFuncOpDataNumber addObject:@(lastDataNum)];
        } else if ([node isKindOfClass:[LKRERightSplitNode class]]) {
            LKREBaseNode *peekNode = [stack lastObject];
            while (![peekNode isKindOfClass:[LKRELeftSplitNode class]]) {
                [stack removeLastObject];
                if ([peekNode isKindOfClass:[LKREOperatorNode class]]) {
                    LKREOperatorNode *opn = (LKREOperatorNode *)peekNode;
                    [commandArray addObject:[[LKREOperatorCommand alloc] initWithOperator:opn.opetator]];
                }
                peekNode = [stack lastObject];
            }
            [stack removeLastObject];
            if (stack.count > 0) {
                peekNode = [stack lastObject];
                if ([peekNode isKindOfClass:[LKREFuncNode class]]) {
                    if (stackFuncOpDataNumber.count <= 0) {
                        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_EXPRESS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | fun opDataNumber error", NSStringFromSelector(_cmd)]}];
                        return nil;
                    }
                    LKREFuncNode *fn = (LKREFuncNode *)peekNode;
                    NSUInteger lastDataNum = [[stackFuncOpDataNumber lastObject] intValue];
                    [stackFuncOpDataNumber removeLastObject];
                    [commandArray addObject:[[LKREFunctionCommand alloc] initWithFunc:fn.getFunc argsLength:lastDataNum]];
                    [stack removeLastObject];
                }
            }
        } else if ([node isKindOfClass:[LKREOperatorNode class]]) {
            LKREBaseNode *peekNode = [stack lastObject];
            while (stack.count > 0 && node.priority <= peekNode.priority) {
                [stack removeLastObject];
                LKREOperatorNode *opn = (LKREOperatorNode *)peekNode;
                [commandArray addObject:[[LKREOperatorCommand alloc] initWithOperator:opn.opetator]];
                if (stack.count > 0) peekNode = [stack lastObject];
            }
            [stack addObject:node];
        } else if ([node isKindOfClass:[LKREFuncNode class]]) {
            LKREBaseNode *peekNode = [stack lastObject];
            while (stack.count > 0 && node.priority <= peekNode.priority) {
                peekNode = [stack lastObject];
                [stack removeLastObject];
                LKREOperatorNode *opn = (LKREOperatorNode *)peekNode;
                [commandArray addObject:[[LKREOperatorCommand alloc] initWithOperator:opn.opetator]];
            }
            [stack addObject:node];
        }
    }
    while (stack.count > 0) {
        LKREBaseNode *peekNode = [stack lastObject];
        [stack removeLastObject];
        if ([peekNode isKindOfClass:[LKREOperatorNode class]]) {
            LKREOperatorNode *opn = (LKREOperatorNode *)peekNode;
            [commandArray addObject:[[LKREOperatorCommand alloc] initWithOperator:opn.opetator]];
        } else if ([peekNode isKindOfClass:[LKREConstNode class]]) {
            LKREConstNode *cn = (LKREConstNode *)peekNode;
            [commandArray addObject:[[LKREValueCommand alloc] initWithValue:[cn getValue]]];
        } else if ([peekNode isKindOfClass:[LKREFuncNode class]]) {
            if (stackFuncOpDataNumber.count <= 0) {
                *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:LKREEXPRINVALID_EXPRESS userInfo:@{@"reason" : [NSString stringWithFormat:@"%@ | fun opDataNumber error", NSStringFromSelector(_cmd)]}];
                return nil;
            }
            LKREFuncNode *fn = (LKREFuncNode *)peekNode;
            NSUInteger lastDataNum = [[stackFuncOpDataNumber lastObject] intValue];
            [stackFuncOpDataNumber removeLastObject];
            [commandArray addObject:[[LKREFunctionCommand alloc] initWithFunc:fn.getFunc argsLength:lastDataNum]];
        }
    }
    return commandArray;
}

@end
