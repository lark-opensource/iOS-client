

#import <Foundation/Foundation.h>

@interface TTDownloadTncConfigManager : NSObject

@property (atomic, assign, readonly) BOOL isTncSetThrottleNetSpeed;
@property (atomic, assign, readonly) int8_t tncIsSliced;
@property (atomic, assign, readonly) int8_t tncIsHttps2HttpFallback;
@property (atomic, assign, readonly) int8_t tncIsDownloadWifiOnly;
@property (atomic, assign, readonly) int8_t tncIsUseTracker;
@property (atomic, assign, readonly) int8_t tncIsBackgroundDownloadEnable;
@property (atomic, assign, readonly) int8_t tncIsBackgroundDownloadWifiOnlyDisable;
@property (atomic, assign, readonly) int8_t tncIsSkipGetContentLength;
@property (atomic, assign, readonly) int8_t tncIsServerSupportRangeDefault;
@property (atomic, assign, readonly) int8_t tncIsCheckCache;
@property (atomic, assign, readonly) int8_t tncIsRetainCacheIfCheckFailed;
@property (atomic, assign, readonly) int8_t tncIsUrgentModeEnable;
@property (atomic, assign, readonly) int8_t tncIsClearCacheIfNoMaxAge;
@property (atomic, assign, readonly) int8_t preCheckFileLength;
@property (atomic, assign, readonly) int8_t tncIsTTNetUrgentModeEnable;
@property (atomic, assign, readonly) int8_t restartImmediatelyWhenNetworkChange;
@property (atomic, assign, readonly) int8_t tncIsIgnoreMaxAgeCheck;
@property (atomic, assign, readonly) int8_t tncIsCommonParamEnable;
@property (atomic, assign, readonly) int8_t tncIsForceCacheLifeTimeMaxEnable;
@property (atomic, assign, readonly) uint32_t tncDLCacheCapacityMax;
@property (atomic, assign, readonly) uint32_t tncDLCacheClearOnceCount;
@property (atomic, assign, readonly) int8_t tncDataBaseStrategy;

- (NSInteger)getUrlRetryTimes;

- (NSTimeInterval)getRetryTimeoutInterval;

- (NSTimeInterval)getRetryTimeoutIntervalIncrement;

- (NSInteger)getSliceMaxNumber;

- (int64_t)getMinDevisionSize;

- (int64_t)getMergeDataLength;

- (int64_t)getSliceMaxRetryTimes;

- (int64_t)getContentLengthWaitMaxInterval;

- (int64_t)getThrottleNetSpeed;

- (int8_t)getRestoreTimesAutomatic;

- (int16_t)getTTNetRequestTimeout;

- (int16_t)getTTNetReadDataTimeout;

- (int16_t)getTTNetRcvHeaderTimeout;

- (int16_t)getTTNetProtectTimeout;
@end
