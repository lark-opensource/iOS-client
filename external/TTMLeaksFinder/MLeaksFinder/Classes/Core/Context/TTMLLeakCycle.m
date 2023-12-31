//
//  TTMLLeakCycle.m
//  TTMLeaksFinder
//
//  Created by maruipu on 2020/11/3.
//

#import "TTMLLeakCycle.h"
#import "TTMLCommon.h"
#import <FBRetainCycleDetector/FBObjectiveCGraphElement.h>
#import <FBRetainCycleDetector/FBBlockStrongLayout.h>

@implementation TTMLLeakCycle

@end

static NSArray<id<TTMLLeakCycleNodeInterpreter>> *_interpreters;
static dispatch_semaphore_t _semaphore;

TTML_REGISTRATION {
    _semaphore = dispatch_semaphore_create(1);
    _interpreters = @[];
}

static NSArray<id<TTMLLeakCycleNodeInterpreter>>* getInterpreters() {
    NSArray<id<TTMLLeakCycleNodeInterpreter>> *snap = nil;
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    snap = _interpreters;
    dispatch_semaphore_signal(_semaphore);
    return snap;
}

@interface TTMLLeakCycleNode ()

@end

@implementation TTMLLeakCycleNode

+ (void)registerInterpreter:(NSArray<id<TTMLLeakCycleNodeInterpreter>> *)interpreters {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    NSMutableArray *muteValue = [NSMutableArray arrayWithArray:(_interpreters)];
    [muteValue addObjectsFromArray:interpreters];
    _interpreters = [muteValue copy];
    dispatch_semaphore_signal(_semaphore);
}

+ (void)removeAllInterpreters {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    _interpreters = @[];
    dispatch_semaphore_signal(_semaphore);
}

+ (instancetype)cycleNodeWithElement:(FBObjectiveCGraphElement *)element index:(NSUInteger)index; {
    TTMLLeakCycleNode *node = [[TTMLLeakCycleNode alloc] init];
    __strong id object = element.object;
    node->_path = element.namePath ?: @[];
    node->_className = [element classNameOrNull];
    node->_isBlock = FBObjectIsBlock((__bridge void *)object);
    node->_index = index;
    node->_extra = [[NSMutableDictionary alloc] init];
    for (id<TTMLLeakCycleNodeInterpreter> inter in getInterpreters()) {
        if ([inter respondsToSelector:@selector(interpretCycleNode:withObject:)]) {
            [inter interpretCycleNode:node withObject:object];
        }
    }
    return node;
}

@end
