//
//  BDPWarmBootManager.h
//  Timor
//
//  Created by liubo on 2018/11/22.
//

#import <Foundation/Foundation.h>
#import "BDPWarmBootCleanerProtocol.h"
#import <OPFoundation/BDPUniqueID.h>

#define kBDPWarmBootManagerLogTag  @"WB"

//自定义数据中的key名称
#define BDP_WARMBOOT_DIC_UNIQUEID   @"uniqueid"
#define BDP_WARMBOOT_DIC_TIMER      @"timer"
#define BDP_WARMBOOT_DIC_TIMER_TIME @"timer_time"
#define BDP_WARMBOOT_DIC_RESIDENT   @"resident" //Subnavi
#define BDP_WARMBOOT_DIC_CONFIG_WHITE     @"config_white"

@class BDPTask;

@class BDPNavigationController;

@interface BDPWarmBootManager : NSObject

@property (nonatomic, readonly, copy) NSArray<BDPUniqueID *> *uniqueIdInFront;

/// 热缓存中存在的App的uniqueId集合
@property (nonatomic, readonly) NSSet<BDPUniqueID *> *aliveAppUniqueIdSet;

+ (instancetype)sharedManager;

#pragma mark - Utilities

//设置最大热启动缓存数量，取值范围[1, 5]
- (void)updateMaxWarmBootCacheCount:(int)maxCount;

#pragma mark - Interface

//建议直接使用下面的 Convenience Methods
- (void)cleanCacheWithUniqueID:(BDPUniqueID *)uniqueID;
- (void)cleanCacheWithoutappIDs:(nullable NSArray<NSString *> *)appIDs result:(void(^)(int beforeNum, int afterNum))result;
- (BOOL)hasCacheDataWithUniqueID:(BDPUniqueID *)uniqueID;

- (BOOL)hasCacheData;
- (void)clearAllWarmBootCache;

-(BOOL)isAutoDestroyEnableWithUniqueID:(BDPUniqueID *)uniqueID;

#pragma mark - Convenience Methods

- (BDPNavigationController *)subNaviWithUniqueID:(BDPUniqueID *)uniqueID;
- (void)cacheSubNavi:(BDPNavigationController *)subNavi uniqueID:(BDPUniqueID *)uniqueID cleaner:(BDPWarmBootCleaner)cleaner;

#pragma mark - Resident Timer

- (BOOL)startTimerToReleaseViewWithUniqueID:(BDPUniqueID *)uniqueID;
- (BOOL)stopTimerToReleaseViewWithUniqueID:(BDPUniqueID *)uniqueID;

@end


@interface BDPWarmBootManager (Running)
/// 应用是否正在运行
- (BOOL)appIsRunning:(OPAppUniqueID *)uniqueID;
@end

typedef enum : NSUInteger {
    BDPKeepAliveReasonNone,
    BDPKeepAliveReasonBackgroundAudio,
    BDPKeepAliveReasonWhiteList,
    BDPKeepAliveReasonLaunchConfig,
} BDPKeepAliveReason;

@interface BDPWarmBootManager (LarkKeepAlive)

- (BDPKeepAliveReason)shouldKeepAlive:(OPAppUniqueID *)uniqueID;

@end
