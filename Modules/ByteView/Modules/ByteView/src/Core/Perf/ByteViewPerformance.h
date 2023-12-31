//
//  ByteViewPerformance.h
//  ByteView
//
//  Created by liujianlong on 2021/6/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

#ifndef ByteViewPerformance_h
#define ByteViewPerformance_h

#import <Foundation/Foundation.h>

#include <stdint.h>
#include "thread_biz_scope.h"
#import "ByteViewThreadBizScopedProxy.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    int64_t appUsageBytes;
    int64_t systemUsageBytes;
    int64_t availableUsageBytes; // 当前可用内存
} ByteViewMemoryUsage;

ByteViewMemoryUsage byteview_current_memory_usage(void);

#ifdef __cplusplus
}
#endif


@interface ByteViewThreadCPUUsage: NSObject

@property(assign, nonatomic) uint64_t threadID;
@property(assign, nonatomic) int index;
@property(assign, nonatomic) ByteViewThreadBizScope bizScope;
@property(copy, nonatomic, nullable) NSString *threadName;
@property(copy, nonatomic, nullable) NSString *queueName;
@property(assign, nonatomic) float cpuUsage;

+ (NSArray<ByteViewThreadCPUUsage *> *)threadCPUUsagesTopN:(NSInteger)topN
                                           threadThreshold:(CGFloat)threadThreshold
                                                    rtcCPU:(CGFloat *)rtcCPU
                                                    appCPU:(CGFloat *)appCPU;

+ (float)appCPU;

@end

NS_ASSUME_NONNULL_END

#endif /* ByteViewPerformance_h */
