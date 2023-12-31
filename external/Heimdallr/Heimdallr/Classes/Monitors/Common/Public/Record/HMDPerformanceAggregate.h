//
//  HMDPerformanceAggregate.h
//  Heimdallr
//
//  Created by joy on 2018/4/17.
//

#import <Foundation/Foundation.h>

@interface HMDPerformanceAggregate : NSObject

@property (nonatomic, strong, nonnull) NSMutableDictionary *tracksDictionary;

- (nonnull NSArray *)getAggregateRecords;

/**
 *
 *  @param sessionID    sessionID，聚合只聚合相同 sessionID 的数据
 *  @param keys         聚合时候需要依据的 key，一般是 extra_status
 *  @param needAggregateDictionary 需要聚合的数据，进行求均值
 *  @param normalDictionary 常规指标，比如 lotType、时间戳，对于时间戳这种 NSNumber 类型的数据，聚合的时候求最大值即可
 *  @param listDictionary 列表指标，比如内存对象dump，磁盘空间最大文件，形如：@{@"dump":[@{name:@"XXViewController",@"size":120,@"count":5}]}
 *  @currentecordIndex 当前要聚合的数据在数组中的 index
 */
- (nullable NSArray *)aggregateWithSessionID:(nonnull NSString *)sessionID
                      aggregateKeys:(nullable NSDictionary *)keys
            needAggregateDictionary:(nullable NSMutableDictionary *)needAggregateDictionary
                   normalDictionary:(nullable NSDictionary *)normalDictionary
                     listDictionary:(nullable NSDictionary<NSString*, NSArray<NSDictionary *>*> *)listDictionary
                  currentecordIndex:(NSInteger)currentecordIndex;
@end
