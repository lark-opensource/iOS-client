//
//  IESGurdKit+Experiment.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/8/23.
//

#import "IESGeckoKit.h"

typedef NS_ENUM(int, IESGurdExpiredCleanType) {
    IESGurdExpiredCleanTypePassive = 4,
    IESGurdExpiredCleanTypeInitiative = 5,
    IESGurdExpiredCleanTypeLowStorage = 6,
};

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdKit (Experiment)

@property (class, nonatomic, assign, getter=isSettingsEnable) BOOL settingsEnable;

@property (class, nonatomic, assign, getter=isThrottleEnabled) BOOL throttleEnabled;

@property (class, nonatomic, assign, getter=isRetryEnabled) BOOL retryEnabled;

@property (class, nonatomic, assign, getter=isPollingEnabled) BOOL pollingEnabled;

@property (class, nonatomic, assign) int availableStorageFull;

@property (class, nonatomic, assign) int availableStoragePatch;

@property (class, nonatomic, assign) BOOL enableDownload;

@property (class, nonatomic, assign) BOOL enableMetadataIndexLog;

@property (class, nonatomic, assign) BOOL enableEncrypt;

@property (class, nonatomic, assign) BOOL enableOnDemand;

@property (class, nonatomic, assign) NSInteger monitorFlushCount; // setup 方法前调用

@property (class, nonatomic, assign) BOOL clearExpiredCacheEnabled;   

@property (class, nonatomic, copy) NSDictionary<NSString *, NSString *> *expiredTargetGroups;

@property (class, nonatomic, copy) NSDictionary<NSString *, NSArray<NSString *> *> *expiredTargetChannels;

@property (class, nonatomic, assign) BOOL useNewDecompressZstd;

@end

NS_ASSUME_NONNULL_END
