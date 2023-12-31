//
//  HMDMemoryChecker.h
//  Heimdallr-iOS13.0
//
//  Created by fengyadong on 2020/2/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const kHMDMemoryWillPeakNotification;
FOUNDATION_EXPORT NSString * const kHMDMemoryHasPeakedNotification;
FOUNDATION_EXPORT NSString * const kHMDMemorySurgeStr;

typedef struct {
    bool manualMemoryWarning;//是否手动发出内存通知的警告
    uint64_t dangerThreshold;//危险内存的阈值，单位Byte
    uint64_t growingStep;//到达危险阈值之后新的危险阈值的增量，单位Byte
    NSTimeInterval checkInterval;//检测的时间间隔，单位秒
    NSTimeInterval minNotifyInterval;//发送内存到达危险阈值通知的最小间隔
    bool calculateSlardarMallocMemory; //内存阈值是否包含slardar_malloc的分配
    int memorySurgeThresholdMB;//内存突增判定值，单位M，默认500
}HMDMemoryCheckerBuilder;

@interface HMDMemoryChecker : NSObject

- (void)activateByBuilder:(HMDMemoryCheckerBuilder)builder;

- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
