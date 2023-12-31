//
//  BDPMonitorProtocol.h
//  Timor
//
//  Created by dingruoshan on 2019/4/8.
//

#import <Foundation/Foundation.h>
#import "BDPMonitorData.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDPMonitorProtocol <NSObject>

#pragma mark 开始/结束监控
/// 开始监控并且自动上传， 调用这个借口前，请确认mpId已经赋值，
- (void)start;
/// 停止监控
- (void)stop;

#pragma mark 上报频率相关
/// 设置上报触发的频率
- (void)resetIntervalOfReport:(NSTimeInterval)interval firstFireDelay:(NSTimeInterval)delay;
/// 当前上报的触发频率
- (NSTimeInterval)intervalOfReport;
- (NSTimeInterval)firstFireDelayOfReport;
/// 获取默认上报触发间隔
- (NSTimeInterval)getDefaultIntervalOfReport;
- (NSTimeInterval)getDefaultFirstFireDelayOfReport;

#pragma mark 数据传入
- (void)recieveMonitorData:(BDPMonitorData *)data;
- (NSMutableArray<BDPMonitorData *> *)recievedDatas;

@end

NS_ASSUME_NONNULL_END
