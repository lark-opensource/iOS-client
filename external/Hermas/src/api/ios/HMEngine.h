//
//  HMEngine.h
//  Hermas
//
//  Created by 崔晓兵 on 19/1/2022.
//

#import <Foundation/Foundation.h>
#import "HMConfig.h"
#import "HMInstance.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

BOOL hermas_enabled();

BOOL hermas_drop_data(NSString * _Nonnull moduleId);

BOOL hermas_is_server_available(NSString * _Nonnull moduleId);

BOOL hermas_drop_data_sdk(NSString *_Nonnull moduleId, NSString* _Nullable aid);

BOOL hermas_is_server_available_sdk(NSString *_Nonnull moduleId, NSString* _Nullable aid);

void hermas_set_plist_suite_name_only_once(NSString *_Nonnull suiteName);

NSString * hermas_plist_suite_name();

#ifdef __cplusplus
}  // extern "C"
#endif

typedef void(^FinishBlock)(BOOL success);

extern char const * kEnableHermasRefactorFromSDK;
extern char const * kEnableHermasRefactorFromApp;

@protocol HMExternalSearchDataSource <NSObject>
@required

- (nullable NSArray *)getDataWithParam:(nonnull HMSearchParam *)param;

- (void)removeDataWithParam:(nonnull HMSearchParam *)param;
@end


@interface HMEngine : NSObject

@property (nonatomic, assign, class, getter=isEnabled) BOOL enabled;

@property (nonatomic, strong, nonnull) HMGlobalConfig *globalConfig;

@property (nonatomic, assign) BOOL isDebug;

@property (nonatomic, weak, nullable) id<HMExternalSearchDataSource> searchDataSource;

@property (nonatomic, copy, nullable) size_t(^getFreeDiskSpace)();


+ (void)setEnableHermasRefactor:(BOOL)enableHermasRefactor;


+ (BOOL)enableHermasRefactor;


+ (nonnull instancetype)sharedEngine;


- (nonnull instancetype)init NS_UNAVAILABLE;


/// Register custom network manager which need to conform the protocol HMNetworkProtocol
/// @param networkManager custom networkManager
- (void)registerNetworkManager:(nonnull id<HMNetworkProtocol>)networkManager;


/// Setup global config
/// @param config global config
- (void)setupGlobalConfig:(nonnull HMGlobalConfig *)config;


/// Add a module with config info
/// @param config module config
- (void)addModuleWithConfig:(nonnull HMModuleConfig *)config;


/// Obtain the instance with module id and app id
/// @param moduleId moduleId
/// @param aid aid
- (nullable HMInstance *)instanceWithModuleId:(nonnull NSString *)moduleId aid:(nullable NSString *)aid;


/// Obtain the instance with HMInstanceConfig
/// @param config HMInstanceConfig
- (nullable HMInstance *)instanceWithConfig:(nonnull HMInstanceConfig *)config;


/// Update flow control strategy
/// @param strategy strategy
- (void)updateFlowControlStrategy:(HMFlowControlStrategy)strategy;


/// Update state of report degrade
/// @param needDegrade needDegrade
/// @param moduleId moduleId
- (void)updateReportDegradeState:(BOOL)needDegrade moduleId:(nonnull NSString *)moduleId;

/// update heimdallr init completed flag
/// @param heimdallrInitCompleted heimdallr init completed
- (void)updateHeimdallrInitCompleted:(BOOL)heimdallrInitCompleted;

/// Update module config
/// @param moduleConfig module config
- (void)updateGlobalConfig:(nonnull id<HMGlobalConfig>)moduleConfig;


/// Update module config
/// @param moduleConfig module config
- (void)updateModuleConfig:(nonnull id<HMModuleConfig>)moduleConfig;


/// update report infrequent Change Header
/// @param reportHeader new infrequent Change Header
- (void)updateReportHeader:(nullable NSDictionary *)reportHeader;


/// Stop cache when fetching the config from remote
- (void)stopCache;


/// Search with param and callback
/// @param param the search param
/// @param callback callback
- (void)searchWithParam:(nullable HMSearchParam *)param callback:(nullable void(^)(NSArray<NSString *> *, FinishBlock))callback;


/// Get the latest session
- (nullable NSDictionary *)getLatestSession:(nullable NSString *)rootDir;


/// Update session record
/// @param newSessionRecord record
- (void)updateSessionRecordWith:(nullable NSDictionary *)newSessionRecord;


/// migrate data
/// @param moduleId module id
- (void)migrateDataWithModuleId:(nonnull NSString *)moduleId;


/// clean rollback migrate mark
/// @param moduleId module id
- (void)cleanRollbackMigrateMark:(nonnull NSString *)moduleId;


/// start upload timer
/// @param moduleId module id
- (void)startUploadTimerWithModuleId:(nonnull NSString *)moduleId;


/// stop upload timer
/// @param moduleId module id
- (void)stopUploadTimerWithModuleId:(nonnull NSString *)moduleId;


/// trigger upload manually
/// @param moduleId module id
- (void)triggerUploadManuallyWithModuleId:(nonnull NSString *)moduleId;

/// trigger upload manually
/// @param moduleId module id
- (void)triggerFlushAndUploadManuallyWithModuleId:(nonnull NSString *)moduleId;

/// clean cache manually
/// @param moduleId module id
- (void)cleanAllCacheManuallyWithModuleId:(nonnull NSString *)moduleId;

/// clean the outdate cache of all modules manually
/// @param time the max remain seconds of cache file; e.g. 7 days = 7 * 24 * 60 * 60(s)
- (void)cleanAllCacheManuallyBeforeTime:(int)time;

/// update weight of uploadsize
/// @param weight weight
- (void)updateMaxReportSizeWeights:(nonnull NSDictionary *)weight;

/// get weight of uploadsize
- (nullable NSDictionary *)getUpdateMaxReportSizeWeights;

- (void)uploadLocalDataWithModuleId:(NSString *)moduleId;

@end

NS_ASSUME_NONNULL_END
