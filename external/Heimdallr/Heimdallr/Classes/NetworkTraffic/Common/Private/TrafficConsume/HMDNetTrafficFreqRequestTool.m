//
//  HMDNetTrafficFreqRequestTool.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/10/23.
//

#import "HMDNetTrafficFreqRequestTool.h"
#import "HMDNetTrafficSourceUsageModel.h"
#import "NSDictionary+HMDSafe.h"
#import "NSArray+HMDSafe.h"

#define kHMDNetTrafficHighFreqQueueCacheCount 50

@interface HMDNetTrafficFreqRequestTool ()
/// 网络请求的使用信息
@property (nonatomic, strong) NSMutableDictionary *highFreqQueue;
@property (nonatomic, strong) NSMutableDictionary *historyQueue;

@end

@implementation HMDNetTrafficFreqRequestTool

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.highFreqQueue = [NSMutableDictionary dictionary];
        self.historyQueue = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark --- public api
- (HMDNetTrafficSourceUsageModel *)cachedSourceInfoWithKey:(NSString *)key {
    // request maybe exist two cache queue
    HMDNetTrafficSourceUsageModel *usageInfo = [self.highFreqQueue hmd_objectForKey:key class:[HMDNetTrafficSourceUsageModel class]];
    if (usageInfo == nil) {
        usageInfo = [self.historyQueue hmd_objectForKey:key class:[HMDNetTrafficSourceUsageModel class]];
    }
    return usageInfo;
}

- (void)cacheSourceUsageInfo:(HMDNetTrafficSourceUsageModel *)usageInfo {
    if (usageInfo.souceId == nil) { return; }
    if (self.frequencyThreashold == 0) { return; }
    // 判断缓存队列是否有已经存在的该请求的使用信息,如果有说明前面已经跟新了不愿管,只判断是否超过了缓存阈值 替换掉最远的节点就行;
    HMDNetTrafficSourceUsageModel *cacheNetInfo = [self.highFreqQueue  hmd_objectForKey:usageInfo.souceId class:[HMDNetTrafficSourceUsageModel class]];
    long long currentTime = usageInfo.resetTimestamp;
    if (cacheNetInfo == nil) { // 缓存队列中没有, 在 store 队列中的如果
        [self.historyQueue hmd_setObject:usageInfo forKey:usageInfo.souceId];
        if (usageInfo.executeCount > (self.frequencyThreashold / 2)) {
            [self.highFreqQueue hmd_setObject:usageInfo forKey:usageInfo.souceId];
            [self.historyQueue removeObjectForKey:usageInfo.souceId?:@""];
        }
        if (self.historyQueue.count > kHMDNetTrafficHighFreqQueueCacheCount) {
            [self usageDictRemoveEarliestValueWithDict:self.historyQueue
                                         initTimeStamp:currentTime
                                         deletEarliest:YES];
        }
    } else if(self.highFreqQueue.count > kHMDNetTrafficHighFreqQueueCacheCount) {
        // 这里 LRU-K 是淘汰最早访问,但是这里是记录高频请求,最早访问的容易淘汰掉真正的高频请求,这里改为高频请求
        [self usageDictRemoveEarliestValueWithDict:self.highFreqQueue
                                     initTimeStamp:currentTime
                                     deletEarliest:NO];
    }
}

- (NSArray<HMDNetTrafficSourceUsageModel *> *)dumpHighFrequencyUsageWithThreshold:(NSInteger)threshold {
    NSMutableArray *highFreqRequests = [NSMutableArray array];
    [[self.highFreqQueue allValues] enumerateObjectsUsingBlock:^(HMDNetTrafficSourceUsageModel * usageInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        if (usageInfo.executeCount > threshold) {
            [highFreqRequests hmd_addObject:usageInfo];
        }
    }];
    return [highFreqRequests copy];
}

- (void)cleanCache {
    [self.highFreqQueue removeAllObjects];
    [self.historyQueue removeAllObjects];
}

#pragma mark --- utilites method
- (void)usageDictRemoveEarliestValueWithDict:(NSMutableDictionary *)dict
                               initTimeStamp:(long long)initTime
                               deletEarliest:(BOOL)deletEarliest {
    if (deletEarliest) { // 删除最早的节点
        __block long long earlestTime = initTime;
        __block NSString *willRemoveKey = nil;
        [dict enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, HMDNetTrafficSourceUsageModel *_Nonnull obj, BOOL *_Nonnull stop) {
            if (obj.resetTimestamp < earlestTime) {
                earlestTime = obj.resetTimestamp;
                willRemoveKey = key;
            }
        }];
        if (willRemoveKey) {
            [dict removeObjectForKey:willRemoveKey];
        }
    } else { // 删除次数最少的节点
        __block NSInteger leastExecuteCount = NSIntegerMax;
        __block NSString *willRemoveKey = nil;
        // 淘汰前一半时间次数最少的
        long long tsBeforePoint = (initTime - self.anchorTS) / 2 + self.anchorTS;
        [dict enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, HMDNetTrafficSourceUsageModel *_Nonnull obj, BOOL *_Nonnull stop) {
            if (obj.resetTimestamp < tsBeforePoint && leastExecuteCount < obj.executeCount) {
                leastExecuteCount = obj.executeCount;
                willRemoveKey = key;
            }
        }];
        if (willRemoveKey) {
            [dict removeObjectForKey:willRemoveKey];
        }
    }
}

@end
