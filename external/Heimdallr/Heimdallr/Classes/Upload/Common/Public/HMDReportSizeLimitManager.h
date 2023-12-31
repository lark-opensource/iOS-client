//
//  HMDReportSizeLimitManager.h
//  AWECloudCommand
//
//  Created by zhangxiao on 2019/12/17.
//

#import <Foundation/Foundation.h>

@interface HMDReportSizeLimitManager : NSObject

@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic, assign, readonly) NSUInteger thresholdSize; // byte
@property (nonatomic, assign) NSUInteger uploadIntervalSec;

+ (nonnull instancetype)defaultControlManager;
/// 开始进入 上传包大小控制状态 此时忽略配置的时间阈值;
- (void)start __attribute__((deprecated("deprecated. Please use api startWithCustomReportConfig: of HMDCustomReportManager")));
/// 停止;
- (void)stop __attribute__((deprecated("deprecated. Please use api stopAndRestartHightestPriorityMode of HMDCustomReportManager")));
/// 设置阈值
- (void)dataSizeThreshold:(NSUInteger)thresholdSize __attribute__((deprecated("deprecated. Please use api startWithCustomReportConfig of HMDCustomReportManager")));

@end

