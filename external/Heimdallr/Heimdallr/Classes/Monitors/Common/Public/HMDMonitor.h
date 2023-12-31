//
//  HMDMonitor.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import <Foundation/Foundation.h>
#import "HeimdallrModule.h"
#import "HMDMonitorRecord.h"
#import "HMDRecordStore.h"
#import "HMDMonitorCurve.h"
#import "HMDMonitorConfig.h"
#import "HMDRecordStoreObject.h"

#ifdef __cplusplus
extern "C" {
#endif

dispatch_queue_t _Nullable hmd_get_monitor_queue(void);
void dispatch_on_monitor_queue(dispatch_block_t _Nullable block);
    
#ifdef __cplusplus
}
#endif

@class HMDMonitor;
@class HMDRecordStore;

typedef NSString* _Nullable HMDMonitorName;
typedef void(^ HMDMonitorCallback)(HMDMonitorRecord* _Nullable);

@interface HMDMonitor : HeimdallrModule
@property (nonatomic, strong, readonly, nonnull) HMDMonitorCurve *curve;
@property (nonatomic, readonly, nullable) HMDMonitorName name;

//HMDTimerMonitorConfiguration
@property (nonatomic, assign) double refreshInterval;
@property (nonatomic, assign) double curPageUsage;

// open by scene
@property (atomic, assign) BOOL isRunningWithSpecialScene;

// records
- (nonnull NSArray *)fetchUploadRecords;
+ (nonnull instancetype)sharedMonitor;

// record产生时的回调
- (void)addMonitorCallbacks:(HMDMonitorCallback _Nonnull)callback;
- (void)removeMonitorCallbacks:(HMDMonitorCallback _Nonnull)callback;
/// 子类的refresh实现数据的插入数据库和缓存
- (nullable HMDMonitorRecord *)refresh;
- (void)startWithInterval:(CFTimeInterval)interval;

- (void)didEnterScene:(nullable NSString *)scene;
- (void)willLeaveScene:(nullable NSString *)scene;

- (void)enterCustomScene:(nonnull NSString *)scene;
- (void)leaveCustomScene:(nonnull NSString *)scene;

@end



