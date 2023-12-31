//
//  HMInstance.h
//  Hermas
//
//  Created by 崔晓兵 on 19/1/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HMRecordPriority) {
    HMRecordPriorityRealTime = 0,
    HMRecordPriorityHigh = 10000,
    HMRecordPriorityDefault = 15000,
    HMRecordPriorityLow = 30000,
};

@class HMInstanceConfig;
@class HMGlobalConfig;
@class HMSearchCondition;

@interface HMInstance : NSObject

@property (nonatomic, strong, readonly, nullable) HMInstanceConfig *config;

@property (nonatomic, copy, nullable) int64_t(^sequenceNumberGenerator)();

- (instancetype)init NS_UNAVAILABLE;


/// record normal data
/// @param dic data
- (void)recordData:(nonnull NSDictionary *)dic;


/// record normal data with priority
/// @param dic data
/// @param priority priority
- (void)recordData:(nonnull NSDictionary *)dic priority:(HMRecordPriority)priority;

- (void)recordData:(nonnull NSDictionary *)dic priority:(HMRecordPriority)priority forceSave:(BOOL)forceSave;

- (void)recordLocal:(NSDictionary *)dic forceSave:(BOOL)forceSave;

/// record cache when the sampling rate is uncertain
/// @param dic data
- (void)recordCache:(nonnull NSDictionary *)dic;


/// stop cache
- (void)stopCache;


/// aggregate data
/// @param dic data
- (void)aggregateData:(nonnull NSDictionary *)dic;


/// stop aggregating data
/// @param isLaunchReport whether it is launch
- (void)stopAggregate:(bool)isLaunchReport;


/// update report header
/// @param reportHeader the new header
- (void)updateReportHeader:(nonnull NSDictionary *)reportHeader;


/// // start semifinished trace record
/// @param record record
- (void)startSemiTraceRecord:(nonnull NSDictionary *)record;


/// // start semifinished span record
/// @param record record
- (void)startSemiSpanRecord:(nonnull NSDictionary *)record;


/// finish semifinished record
/// @param record record data
/// @param spanIDList spanIDList
- (void)finishSemiTraceRecord:(nonnull NSDictionary *)record WithSpanIdList:(nullable NSArray *)spanIDList;


/// finish semi span record
/// @param record record data
- (void)finishSemiSpanRecord:(nonnull NSDictionary *)record;


/// delete semifinished data
/// @param traceID trace id
/// @param spanIDList span id list
- (void)deleteSemifinishedRecords:(nonnull NSString *)traceID WithSpanIdList:(nullable NSArray *)spanIDList;


/// launch report for semi
- (void)launchReportForSemi;


/// search with condition
/// @param condition condition
- (nullable NSDictionary<NSString*, NSArray*> *)searchWithCondition:(nonnull HMSearchCondition *)condition;


/// check if need drop data
- (BOOL)isDropData;


/// check if the server is available
- (BOOL)isServerAvailable;

/// clean all cache data
- (void)cleanAllCache;

/// flush and upload data
- (void)UploadWithFlushImmediately;

/// uploadLocalData
- (void)UploadLocalData;

@end

NS_ASSUME_NONNULL_END
