//
//  HMDCPUExceptionLog.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/10/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDCPUExceptionLog : NSObject

+ (void)hmd_CPUExceptionRecordTimeUsageWithTime:(long long)timeUsage eventName:(NSString *)eventName category:(nullable NSDictionary *)catory;

@end

NS_ASSUME_NONNULL_END
