//
//  HMDCPUExceptionPerf.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/1/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDCPUExceptionPerf : NSObject

@property (nonatomic, assign) BOOL enablePerfWatch;

- (void)threadBackTreeWithTimeUsage:(long long)timeUsage threadCount:(NSInteger)threadCount suspendThread:(BOOL)suspendThread;

- (void)exceptionThreadTimeUsage:(long long)timeUsage;

- (void)exceptionRecordPrepareWithTimeUsage:(long long)timeUsage infoSize:(NSUInteger)infoSize;

- (void)recordWriteFileWithStartTS:(long long)startTS endTS:(long long)endTS infoCount:(NSUInteger)infoCount;

- (void)monitorThreadCPUUsgeOutOfThreshold:(float)usage;

- (void)collectPerformanceWithServiceName:(NSString *)serviceName
                                timeUsage:(NSNumber *)usage
                                 category:(nullable NSDictionary<NSString *, NSNumber *> *)catergory;
@end

NS_ASSUME_NONNULL_END
