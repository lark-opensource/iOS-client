//
//  HMDPerformanceReporter+SizeLimitedReport.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//

#import "HMDPerformanceReporter+SizeLimitedReport.h"
#import <objc/runtime.h>
#import "HMDWeakProxy.h"
#import "HMDReportSizeLimitManager+Private.h"
#import "HMDInjectedInfo+NetworkSchedule.h"
#import "HMDPerformanceReporterManager+Privated.h"
#import "HMDCustomReportManager.h"

@implementation HMDPerformanceReporter (SizeLimitedReport)

@dynamic sizeLimitAvailableTime;

- (void)setSizeLimitedReportTimer:(NSTimer *)sizeLimitedReportTimer {
    objc_setAssociatedObject(self, @selector(sizeLimitedReportTimer), sizeLimitedReportTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimer *)sizeLimitedReportTimer {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)reportPerformanceDataAsyncWithSizeLimited {
    [[HMDPerformanceReporterManager sharedInstance] reportPerformanceDataAsyncWithSizeLimitedReporter:self block:NULL];
}

- (void)startSizeLimitedReportTimer {
    NSTimeInterval reportPollingInterval = [HMDCustomReportManager defaultManager].currentConfig.uploadInterval;
    if(reportPollingInterval > 0) {
        NSTimer *previousTimer = self.sizeLimitedReportTimer;
        NSTimer *timer = [NSTimer timerWithTimeInterval:reportPollingInterval
                                                 target:[HMDWeakProxy proxyWithTarget:self]
                                               selector:@selector(autoReportPerformanceDataWithSizeLimited:)
                                               userInfo:nil
                                                repeats:NO];

        self.sizeLimitedReportTimer = timer;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (previousTimer && [previousTimer isValid]) {
                [previousTimer invalidate];
            }
            if (timer) {
                [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            }
        });
    }
}

- (void)stopSizeLimitedReportTimer {
    if (self.sizeLimitedReportTimer) {
        NSTimer *timer = self.sizeLimitedReportTimer;
        dispatch_async(dispatch_get_main_queue(), ^{
           if ([timer isValid]) {
               [timer invalidate];
           }
        });
        self.sizeLimitedReportTimer = nil;
    }
}

///  moule reponse to performanceDataWithLimitSize;  in this time, reporter body's size should be limited;
- (NSArray *)_dataArrayForSizeLimitedReportWithAddedMoudle:(NSMutableArray *)addedModules modules:(NSArray *)modules {
    NSMutableArray *dataArray = [NSMutableArray new];
    NSUInteger expectionSize = [HMDCustomReportManager defaultManager].currentConfig.thresholdSize;
    NSUInteger currentSize = 0;
    for (id module in modules) {
       @autoreleasepool {
           if ([module respondsToSelector:@selector(performanceDataWithLimitSize:limitCount:currentSize:)]) {
               if (dataArray.count < 200 && currentSize < expectionSize) {
                   NSInteger properLimitCount = 100;
                   if ([module respondsToSelector:@selector(properLimitCount)]) {
                       properLimitCount = [module properLimitCount];
                   }
                   NSUInteger maxAllowedSize = expectionSize; // 日志大小权重 防止一些比较大的日志直接占用了全部的上传大小
                   if ([module respondsToSelector:@selector(properLimitSizeWeight)]) {
                       CGFloat weight = ([module properLimitSizeWeight]);
                       maxAllowedSize = (NSUInteger)(weight * expectionSize);
                   }
                   NSUInteger surplusSize = expectionSize - currentSize;
                   NSUInteger targetSize = surplusSize > maxAllowedSize ? maxAllowedSize : surplusSize;
                   NSArray *result = [module performanceDataWithLimitSize:targetSize limitCount:properLimitCount currentSize:&currentSize];
                   if (result && result.count > 0) {
                       [dataArray addObjectsFromArray:result];
                       [addedModules addObject:module];
                   }
               }
           }
       }
    }
    return dataArray;
}


// 限制包大小的上传模式 计算上传的时间间隔
- (void)_sizeLimitedTimeAvaliableWithBody:(NSDictionary *)body {
    // 计算大小推算时间
    NSTimeInterval nextInterval = 0; // 下一次上报的 最小时间间隔
    NSUInteger expectionInterval = [HMDCustomReportManager defaultManager].currentConfig.uploadInterval; // 外部设置的期望上传的时间间隔
    expectionInterval = expectionInterval >= 1? expectionInterval : 1; // 最小时间间隔为 1s;
    @try {
       NSError *error = nil;
       NSData *data = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:&error];
       NSUInteger length = data.length; // 获取此次上报的数据的大小
       NSUInteger expireSize = [HMDCustomReportManager defaultManager].currentConfig.thresholdSize;
       expireSize = expireSize > 0 ? expireSize : (20000); // 默认 20 * 1000;
        // 这块是为了平均上传的大小;  比如: 用户期望每 5s 上报的大小为 100, 如果因为某条超大日志 导致这次日志上报的比较大, 比如到达了 200 , 那么为了平衡资源 那么需要拉长下次上报的时间间隔, 保证平均时间内上报的数据大小不出现太大的波动
       nextInterval = (length / expireSize) * expectionInterval;
    } @catch (NSException *exception) {
        // json序列化异常的话 使用用户期望的时间
        nextInterval = expectionInterval; // 没有的话 设置最小间隔 2s
    } @finally {
        nextInterval = nextInterval < 120 ? nextInterval : 120;
        // 设置 最小的时间间隔为 用户期望的 一半, 防止日志的频繁上报;
        NSUInteger minTimeInterval = expectionInterval / 2.0;
        // 计算出下次可上报的最小日期, 不能小于最小时间间隔
        self.sizeLimitAvailableTime = [[NSDate date] timeIntervalSince1970] + (nextInterval > minTimeInterval ? nextInterval : minTimeInterval);
    }
}


- (void)autoReportPerformanceDataWithSizeLimited:(NSTimer *)timer {
    [self reportPerformanceDataAsyncWithSizeLimited];
}

@end
