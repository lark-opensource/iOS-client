//
//  HMDTracker.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import <Foundation/Foundation.h>
#import "HMDTrackerRecord.h"
#import "HeimdallrModule.h"
#import "HMDTrackerConfig.h"

#define SHAREDTRACKER(x) + (instancetype)sharedTracker\
{\
    static x *sharedTracker = nil;\
    static dispatch_once_t onceToken;\
    dispatch_once(&onceToken, ^{\
        sharedTracker = [[x alloc] init];\
    });\
    return sharedTracker;\
}\

typedef void (^ _Nullable TrackerDataToDBBlock)(BOOL flag);

#ifdef __cplusplus
extern "C" {
#endif

void dispatch_on_tracker_queue(bool async, dispatch_block_t _Nonnull block);

#ifdef __cplusplus
} // extern "C"
#endif

@class HMDTracker;
@class HMDTrackerRecord;

@interface HMDTracker : HeimdallrModule

@property (nonatomic, strong, nullable) NSMutableArray<HMDTrackerRecord *> *records;

@property (nonatomic, assign) double refreshInterval;

@property (nonatomic, assign) NSUInteger insertIndex;
@property (nonatomic, assign) BOOL hasNewData;
@property (nonatomic, strong, nonnull) NSLock * lock;

+ (instancetype _Nonnull)sharedTracker;

- (void)didCollectOneRecord:(HMDTrackerRecord * _Nullable)record;
- (void)didCollectOneRecord:(HMDTrackerRecord * _Nullable)record trackerBlock:(TrackerDataToDBBlock)block;
- (void)didCollectOneRecord:(HMDTrackerRecord * _Nullable)record async:(BOOL)async;
- (void)didCollectOneRecord:(HMDTrackerRecord * _Nullable)record async:(BOOL)async trackerBlock:(TrackerDataToDBBlock)block;
- (void)flushRecord:(HMDTrackerRecord * _Nullable)record async:(BOOL)async trackerBlock:(TrackerDataToDBBlock)block;

- (void)updateRecordWithConfig:(HMDTrackerRecord * _Nullable)record;//入库之前 根据config更新record，目前基类只更新enable_upload标志，子类可重写

- (void)dropAllRecordFromMemoryCacheOrDatabase;

+ (void)asyncActionOnTrackerQueue:(dispatch_block_t _Nullable)action;
+ (NSString * _Nullable)getLastSceneIfAvailable;

//返回用户的操作轨迹，包括用户最后进入的10个页面和时间等
+ (NSDictionary * _Nullable)getOperationTraceIfAvailable;

- (void)performanceActionOnTrackerAsyncQueue:(dispatch_block_t _Nullable)block;

@end
