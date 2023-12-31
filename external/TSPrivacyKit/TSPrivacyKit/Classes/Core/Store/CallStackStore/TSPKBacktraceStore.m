//
//  TSPKBacktraceStore.m
//  Musically
//
//  Created by ByteDance on 2022/8/26.
//

#import "TSPKBacktraceStore.h"
#import "TSPKConfigs.h"
#import "TSPKLock.h"
#import <PNSServiceKit/PNSBacktraceProtocol.h>
#import <PNSServiceKit/PNSServiceCenter.h>
#import "TSPKUtils.h"
#import <ByteDanceKit/ByteDanceKit.h>

@interface TSPKBacktraceStoreModel : NSObject

@property (nonatomic, copy) NSArray *backtraces;
@property (nonatomic, assign) NSTimeInterval timestamp;

@end

@implementation TSPKBacktraceStoreModel

@end

@interface TSPKBacktraceStore ()

@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray <TSPKBacktraceStoreModel*> *> *mutableBacktraceDic;
@property (nonatomic, strong) id<TSPKLock> lock;

@end

@implementation TSPKBacktraceStore

+ (instancetype)shared
{
    static TSPKBacktraceStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[TSPKBacktraceStore alloc] init];
    });
    return store;
}

- (instancetype)init {
    if (self = [super init]) {
        _lock = [TSPKLockFactory getLock];
        _mutableBacktraceDic = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)saveCustomCallBacktraceWithPipelineType:(nonnull NSString *)pipelineType {
    if ([PNS_GET_INSTANCE(PNSBacktraceProtocol) isMultipleAsyncStackTraceEnabled] || ![[TSPKConfigs sharedConfig] enableMergeCustomAndSystemBacktraces]) {
        return;
    }
    
    if (pipelineType.length == 0) {
        return;
    }

    TSPKBacktraceStoreModel *model = [TSPKBacktraceStoreModel new];
    model.backtraces = [PNS_GET_INSTANCE(PNSBacktraceProtocol) getBacktracesWithSkippedDepth:1 needAllThreads:NO];
    model.timestamp = [TSPKUtils getRelativeTime];
    
    [self.lock lock];
    if (!self.mutableBacktraceDic[pipelineType]) {
        self.mutableBacktraceDic[pipelineType] = [NSMutableArray array];
    }
    
    if ([self.mutableBacktraceDic[pipelineType] isKindOfClass:[NSMutableArray class]]) {
        NSMutableArray *pipelineTypeBacktracesArr = self.mutableBacktraceDic[pipelineType];
        [pipelineTypeBacktracesArr addObject:model];
    }
    [self.lock unlock];
}

- (nullable NSArray *)findMatchedBacktraceWithPipelineType:(nonnull NSString *)pipelineType beforeTimestamp:(NSTimeInterval)timestamp {
    if ([PNS_GET_INSTANCE(PNSBacktraceProtocol) isMultipleAsyncStackTraceEnabled] || ![[TSPKConfigs sharedConfig] enableMergeCustomAndSystemBacktraces]) {
        return nil;
    }
    
    if (pipelineType.length == 0) {
        return nil;
    }
    
    __block NSArray *backtraceResult;
    __block NSInteger matchedIndex = -1;
    [self.lock lock];
    
    if ([self.mutableBacktraceDic[pipelineType] isKindOfClass:[NSMutableArray class]]) {
        NSMutableArray *pipelineTypeBacktracesArr = self.mutableBacktraceDic[pipelineType];
        
        // reverse travel
        [pipelineTypeBacktracesArr enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TSPKBacktraceStoreModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
            if (model.timestamp < timestamp) {
                backtraceResult = model.backtraces;
                matchedIndex = idx;
                *stop = YES;
            }
        }];
        
        // make sure find matched backtrace, delete all the records before timestamp
        if (matchedIndex != -1) {
            [pipelineTypeBacktracesArr removeObjectsInRange:NSMakeRange(0, matchedIndex + 1)];
        }
    }
    
    [self.lock unlock];
    return backtraceResult;
}

@end
