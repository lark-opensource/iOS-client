//
//  HMDReportSizeLimitManager+Private.h
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/7/28.
//

#import <Foundation/Foundation.h>
#import "HMDReportSizeLimitManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HMDReportSizeLimitManagerDelegate <NSObject>

@optional
- (void)currentSizeOutOfThreshold;
- (void)hmdReportSizeLimitManagerStart;
- (void)hmdReportSizeLimitManagerStop;

@end

@interface HMDReportSizeLimitManager (Private)

- (void)startSizeLimit;
- (void)stopSizeLimit;

- (void)setDataSizeThreshold:(NSUInteger)thresholdSize;
- (void)addSizeLimitTool:(id<HMDReportSizeLimitManagerDelegate>)tool;
- (void)removeSizeLimitTool:(id<HMDReportSizeLimitManagerDelegate>)tool;

#pragma mark --- calculate the size
- (BOOL)increaseDataLength:(NSUInteger)dataLength;

@end

NS_ASSUME_NONNULL_END
