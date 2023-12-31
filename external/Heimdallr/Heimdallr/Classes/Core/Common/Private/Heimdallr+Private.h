//
//  Heimdallr+Private.h
//  Heimdallr
//
//  Created by fengyadong on 2018/4/23.
//

#import "Heimdallr.h"
#import "HMDPerformanceReporter.h"
#import "HMDHeimdallrConfig.h"
#import "HMDRecordStore.h"
#import "HMDSessionTracker.h"
#import "HMDStoreIMP.h"
#import "HMDConfigManager.h"
#import "Heimdallr+SafeMode.h"

#define HEMDAILLR 1

FOUNDATION_EXTERN NSString *kHMDSyncModulesKey;

@interface Heimdallr(Private)

@property (atomic, strong, readonly) HMDHeimdallrConfig *config;
@property (nonatomic, strong, readonly) HMDConfigManager *configManager;
@property (nonatomic, strong, readonly) HMDRecordStore *store;
@property (nonatomic, strong, readonly) HMDPerformanceReporter *reporter;
@property (atomic, assign, readonly) BOOL isRemoteReady;
@property (nonatomic, strong, readonly) HMDSessionTracker *sessionTracker;
@property (nonatomic, assign, readonly) BOOL initializationCompleted;
@property (nonatomic, assign, readwrite) HMDSafeModeType safeModeType;

- (id<HMDStoreIMP>)database;

- (void)updateRecordCount:(NSInteger)count;
- (void)updateConfig:(HMDHeimdallrConfig *)config;
- (void)cleanup;
- (id<HeimdallrModule>)moduleWithName:(NSString*)name;
+ (NSDictionary *)syncStartModuleSettings;

// Used for loop for all modules in Heimdallr
- (NSArray<id<HeimdallrModule>> *)copyAllRemoteModules;

@end

extern void dispatch_on_heimdallr_queue(bool async, dispatch_block_t block);
extern dispatch_queue_t hmd_get_heimdallr_queue(void);

#ifdef DEBUG
#define HMD_DEBUG_ASSERT_ON_Heimdallr_QUEUE() debug_assert_on_heimdallr_queue()
void debug_assert_on_heimdallr_queue(void);
#else
#define HMD_DEBUG_ASSERT_ON_Heimdallr_QUEUE()
#endif
