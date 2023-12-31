//
//	HMDTTMonitorCounter.h
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/4/24. 
//

#import <Foundation/Foundation.h>

#ifndef HMDMonitorCounterMetricTime
#define HMDMonitorCounterMetricTime 86400.f // 时间单位：天；以天为单位计数
#endif

NS_ASSUME_NONNULL_BEGIN

@interface HMDTTMonitorCounter : NSObject

- (instancetype)initCounterWithAppID:(NSString *)appID;
- (id)init __attribute__((unavailable("please use initCounterWithAppID: method")));
+ (instancetype)new __attribute__((unavailable("please use initCounterWithAppID: method")));

- (int64_t)generateSequenceNumber;
- (int64_t)generateUniqueCode;

@end

NS_ASSUME_NONNULL_END
