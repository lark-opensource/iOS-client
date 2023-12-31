//
//  HMDPerformanceAggregate+CPUAggregate.h
//  AWECloudCommand
//
//  Created by zhangxiao on 2020/8/31.
//

#import "HMDPerformanceAggregate.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDPerformanceAggregate (FindMaxValue)

@property (nonatomic, strong) NSMutableDictionary *indexKeys;

- (NSArray *)findMaxValueAggregateWithSessionID:(NSString *)sessionID
                                  aggregateKeys:(NSDictionary *)keys
                        needAggregateDictionary:(NSDictionary *)needAggregateDictionary
                               normalDictionary:(NSDictionary *)normalDictionary
                                 listDictionary:(nullable NSDictionary<NSString *,NSArray<NSDictionary *> *> *)listDictionary
                              currentecordIndex:(NSInteger)currentecordIndex
                         findMaxValueDictionary:(NSDictionary<NSString *,NSDictionary *> *)findMaxValueDict;

@end

NS_ASSUME_NONNULL_END
