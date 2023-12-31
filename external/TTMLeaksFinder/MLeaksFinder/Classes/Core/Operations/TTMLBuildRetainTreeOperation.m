//
//  MLeaksFinder.m
//  MLeaksFinder
//
//  Created by xushuangqing on 2019/8/12.
//

#import "TTMLBuildRetainTreeOperation.h"
#import <FBRetainCycleDetector/FBObjectGraphConfiguration.h>
#import <FBRetainCycleDetector/FBRetainCycleUtils.h>
#import <FBRetainCycleDetector/FBBlockStrongLayout.h>
#import <sys/sysctl.h>
#import <mach/mach_time.h>
#import "TTMLUtils.h"
#import "TTMLLeakContext.h"

@interface TTMLBuildRetainTreeOperation ()<TTMLNodeAddChildrenDelegate>

@property (atomic, strong, readwrite) id rootObject;
@property (atomic, assign, readwrite) size_t rootAddress;

@property (atomic, assign) BOOL needNormalRetainTree;
@property (atomic, strong) FBObjectGraphConfiguration *graphConfiguration;
@property (atomic, assign) NSInteger stackDepth;
@property (atomic, strong) TTMLGraphNode *rootNode;
@property (atomic, copy) TTMLBuildRetainTreeCompletionBlock operationCompletionBlock;
@property (atomic, strong) NSMutableArray<TTMLBuildRetainTreeCompletionBlock> *addedCompletionBlockArray;

@property (atomic, copy) NSDictionary<NSNumber *, TTMLGraphNode *> *viewVCTreeDict;

@property (atomic, assign) uint64_t beginTimeStamp;

//new property
//@property(nonatomic,assign) int enableDetectSystemClass;

@end

@implementation TTMLBuildRetainTreeOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (id)initWithRootObject:(id)rootObject
    needNormalRetainTree:(BOOL)needNormalRetainTree
       graphConfiguraion:(FBObjectGraphConfiguration *)graphConfiguration
              stackDepth:(NSInteger)stackDepth
         completionBlock:(TTMLBuildRetainTreeCompletionBlock)completionBlock {
    self = [super init];
    if (self) {
        self.queuePriority = NSOperationQueuePriorityHigh;
        
        self.rootObject = rootObject;
        self.rootAddress = (size_t)rootObject;
        self.needNormalRetainTree = needNormalRetainTree;
        self.graphConfiguration = graphConfiguration;
        self.stackDepth = stackDepth;
        self.operationCompletionBlock = completionBlock;
        self.addedCompletionBlockArray = [[NSMutableArray alloc] init];
//        self.enableDetectSystemClass = 0;
    }
    return self;
}

#pragma mark - NSOpeartion Life Cycle

- (void)start {
    if (self.isCancelled) {
        self.executing = NO;
        self.finished = YES;
        return;
    }
    self.executing = YES;
    
//    NSLog(@"%@ started...", self);
    self.beginTimeStamp = TTMLCurrentMachTime();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
//        uint64_t mainThreadTick = TTMLCurrentMachTime();
        [self buildViewVCTree];
//        double mainThreadDuration = TTMLMachTimeToSecs(TTMLCurrentMachTime() - mainThreadTick);
//        if ([[TTMLeaksFinder memoryLeaksConfig].delegateClass respondsToSelector:@selector(trackService:metric:category:extra:)]) {
//            [[TTMLeaksFinder memoryLeaksConfig].delegateClass trackService:@"mleaks_main_thread_build_tree_duraton" metric:@{@"duration":@(mainThreadDuration*1000.0)} category:nil extra:nil];
//        }
        
        if (self.needNormalRetainTree) {
            dispatch_async(dispatch_get_global_queue(NSOperationQueuePriorityNormal, 0), ^{
                [self buildNormalRetainTree];
                [self done];
            });
        }
        else {
            [self done];
        }
    });
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
    dispatch_async(dispatch_get_main_queue(), ^{
        //NSLog(@"主线程释放强持有");
        self.rootObject = nil; //主线程释放
    });
    if (self.operationCompletionBlock) {
        self.operationCompletionBlock(self.rootNode);
    }
    [self.addedCompletionBlockArray enumerateObjectsUsingBlock:^(TTMLBuildRetainTreeCompletionBlock  _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
        block(self.rootNode);
    }];
//    NSTimeInterval totalDuration = TTMLMachTimeToSecs(TTMLCurrentMachTime() - self.beginTimeStamp);
//    //NSLog(@"%@%@%@", self.rootNode.clazzName,@"bulid tree time(s):",@(totalDuration));
//    if ([[TTMLeaksFinder memoryLeaksConfig].delegateClass respondsToSelector:@selector(trackService:metric:category:extra:)]) {
//        [[TTMLeaksFinder memoryLeaksConfig].delegateClass trackService:@"mleaks_build_tree_duraton" metric:@{@"duration":@(totalDuration*1000.0)} category:nil extra:nil];
//    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, root=%@", [super description], self.rootObject];
}

#pragma mark - Operation

- (void)addCompletionBlock:(TTMLBuildRetainTreeCompletionBlock)completionBlock {
    [self.addedCompletionBlockArray addObject:completionBlock];
}

//构建 View VC 树，必须在主线程执行，应该是兼容swift的
- (void)buildViewVCTree {
    
    if (![self isValidViewVC:self.rootObject] || [self isInWhiteList:self.rootObject]) {
        return;
    }
    
    TTMLGraphNode *rootNode = [[TTMLGraphNode alloc] initWithObject:self.rootObject];
    self.rootNode = rootNode;
    NSMutableDictionary<NSNumber *, TTMLGraphNode *> *viewVCTreeDict = [[NSMutableDictionary alloc] init];
    
    [viewVCTreeDict setObject:rootNode forKey:@((size_t)rootNode.object)];
        
    //先用广度优先遍历的方式，把所有 View VC 都遍历出来
    NSMutableArray *queue = [[NSMutableArray alloc] init];
    [queue addObject:self.rootObject];
        
    while (queue.count > 0) {
        id popedObject = [queue objectAtIndex:0];
        TTMLGraphNode *rootNode = [viewVCTreeDict objectForKey:@((size_t)popedObject)];
        
        [queue removeObjectAtIndex:0];
        
        NSSet *chilren = [self viewVCChildrenFor:popedObject];
        for (id child in chilren) {
        
            if ([viewVCTreeDict objectForKey:@((size_t)child)]) {
                //已经访问过，不再访问
                continue;
            }
            else if ([self isInWhiteList:child]) {
                //白名单，不再访问
                continue;
            }
                
            [queue addObject:child];
                
            TTMLGraphNode *childNode = [[TTMLGraphNode alloc] initWithObject:child];
            [viewVCTreeDict setObject:childNode forKey:@((size_t)child)];
            [rootNode.children addObject:childNode];
            childNode.parent = rootNode;
                
        }
    }
    
    self.viewVCTreeDict = viewVCTreeDict;
    self.rootNode = rootNode;
}

//构建普通对象树，必须在异步线程执行
- (void)buildNormalRetainTree {
    
    if ([self isInWhiteList:self.rootObject]) {
        return;
    }
    
    FBObjectiveCGraphElement *graphElement = FBWrapObjectGraphElement(nil, self.rootObject, self.graphConfiguration);
    
    NSMutableSet *objectSet = [[NSMutableSet alloc] init];
    TTMLNodeEnumerator *wrappedObject = [[TTMLNodeEnumerator alloc] initWithObject:graphElement addChildDelegate:self];
    // We will be doing DFS over graph of objects
    
    // Stack will keep current path in the graph
    NSMutableArray<TTMLNodeEnumerator *> *stack = [NSMutableArray new];
    
    // To make the search non-linear we will also keep
    // a set of previously visited nodes.
    
    // Let's start with the root
    [objectSet addObject:@([wrappedObject.object objectAddress])];
    [stack addObject:wrappedObject];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    
    while ([stack count] > 0 && [objectSet count] < TTMLBuildRetainTreeMaxNode) {
        // Algorithm creates many short-living objects. It can contribute to few
        // hundred megabytes memory jumps if not handled correctly, therefore
        // we're gonna drain the objects with our autoreleasepool.
        @autoreleasepool {
            // Take topmost node in stack and mark it as visited
            TTMLNodeEnumerator *top = [stack lastObject];
            TTMLNodeEnumerator *firstAdjacent = [top nextObject];
            id strongObject = firstAdjacent.object.object;
            if (firstAdjacent) {
                // Current node still has some adjacent not-visited nodes
                BOOL shouldPushToStack = NO;
                if ([objectSet containsObject:@([firstAdjacent.object objectAddress])]) {
                    // 不重复访问图中的节点
                }
                else if (!strongObject || object_getClass(strongObject) == nil) {
                    // 加保护，不访问找不到类的
                }
                else if ([strongObject isProxy]) {
                    // 不访问 NSProxy 等，有坑，还有些 Proxy 把 respondsToSelector 都实现了。。
                }
                else if ([strongObject isKindOfClass:[TTMLLeakContext class]]) {
                    // 不妨问 TTMLLeakContext
                }
                else if ([self isInWhiteList:strongObject]) {
                    // 不访问白名单
                }
                else if ([TTMLUtil objectIsSystemClass:strongObject]) {//系统库里的类，只访问 block、UIView、UIViewController 不然太多了
                    if ([strongObject isKindOfClass:[NSDictionary class]] || [strongObject isKindOfClass:[NSArray class]]) {
                        if (![NSJSONSerialization isValidJSONObject:strongObject]) {
                            shouldPushToStack = YES;
                        }
                    }else if (FBObjectIsBlock((__bridge void *)strongObject)) {
                        shouldPushToStack = YES;
                    }else if ( [strongObject isKindOfClass:NSClassFromString(@"__NSCFTimer")]){
                        shouldPushToStack = YES;
                    }else {
                        if([TTMLeaksFinder memoryLeaksConfig].enableDetectSystemClass == 1 && [self isValidViewVC:strongObject]){
                            shouldPushToStack = YES;
                        } else if([TTMLeaksFinder memoryLeaksConfig].enableDetectSystemClass == 2){
                            shouldPushToStack = YES;
                        }
                        // Fallback on earlier versions
                    }
                }
                else if ([dic[firstAdjacent.node.clazzName] integerValue] > TTMLOneClassBuildRetainTreeMaxCount) {
                    // 限制每个类的搜索次数@langminglang
                }
                else {
                    shouldPushToStack = YES;
                }
                
                if (shouldPushToStack) {
                    firstAdjacent.node.parent = top.node;
                    [top.node.children addObject:firstAdjacent.node];
                    [objectSet addObject:@([firstAdjacent.object objectAddress])];
                    dic[firstAdjacent.node.clazzName] = @([dic[firstAdjacent.node.clazzName] integerValue] + 1);
                    if ([stack count] < self.stackDepth) {
                        [stack addObject:firstAdjacent];
                    }
                    else {
                        //到达栈最深处，不再继续向下
                    }
                }
            } else {
                // Node has no more adjacent nodes, it itself is done, move on
                [stack removeLastObject];
            }
        }
    }
    self.rootNode = wrappedObject.node;
}

#pragma mark - utils

- (BOOL)isValidViewVC:(NSObject *)object {
    if ([object isKindOfClass:[UIView class]] || [object isKindOfClass:[UIViewController class]]) {
        return YES;
    }
    return NO;
}

- (NSSet *)viewVCChildrenFor:(id)root {
    
    NSMutableSet *children = [[NSMutableSet alloc] init];
    
    if ([root isKindOfClass:[UIView class]]) {
        [children addObjectsFromArray:[(UIView *)root subviews]];
    }
    if ([root isKindOfClass:[UISplitViewController class]]) {
        [children addObjectsFromArray:[(UISplitViewController *)root viewControllers]];
    }
    if ([root isKindOfClass:[UIPageViewController class]]) {
        [children addObjectsFromArray:[(UIPageViewController *)root viewControllers]];
    }
    if ([root isKindOfClass:[UITabBarController class]]) {
        [children addObjectsFromArray:[(UITabBarController *)root viewControllers]];
    }
    if ([root isKindOfClass:[UINavigationController class]]) {
        [children addObjectsFromArray:[(UINavigationController *)root viewControllers]];
    }
    if ([root isKindOfClass:[UIViewController class]]) {
        [children addObjectsFromArray:[(UIViewController *)root childViewControllers]];
        if ([(UIViewController *)root isViewLoaded]) {
            [children addObject:[((UIViewController *)root) view]];
        }
    }
    
    return [children copy];
}

- (BOOL)isInWhiteList:(id)obj {
    __block BOOL isInWhiteList = NO;
    [[TTMLeaksFinder classNamesWhitelist] enumerateObjectsUsingBlock:^(Class  _Nonnull whiteListClazz, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:whiteListClazz]) {
            isInWhiteList = YES;
            *stop = YES;
        }
    }];
    return isInWhiteList;
}

#pragma mark - TTMLNodeAddChildrenDelegate

- (NSSet *)addedChildrenForNodeEnumerator:(TTMLNodeEnumerator *)nodeEnumerator {
    TTMLGraphNode *node = [self.viewVCTreeDict objectForKey:@((size_t)nodeEnumerator.object.object)];
    if (!node || node.children.count < 1) {
        return nil;
    }
    
    NSMutableSet *set = [[NSMutableSet alloc] init];
    [node.children enumerateObjectsUsingBlock:^(TTMLGraphNode * _Nonnull child, NSUInteger idx, BOOL * _Nonnull stop) {
        id object = child.object;
        if (object) {
            [set addObject:object];
        }
    }];
    return [set copy];
}
@end
