//
//  TSPKRelationObjectCacheStore.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/26.
//

#import "TSPKRelationObjectCacheStore.h"

#import "TSPKLock.h"
#import "TSPKRelationObjectModel.h"
#import "TSPKThreadPool.h"
#import "TSPKUtils.h"
#import <PNSServiceKit/PNSServiceCenter.h>
#import <PNSServiceKit/PNSBacktraceProtocol.h>
#import "TSPKConfigs.h"

const NSInteger instanceNumThresholdToClean = 20;
const NSInteger expectInstanceNum = 10;
const NSTimeInterval cleanCheckThreshold = 300; // 5 minute

@interface TSPKRelationObjectCacheStore ()

@property (nonatomic, strong) id<TSPKLock> lock;
@property (nonatomic, strong) NSMutableDictionary<NSString *, TSPKRelationObjectModel *> *objects;//key is instance address's hashTag, TSPKRelationObjectModel stores the instance events of start and stop
@property (nonatomic) NSTimeInterval lastCleanTime;

@end

@implementation TSPKRelationObjectCacheStore

- (instancetype)init
{
    if (self = [super init]) {
        _lock = [TSPKLockFactory getLock];
        _objects = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)saveEventData:(TSPKEventData *)eventData completion:(void (^ __nullable)(NSError *))completion
{
    NSString *instanceUid = eventData.apiModel.hashTag;
    if ([instanceUid length] == 0) {
        return;
    }
    
    if (eventData.apiModel.apiUsageType == TSPKAPIUsageTypeStart && eventData.apiModel.backtraces.count == 0) {
        eventData.apiModel.backtraces = [PNS_GET_INSTANCE(PNSBacktraceProtocol) getBacktracesWithSkippedDepth:0 needAllThreads:NO];
    }

    [_lock lock];
    
    TSPKRelationObjectModel *relationObjectModel = [self objectOfUid:instanceUid];
    // only save recent start backtrace
    if (eventData.apiModel.apiUsageType == TSPKAPIUsageTypeStart && [[TSPKConfigs sharedConfig] enableRemoveLastStartBacktrace]) {
        [relationObjectModel removeLastStartBacktrace];
    }
    
    [relationObjectModel saveEventData:eventData];
    
    TSPKAPIUsageType apiType = eventData.apiModel.apiUsageType;
    
    if (apiType == TSPKAPIUsageTypeDealloc) {
        [self scheduleACleanPlan];
    }
    
    [_lock unlock];
    
    !completion ?: completion(nil);
}

- (void)getStoreDataWithInstanceAddress:(nullable NSString *)instanceAddress completion:(void (^ __nullable)(NSDictionary *))completion {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [_lock lock];
    [self.objects enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, TSPKRelationObjectModel * _Nonnull obj, BOOL * _Nonnull stop) {
        // if instanceAddress exists, only get instance data
        if (instanceAddress.length > 0) {
            if ([key isEqualToString:instanceAddress]) {
                result[key] = [obj copy];
                *stop = YES;
            }
        } else {
            result[key] = [obj copy];
        }
    }];
    [_lock unlock];
    !completion ?: completion([NSDictionary dictionaryWithDictionary:result]);
}

- (void)getStoreDataWithCompletion:(void (^ __nullable)(NSDictionary *))completion
{
    [self getStoreDataWithInstanceAddress:nil completion:completion];
}

- (NSTimeInterval)getCleanTime
{
    NSTimeInterval cleanTime = 0;
    [_lock lock];
    cleanTime = self.lastCleanTime;
    [_lock unlock];
    return cleanTime;
}

- (void)updateReportTime:(NSTimeInterval)reportTime
{
    [_lock lock];
    [self.objects enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, TSPKRelationObjectModel * _Nonnull obj, BOOL * _Nonnull stop) {
        obj.reportTimeStamp = reportTime;
    }];
    [_lock unlock];
}

- (TSPKRelationObjectModel *)objectOfUid:(NSString *)uid
{
    if (self.objects[uid] == nil) {
        self.objects[uid] = [TSPKRelationObjectModel new];
    }
    return self.objects[uid];
}

#pragma mark - clean
- (void)scheduleACleanPlan
{
    if (self.objects.allKeys.count < instanceNumThresholdToClean) {
        return;
    }
    
    NSTimeInterval now = [TSPKUtils getRelativeTime];
    if (now - self.lastCleanTime < cleanCheckThreshold) {
        return;
    }
    
    self.lastCleanTime = now;
    dispatch_async([[TSPKThreadPool shardPool] lowPriorityQueue], ^{
        [self cleanRecords];
    });
}

- (void)cleanRecords
{
    [_lock lock];
    
    NSMutableArray *deallocArray = [[NSMutableArray alloc] init];
    for (NSString *key in self.objects.allKeys) {
        TSPKRelationObjectModel *objectModel = self.objects[key];
        if (objectModel.objectStatus != TSPKRelationObjectStatusDealloc) {
            continue;
        }
        [deallocArray addObject:key];
    }
    
    NSInteger numToClean = self.objects.allKeys.count - expectInstanceNum;
    if (deallocArray.count <= numToClean) {
        [self cleanRecordsInArray:deallocArray];
    } else if (numToClean > 0){
        [deallocArray sortUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
            TSPKRelationObjectModel *object1 = self.objects[key1];
            TSPKRelationObjectModel *object2 = self.objects[key2];
            
            if (object1.updateTimeStamp < object2.updateTimeStamp) {
                return NSOrderedAscending;
            } else if (object1.updateTimeStamp > object2.updateTimeStamp) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];
        
        [self cleanRecordsInArray:[deallocArray subarrayWithRange:NSMakeRange(0, numToClean)]];
    }
    
    [_lock unlock];
}

- (void)cleanRecordsInArray:(NSArray *)array {
    for (NSString *key in array) {
        self.objects[key] = nil;
    }
}

@end
