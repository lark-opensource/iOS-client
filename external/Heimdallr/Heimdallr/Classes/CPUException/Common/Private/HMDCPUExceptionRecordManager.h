//
//  HMDCPUExceptionRecordCache.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/5/19.
//

#import <Foundation/Foundation.h>
#import "HMDCPUExceptionV2Record.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HMDCPUExceptionRecordManagerDelegate <NSObject>

@optional
- (BOOL)storeCPUExceptionRecords:(NSArray<HMDCPUExceptionV2Record *> *)records;
- (BOOL)deleteCPUExceptionRecords:(NSArray<NSString *> *)recordUUIDs;
- (void)shouldReportCPUExceptionRecordNow;

@end

@interface HMDCPUExceptionRecordManager : NSObject

/// 是否需要去重逻辑
@property (nonatomic, assign) BOOL ignoreDuplicate;
@property (nonatomic, assign) BOOL isRecordFromStore;
@property (nonatomic, weak) id<HMDCPUExceptionRecordManagerDelegate> delegate;

- (void)pushRecord:(HMDCPUExceptionV2Record *)record needUploadImmediately:(BOOL)needImmediately;
- (NSArray *)cpuExceptionReportData;
- (NSArray *)cpuExceptionReprotDataWithRecords:(NSArray<HMDCPUExceptionV2Record *> *)records;
- (void)cpuExceptionReportCompletion:(BOOL)success;

@end

NS_ASSUME_NONNULL_END
