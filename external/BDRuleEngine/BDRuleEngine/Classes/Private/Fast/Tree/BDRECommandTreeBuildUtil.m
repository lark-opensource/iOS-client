//
//  BDRECommandTreeBuildUtil.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/12.
//

#import "BDRECommandTreeBuildUtil.h"
#import "BDREOperatorCommand.h"
#import "BDREFunctionCommand.h"

#pragma mark - Implementation

@implementation BDRECommandTreeBuildUtil

+ (BDRETreeNode *)generateWithCommands:(NSArray<BDRECommand *> *)commands
{
    NSMutableArray<BDRETreeNode *> *stack = [NSMutableArray array];
    
    for (BDRECommand *command in commands) {
        BDRETreeNode *node = nil;
        NSInteger argsCount = 0;
        if ([command isKindOfClass:BDREFunctionCommand.class]) {
            argsCount = ((BDREFunctionCommand *)command).argsNumber;
        } else if ([command isKindOfClass:BDREOperatorCommand.class]) {
            argsCount = ((BDREOperatorCommand *)command).opDataNumber;
        }
        NSArray<BDRETreeNode *> *children = nil;
        if (argsCount > 0) {
            if (stack.count >= argsCount) {
                children = [stack subarrayWithRange:NSMakeRange(stack.count - argsCount, argsCount)];
                [stack removeObjectsInRange:NSMakeRange(stack.count - argsCount, argsCount)];
            } else {
                // error
                return nil;
            }
        }
        node = [[BDRETreeNode alloc] initWithCommand:command children:children];
        [stack addObject:node];
    }
    
    if (stack.count != 1) {
        // error
        return nil;
    }
    return [stack lastObject];
}

@end
