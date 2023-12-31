//
//  MLeaksFinder.m
//  MLeaksFinder
//
//  Created by xushuangqing on 2019/8/12.
//

#import "TTMLOperationManager.h"
#import "TTMLBuildRetainTreeOperation.h"
#import "TTMLDetectSurviveObjectsOperation.h"
#import "TTMLDetectRetainCycleOperation.h"
#import <FBRetainCycleDetector/FBObjectGraphConfiguration.h>
#import "TTMLeakedObjectProxy.h"
#import "TTMLeaksFinder.h"
#import "TTMLUtils.h"
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <FBRetainCycleDetector/FBRetainCycleAlogDelegate.h>


extern NSArray<FBGraphEdgeFilterBlock> * MLeaksFileters;

static NSArray<FBGraphEdgeFilterBlock> *MLeaksFinderGraphEdgeFilters() {
    return MLeaksFileters;
}

@interface TTMLOperationManager()<FBFinderAlogProtocol>

// 所有未开始/进行中/已完成的构建树操作
// 直到进入 DetectSurviveObjects 步骤
@property (atomic, strong) NSMutableArray<TTMLBuildRetainTreeOperation *> *buildRetainTreeOperations;
@property (atomic, strong) NSOperationQueue *operationQueue;
@property (atomic, strong) FBObjectGraphConfiguration *graphConfiguration;

@end

@implementation TTMLOperationManager

+ (instancetype)sharedManager {
    static TTMLOperationManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.graphConfiguration = [[FBObjectGraphConfiguration alloc] initWithFilterBlocks:MLeaksFinderGraphEdgeFilters() shouldInspectTimers:YES];
        [FBRetainCycleAlogDelegate sharedDelegate].delegate = self;
        self.buildRetainTreeOperations = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)appDidEnterBackground {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.buildRetainTreeOperations enumerateObjectsUsingBlock:^(TTMLBuildRetainTreeOperation * _Nonnull operation, NSUInteger idx, BOOL * _Nonnull stop) {
            [operation cancel];
        }];
        [self.buildRetainTreeOperations removeAllObjects];
    });

}

- (void)startBuildingRetainTreeForRoot:(id)root {
    
    if (!root) {
        return;
    }
    
    // 同一时间不重复对一个 root 查找循环引用
    if ([self buildRetainTreeOperationForRoot:root]) {
        return;
    }
    
    TTMLBuildRetainTreeOperation *buildRetainTreeOperation = [[TTMLBuildRetainTreeOperation alloc] initWithRootObject:root needNormalRetainTree:[TTMLeaksFinder memoryLeaksConfig].enableNoVcAndViewHook graphConfiguraion:self.graphConfiguration stackDepth:TTMLStackDepthInBuildRetainTreeOperation completionBlock:nil];
    
    [self.buildRetainTreeOperations addObject:buildRetainTreeOperation];
    [self.operationQueue addOperation:buildRetainTreeOperation];
}

- (void)cancelAllOperationsForRoot:(id)root {
    
    if (!root) {
        return;
    }
    
    TTMLBuildRetainTreeOperation *operation = [self buildRetainTreeOperationForRoot:root];
    if (!operation) {
        //NSAssert(NO, @"cannot find operation for %@", root);
        return;
    }
    
    [operation cancel];
    [self.buildRetainTreeOperations removeObject:operation];
}

- (void)startDetectingSurviveObjectsForRootAfterDelay:(id)root {
    
    if (!root) {
        return;
    }
    
    TTMLBuildRetainTreeOperation *operation = [self buildRetainTreeOperationForRoot:root];
    
    if (!operation) {
        return;
    }
    
    
//    if (operation.isFinished) {
//        if ([[TTMLeaksFinder memoryLeaksConfig].delegateClass respondsToSelector:@selector(trackService:metric:category:extra:)]) {
//            [[TTMLeaksFinder memoryLeaksConfig].delegateClass trackService:@"mleaks_delay_dealloc_duration" metric:@{@"duration":@(0)} category:nil extra:nil];
//        }
//    }
//    else {
//        uint64_t didDisappearTick = TTMLCurrentMachTime();
//        [operation addCompletionBlock:^(TTMLGraphNode *rootNode) {
//            double delayDeallocDuration = TTMLMachTimeToSecs(TTMLCurrentMachTime() - didDisappearTick);
//            //NSLog(@"%@%@%@", rootNode.clazzName,@"延迟释放时间（s）",@(delayDeallocDuration));
//            if ([[TTMLeaksFinder memoryLeaksConfig].delegateClass respondsToSelector:@selector(trackService:metric:category:extra:)]) {
//                [[TTMLeaksFinder memoryLeaksConfig].delegateClass trackService:@"mleaks_delay_dealloc_duration" metric:@{@"duration":@(delayDeallocDuration * 1000)} category:nil extra:nil];
//            }
//        }];
//    }
    
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (operation.isFinished) {
            [self startDetectingSurviveObjectsWithRootNode:operation.rootNode];
            [self.buildRetainTreeOperations removeObject:operation];
        }
        else {
            __weak typeof(operation) weakOperation = operation;
            [operation addCompletionBlock:^(TTMLGraphNode *rootNode) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    __strong typeof(weakOperation) operation = weakOperation;
                    [self startDetectingSurviveObjectsWithRootNode:rootNode];
                    [self.buildRetainTreeOperations removeObject:operation];
                });
            }];
        }
    });
}

- (void)startDetectingSurviveObjectsWithRootNode:(TTMLGraphNode *)rootNode {
    if (!rootNode) {
        return;
    }
    TTMLDetectSurviveObjectsOperation *detectSurviveObjectsOperation = [[TTMLDetectSurviveObjectsOperation alloc] initWithRootNode:rootNode completion:^(NSArray<TTMLGraphNode *> *survivedNodes) {
        //NSLog(@"%@%@%@", rootNode.clazzName,@"存活的节点的个数",@([survivedNodes count]));
        [survivedNodes enumerateObjectsUsingBlock:^(TTMLGraphNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            TTMLDetectRetainCycleOperation *detectRetainCycleOperation = [[TTMLDetectRetainCycleOperation alloc] initWithNode:node rootNode:rootNode graphConfiguraion:self.graphConfiguration maxCycleLength:TTMLStackDepthInDetectRetainCycleOperation completionBlock:^(id leakedObject) {
                if (leakedObject) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [TTMLeakedObjectProxy addLeakedObject:leakedObject];
                    });
                }
            }];
            [self.operationQueue addOperation:detectRetainCycleOperation];
        }];
    }];
    [self.operationQueue addOperation:detectSurviveObjectsOperation];
}

#pragma mark - utils

- (TTMLBuildRetainTreeOperation *)buildRetainTreeOperationForRoot:(id)root {
    __block TTMLBuildRetainTreeOperation *buildRetainTreeOperation = nil;
    [self.buildRetainTreeOperations enumerateObjectsUsingBlock:^(TTMLBuildRetainTreeOperation * _Nonnull operation, NSUInteger idx, BOOL * _Nonnull stop) {
        if (operation.rootAddress == (size_t)root) {
            buildRetainTreeOperation = operation;
            *stop = YES;
        }
    }];
    return buildRetainTreeOperation;
}


#pragma mark - FBFinderAlogProtocol

- (void)findInstanceStrongPropertyAlog:(NSString *)alog{
    if ([TTMLeaksFinder memoryLeaksConfig].enableAlogOpen) {
        BDALOG_PROTOCOL_INFO(alog);
    }
    
}
@end
