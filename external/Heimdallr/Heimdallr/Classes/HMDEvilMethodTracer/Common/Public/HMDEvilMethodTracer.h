//
//  HMDEvilMethodTracer.h
//  AWECloudCommand
//
//  Created by maniackk on 2021/5/28.
//

#import "HeimdallrModule.h"


@interface HMDEvilMethodTracer : HeimdallrModule

+ (nonnull instancetype)sharedInstance;

// 开始监控 如果想监控app启动阶段，则需要调用次方法越早越好，最好在第一个load方法
// 这个函数只是确定开始监控的时机
//这个函数只需要调用一次，是整个慢函数功能的开关
- (void)startTrace;

// 这个函数只是确定结束监控的时机
////这个函数只需要调用一次，是整个慢函数功能的开关；可以不调用。
- (void)stopTrace;

@end

