//
//  MLeaksFinder.m
//  MLeaksFinder
//
//  Created by xushuangqing on 2019/8/12.
//

#import "TTMLDetectRetainCycleOperation.h"
#import <FBRetainCycleDetector/FBRetainCycleDetector.h>
#import "TTMLLeakContext.h"
#import "MLCycleKeyClassDetector.h"
#import <FBRetainCycleDetector/FBBlockStrongLayout.h>
#import "TTMLUtils.h"
#import "TTMLeaksSizeCalculator.h"


typedef void(^TTMLDetectCompletionBlock)(BOOL found);

@interface TTMLGraphNode (Context)

- (BOOL)isAnyParentNodeLeaked;

@end

@implementation TTMLGraphNode (Context)

// 主线程调用
- (BOOL)isAnyParentViewIsReusing {
    TTMLGraphNode *currentNode = self;
    if ([currentNode.object isKindOfClass:[UIView class]]) {
        UIView *view = (UIView *)currentNode.object;
        if (view.window && [[UIApplication sharedApplication].windows containsObject:view.window]) {
            return YES;
        }
    }
    if ([currentNode.object isKindOfClass:[UIViewController class]]) {
        UIViewController *vc = (UIViewController *)currentNode.object;
        if ([vc isViewLoaded]) {
            if (vc.view.window && [[UIApplication sharedApplication].windows containsObject:vc.view.window]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)isAnyParentNodeLeaked {
    TTMLGraphNode *currentNode = self;
    while (currentNode) {
        if ([[TTMLLeakContextMap sharedInstance] ttml_hasRetainCycleOf:currentNode.object]) {
            return YES;
        }
        currentNode = currentNode.parent;
    }
    return NO;
}

- (NSArray<NSString *> *)viewStack {
    NSMutableArray *viewStackArray = [[NSMutableArray alloc] init];
    TTMLGraphNode *currentNode = self;
    while (currentNode) {
        [viewStackArray insertObject:currentNode.clazzName atIndex:0];
        currentNode = currentNode.parent;
    }
    return [viewStackArray copy];
}

@end


@interface TTMLDetectRetainCycleOperation()

@property (atomic, strong) TTMLGraphNode *node;
@property (atomic, strong) TTMLGraphNode *rootNode; // retain root node for isAnyParentNodeLeaked and viewStack
@property (atomic, strong) FBObjectGraphConfiguration *graphConfiguration;
@property (atomic, assign) NSInteger maxCycleLength;
@property (atomic, copy) TTMLDetectRetainCycleCompletionBlock operationCompletionBlock;

//new property
@property (nonatomic,assign) BOOL needCalculateLeakSize;
@end

@implementation TTMLDetectRetainCycleOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (id)initWithNode:(TTMLGraphNode *)node
          rootNode:(TTMLGraphNode *)rootNode
 graphConfiguraion:(FBObjectGraphConfiguration *)graphConfiguration
    maxCycleLength:(NSInteger)maxCycleLength
   completionBlock:(TTMLDetectRetainCycleCompletionBlock)completionBlock {
    self = [super init];
    if (self) {
        self.node = node;
        self.rootNode = rootNode;
        self.graphConfiguration = graphConfiguration;
        self.maxCycleLength = maxCycleLength;
        self.operationCompletionBlock = completionBlock;
        self.needCalculateLeakSize = false;
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
    id nodeObject = self.node.object;
    uint64_t detectRetainCycleTick = TTMLCurrentMachTime();
    [self startDetectRetainCycleIfNeedWithCompletionBlock:^(BOOL found) {
        [self doneWithFound:found];
//        double detectRetainCycleDuration = TTMLMachTimeToSecs(TTMLCurrentMachTime() - detectRetainCycleTick);
//        if (detectRetainCycleDuration > 1.0) {
//            NSLog(@"%@%@%@", self.node.clazzName,@"找环耗费时间(S):",@(detectRetainCycleDuration));
//        }
//        if ([[TTMLeaksFinder memoryLeaksConfig].delegateClass respondsToSelector:@selector(trackService:metric:category:extra:)]) {
//            [[TTMLeaksFinder memoryLeaksConfig].delegateClass trackService:@"mleaks_detect_cycle_duration" metric:@{@"duration":@(detectRetainCycleDuration*1000.0)} category:nil extra:nil];
//        }
        dispatch_async(dispatch_get_main_queue(), ^{
            (void)(nodeObject);// release the object in main thread
        });
    }];
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

- (void)doneWithFound:(BOOL)found {
//    NSLog(@"%@ done...", self);
    self.executing = NO;
    self.finished = YES;
    if (self.operationCompletionBlock) {
        if (found) {
            self.operationCompletionBlock(self.node.object);
        }
        else {
            self.operationCompletionBlock(nil);
        }
    }
    
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, rootNode=%@", [super description], self.node];
}

#pragma mark - Operation

- (void)startDetectRetainCycleIfNeedWithCompletionBlock:(TTMLDetectCompletionBlock)completionBlock {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.node isAnyParentViewIsReusing]) {
            if (completionBlock) {
                completionBlock(NO);
            }
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            // if any parent has retain cycles
            if ([self.node isAnyParentNodeLeaked]) {//Todo，这个是否会漏掉循环引用检测？@langminglang 同时需要注意这个如果去掉， TTMLLeakContextMap 不能保证线程安全(所谓线程不安全指主线程+operation线程同时操作一个obect的context）
                if (completionBlock) {
                    completionBlock(NO);
                }
                return;
            }
            
            FBRetainCycleDetector *detector = [[FBRetainCycleDetector alloc] initWithConfiguration:self.graphConfiguration];
            
            id nodeObject = self.node.object;
            
            if (!nodeObject) {
                if (completionBlock) {
                    completionBlock(NO);
                }
                return;
            }
            [detector addCandidate:nodeObject];
            
//            [NSThread sleepForTimeInterval:1.0];
            
            NSMutableSet *targetRetainCycles = [NSMutableSet set];
            
            @try {
                // 最大深度还需观察
                NSSet *retainCycles = [detector findRetainCyclesWithMaxCycleLength:TTMLStackDepthInDetectRetainCycleOperation maxTraversedNodeNumber:TTMLOneClassOnceDetectRetainMaxTraversedNodeNumber maxCycleNum:TTMLOneClassOnceDetectRetainCycleMaxCount];
                
                for (NSArray *retainCycle in retainCycles) {
                    for (FBObjectiveCGraphElement *element in retainCycle) {
                        if (element.object == nodeObject) {
                            [targetRetainCycles addObject:retainCycle];
                            break;
                        }
                    }
                }
            } @catch (NSException *exception) {
                if (completionBlock) {
                    completionBlock(NO);
                }
            } @finally {
                
            }
            
            if (targetRetainCycles.count) {
                NSMutableArray<TTMLLeakCycle *> *leakCycles = [NSMutableArray array];
                [targetRetainCycles enumerateObjectsUsingBlock:^(NSArray *retainCycle, BOOL * _Nonnull stop) {
                    TTMLLeakCycle *leakCycle = [[TTMLLeakCycle alloc] init];
                    NSMutableArray<NSString *> *customClassNames = [NSMutableArray array];
                    
                    //find key class
                    cyle_key_class cycleKeyClassInfo = [MLCycleKeyClassDetector keyClassNameForRetainCycle:retainCycle];
                    leakCycle.keyClassName = (cycleKeyClassInfo.keyClassName ?: @"");
                    
                    // find key class of cal leak size 
                    id keyObject = nil;
                    if (cycleKeyClassInfo.keyClassName && [retainCycle[cycleKeyClassInfo.index] isKindOfClass:[FBObjectiveCGraphElement class]]) {
                        FBObjectiveCGraphElement *element = (FBObjectiveCGraphElement *)retainCycle[cycleKeyClassInfo.index];
                        keyObject = element.object;
                    }
                    
                    // cal leak size
                    if (keyObject && self.needCalculateLeakSize) {
                        leakCycle.leakSize = [NSString stringWithFormat:@"%ld B", lround([[TTMLeaksSizeCalculator class] tt_memoryUseOfObj:keyObject])];
                    }
                    
                    NSMutableString *cycleDescription = [@"cycle: " mutableCopy];
                    
                    // 由于从同一个环的不同节点启动找环，可能会找到不同的环，生成不同的id，因此将环做一个排序
                    // 找到数组里字典序最大，然后整个数组shift
                    __block NSInteger maxIndex = 0;
                    __block NSString *maxString = @"";
                    __block BOOL hasRAC = NO;
                    NSMutableArray<NSString *> *allClassNames = [NSMutableArray array];
                    [retainCycle enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj isKindOfClass:[FBObjectiveCGraphElement class]]) {
                            FBObjectiveCGraphElement *element = (FBObjectiveCGraphElement *)obj;
                            if (element.object == nil || object_getClass(element.object) == nil) {
                                //pass
                            }
                            else if ([TTMLUtil objectIsSystemClass:element.object]) {
                                // pass
                            }
                            else if (FBObjectIsBlock((__bridge void *)element.object)) {
                                // pass
                            }
                            else if ([[element classNameOrNull] hasPrefix:@"RAC"]) {
                                // pass
                                hasRAC = YES;
                            }
                            else {
                                [customClassNames addObject:[element classNameOrNull]];
                            }
                            [allClassNames addObject:[element classNameOrNull]];
                        }
                        if ([[obj description] compare:maxString] == kCFCompareGreaterThan) {
                            maxString = [obj description];
                            maxIndex = idx;
                        }
                    }];
                    
                    if ([customClassNames count] < 3 && !hasRAC) {
                        customClassNames = allClassNames;
                    }
                    
                    // 将 cycle 里面的有效类抽取出来，排序后做一个 string，用这个 string 的 md5 用于问题去重
                    NSString *namesString = @"";
                    if ([customClassNames count] > 0) {
                        [customClassNames sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                            return [[obj1 description] compare:[obj2 description]];
                        }];
                        namesString = [customClassNames componentsJoinedByString:@","];
                    }
                    leakCycle.className = namesString;
                    
                    NSInteger length = [retainCycle count];
                    NSArray *post = [retainCycle subarrayWithRange:(NSRange){ .location = maxIndex, .length = length - maxIndex }];
                    NSArray *pre = [retainCycle subarrayWithRange:(NSRange){ .location = 0, .length = maxIndex}];
                    retainCycle = [post arrayByAddingObjectsFromArray:pre];
                    
                    NSMutableArray<TTMLLeakCycleNode *> *cycleNodes = [NSMutableArray array];
                    [retainCycle enumerateObjectsUsingBlock:
                        ^(FBObjectiveCGraphElement *obj, NSUInteger idx, BOOL *stop) {
                        [cycleDescription appendFormat:@"%d. %@",(int)idx, [obj description]];
                        [cycleNodes addObject:[TTMLLeakCycleNode cycleNodeWithElement:obj index:idx]];
                    }];
                    leakCycle.retainCycle = cycleDescription;
                    leakCycle.nodes = [cycleNodes copy];
                
                    
                    [leakCycles addObject:leakCycle];
                }];
                TTMLLeakContext *leakContext = [[TTMLLeakContextMap sharedInstance] ttml_leakContextOf:nodeObject];
                leakContext.cycles = [leakCycles copy];
                leakContext.viewStack = [self.node viewStack];
            }
            
            if (completionBlock) {
                completionBlock((targetRetainCycles.count > 0));
            }
        });
    });
}



@end
