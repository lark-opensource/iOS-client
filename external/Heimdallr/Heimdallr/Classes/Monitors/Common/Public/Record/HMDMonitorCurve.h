//
//  HMDMonitorCurve.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import <Foundation/Foundation.h>
@class HMDMonitorCurve;
@class HMDMonitorRecord;

@protocol HMDMonitorStorageDelegate
- (BOOL)enableUpload;
- (void)updateRecordWithConfig:(nullable HMDMonitorRecord *)record;
- (BOOL)monitorCurve:(nonnull HMDMonitorCurve *)monitorCurve willSaveRecords:(nullable NSArray <HMDMonitorRecord *>*)records;
- (void)recordSizeCalculationWithRecord:(nullable HMDMonitorRecord *)record;
- (void)dropAllMonitorRecords;
@end

/**负责Monitor数据存储管理*/
@interface HMDMonitorCurve : NSObject
@property (nonatomic, strong, nullable) NSString *name;
@property (nonatomic, assign, readonly) NSTimeInterval startTime;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, strong, readonly, nullable) HMDMonitorRecord *currentRecord;
@property (nonatomic, strong, readonly, nullable) HMDMonitorRecord *maxRecord;
@property (nonatomic, strong, readonly, nullable) HMDMonitorRecord *minRecord;
@property (nonatomic, assign, nonnull) Class recordClass;
@property (nonatomic, strong, readonly, nullable) NSMutableArray<HMDMonitorRecord *> *records;

@property (nonatomic, assign) NSUInteger flushCount;
@property (nonatomic, assign) double flushInterval;
@property (nonatomic, assign) BOOL performanceReportEnable;

@property (nonatomic, weak, nullable) id<HMDMonitorStorageDelegate> storageDelegate;

- (nonnull instancetype)initWithCurveName:(nonnull NSString *)name recordClass:(nonnull Class)recordClass;
- (void)pushRecord:(nullable HMDMonitorRecord *)record;
///  忽略缓存数量 直接尝试写入数据库
- (void)pushRecordToDBImmediately:(nullable HMDMonitorRecord *)record;
/// 把缓存在内存的 records 立即写入数据库
- (void)pushRecordImmediately;

- (nullable NSArray<HMDMonitorRecord*>*)recordsInAppTimeFrom:(CFTimeInterval)fromTime to:(CFTimeInterval)toTime sessionID:(nonnull NSString *)sessionID recordClass:(nonnull Class)recordClass;

- (void)dropAllDataForServerState;
- (void)dropDataForServerState:(BOOL)drop;

// 重构后，有些数据无需聚类，需要直接record
- (void)recordDataDirectly:(NSDictionary *_Nonnull)dic;

@end
