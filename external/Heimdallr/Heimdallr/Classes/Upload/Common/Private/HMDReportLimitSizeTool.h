//
//  HMDReportSizeControl.h
//  AFgzipRequestSerializer-iOS13.0
//
//  Created by zhangxiao on 2019/12/16.
//

#import <Foundation/Foundation.h>
#import "HMDRecordStoreObject.h"
#import "HMDReportSizeLimitManager+Private.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HMDLimitReportDataSizeToolDelegate <NSObject>

@optional
- (void)performanceDataSizeOutOfThreshold;
- (void)performanceSizeLimitReportStart;
- (void)performanceSizeLimitReportStop;

@end

@interface HMDReportLimitSizeTool : NSObject <HMDReportSizeLimitManagerDelegate>

@property (nonatomic, weak) id<HMDLimitReportDataSizeToolDelegate> delegate;

- (BOOL)shouldSizeLimit;
- (void)addNeedLimitReportSizeRecordClass:(id)recordModule;
- (void)addNeedLimitReportSizeRecordClasses:(NSSet *)recordModules;
- (void)removeReportSizeRecordClass:(id)recordModule;

#pragma mark --- enter record
/// 添加实现 HMDRecordStoreObject 协议的日志
/// @param records  实现了 HMDRecordStoreObject 协议的日志
- (void)estimateSizeWithStoreObjectRecord:(NSArray *)records recordClass:(Class <HMDRecordStoreObject>)recordClass module:(id)reportMoudle;

/// 添加 MonitorRecord 的聚合后的日志
/// @param aggregateDictArray  MonitorRecord日志
- (void)estimateSizeWithMonitorRecords:(NSArray *)aggregateDictArray recordClass:(Class <HMDRecordStoreObject>)recordClass module:(id)reportMoudle;

/// 添加 MonitorRecord 的聚合后的日志
/// @param aggregateDictArray  MonitorRecord日志
- (void)estimateSizeWithDictArray:(NSArray<NSDictionary *> *)aggregateDictArray module:(id)reportMoudle;

@end

NS_ASSUME_NONNULL_END
