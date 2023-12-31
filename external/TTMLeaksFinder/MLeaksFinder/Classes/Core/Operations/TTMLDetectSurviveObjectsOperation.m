//
//  MLeaksFinder.m
//  MLeaksFinder
//
//  Created by xushuangqing on 2019/8/12.
//

#import "TTMLDetectSurviveObjectsOperation.h"
#import <FBRetainCycleDetector/FBObjectiveCGraphElement.h>
#import <FBRetainCycleDetector/FBRetainCycleDetector.h>
#import <FBRetainCycleDetector/FBNodeEnumerator.h>
#import <FBRetainCycleDetector/FBRetainCycleUtils.h>
#import <FBRetainCycleDetector/FBBlockStrongLayout.h>
#import "TTMLLeakContext.h"
#import "TTMLUtils.h"

@interface TTMLDetectSurviveObjectsOperation ()

@property (atomic, strong) TTMLGraphNode *rootNode;
@property (atomic, strong) NSMutableArray<TTMLGraphNode *> *surviveNodes;
@property (atomic, copy) TTMLDetectSurviveObjectsCompletionBlock operationCompletionBlock;

@end

@implementation TTMLDetectSurviveObjectsOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

#pragma mark - NSOpeartion Life Cycle

- (id)initWithRootNode:(TTMLGraphNode *)rootNode completion:(TTMLDetectSurviveObjectsCompletionBlock)completionBlock {
    self = [super init];
    if (self) {
        self.rootNode = rootNode;
        self.surviveNodes = [[NSMutableArray alloc] init];
        self.operationCompletionBlock = completionBlock;
    }
    return self;
}

- (void)start {
    if (self.isCancelled) {
        self.executing = NO;
        self.finished = YES;
        return;
    }
    self.executing = YES;
    [self enumerateRemainingObjectsForGraph:self.rootNode];
    [self done];
}

- (void)setFinished:(BOOL)finished {
    if (_finished == finished) {
        return;
    }
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    if (_executing == executing) {
        return;
    }
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)cancel {
//    NSLog(@"%@ cancelled...", self);
    [super cancel];
}

- (void)done {
//    NSLog(@"%@ done...", self);
    self.executing = NO;
    self.finished = YES;
    if (self.operationCompletionBlock) {
        self.operationCompletionBlock(self.surviveNodes);
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, rootNode=%@", [super description], self.rootNode];
}

#pragma mark - Operation

#define DISCOVERED 1
#define VISITED 2

//在异步线程调用
- (void)enumerateRemainingObjectsForGraph:(TTMLGraphNode *)node{
    
    if (!node) {
        return;
    }
    
    //NSMutableArray<NSNumber *> *checkedObjectsPtrs = [[NSMutableArray alloc] init];
    
    //__block int traversCount = 0;
    NSMutableDictionary<NSString *, NSNumber *> *enumeratedClasses = [[NSMutableDictionary alloc] init];
    
    BOOL(^block)(TTMLGraphNode * _Nonnull node) = ^BOOL(TTMLGraphNode * _Nonnull node) {
        id nodeObject = node.object;//将 node.object 强持有一下
        if (!nodeObject || object_getClass(nodeObject) == nil) {
            return NO;
        }
        if ([[TTMLLeakContextMap sharedInstance] ttml_hasRetainCycleOf:nodeObject]) {
            return YES; //如果这个对象已经被找到了环，就不再重复找
        }
        NSInteger classEnumeratedCount = [[enumeratedClasses objectForKey:NSStringFromClass([nodeObject class])] integerValue];
        if (classEnumeratedCount >= TTMLOneClassCheckMaxCount) {
            return NO;
        }
        if ([TTMLUtil objectIsSystemClass:nodeObject]) {
            return NO;
        }
        if ([NSStringFromClass([nodeObject class]) hasPrefix:@"RAC"]) {
            return NO;
        }
        if (FBObjectIsBlock((__bridge void *)nodeObject)) {//block，持有 block 的一定存活，所以block 不需要再单独保存
            return NO;
        }
        
        [self.surviveNodes addObject:node];//这里后续可以注意一下有什么不应该suriver 的surive了，然后在这里跳过@langminglang
        
        [enumeratedClasses setObject:@(classEnumeratedCount+1) forKey:NSStringFromClass([nodeObject class])];
        
        return NO;
    };
    
    NSMutableArray *queue = [NSMutableArray new];
    NSMutableDictionary<NSNumber *, NSNumber *> *statusMap = [NSMutableDictionary new];
    [queue addObject:node];
    statusMap[@((size_t)node)] = @(DISCOVERED);
    while (queue.count) {
        TTMLGraphNode *current = [queue objectAtIndex:0];
        [queue removeObjectAtIndex:0];
        BOOL hasValidCycle = NO;

        if (block) {
            hasValidCycle = block(current);
        }
        
        if (hasValidCycle) { //如果这一节点【未释放且有环】，那么它的孩子节点肯定未释放，不需要重复去找孩子节点的环了。⚠️仅仅不释放仍然需要找child，因为环不一定位于哪个节点
            //如果当前节点和child有两个环，会漏掉child的环@langminglang
        }
        else {
            for (TTMLGraphNode *child in current.children) {
                if (!statusMap[@((size_t)child)]) {
                    statusMap[@((size_t)child)] = @(DISCOVERED);
                    [queue addObject:child];
                }
                else {
                    
                }
            }
        }
        statusMap[@((size_t)current)] = @(VISITED);
    }
}

@end

