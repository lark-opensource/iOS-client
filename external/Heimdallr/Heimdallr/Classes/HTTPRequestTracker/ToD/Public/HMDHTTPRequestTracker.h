//
//  HMDHTTPRequestTracker.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/21.
//

#import <Foundation/Foundation.h>
#import "HMDTracker.h"
#import "HMDRecordStore.h"
@class HMDHTTPTrackerConfig;
@class HMDHTTPRequestRecord;
@class HMDHTTPDetailRecord;
@class HMDStoreCondition;
@protocol HMDPerformanceReporterDataSource;

// 业务将 HMDHTTPDetailRecord.extraBizInfo 处理成一个结构化的字典回调给 HMD 上报
typedef NSDictionary * _Nullable (^HMDHTTPRequestTrackerCallback)(HMDHTTPDetailRecord * _Nonnull record);

@interface HMDHTTPRequestTracker : HMDTracker

@property (nonatomic, strong, readonly, nullable) NSArray <HMDPerformanceReporterDataSource> *uploaders;
@property (nonatomic, assign, readonly) BOOL ignoreCancelError;//是否忽略-999错误，因为-999错误可能由业务主动触发，也可能因为用户失去耐心取消触发，默认不开启

@property (nonatomic, readonly) HMDHTTPTrackerConfig * _Nonnull trackerConfig;

- (void)addRecord:(HMDHTTPDetailRecord *_Nonnull)record;

- (nullable NSArray<HMDHTTPDetailRecord *> *)recordsFilteredByConditions:(NSArray<HMDStoreCondition *>* _Nonnull)conditions;

- (BOOL)shouldRecordResponsebBodyForRecord:(nonnull HMDHTTPDetailRecord *)record rawData:(nullable NSData *)rawData;


/// whether use url allow list check rule optimized
/// @param useOptimized if is YES, use url allow list check rule optimized; default is NO;
- (void)urlAllowedCheckOptimized:(BOOL)useOptimized DEPRECATED_MSG_ATTRIBUTE("The experience has gained positive benefits;Now the default is YES, no need to call this API");

// HMDHTTPDetailRecord 上报时回调，业务方通过回调自行决定 HMDHTTPDetailRecord.extraBizInfo 的上报格式
- (void)addHTTPRequestTrackerCallback:(HMDHTTPRequestTrackerCallback _Nonnull )callback;
- (void)removeHTTPRequestTrackerCallback:(HMDHTTPRequestTrackerCallback _Nonnull )callback;

@end
