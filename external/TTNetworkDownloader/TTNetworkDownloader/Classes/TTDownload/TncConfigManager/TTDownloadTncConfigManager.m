
#import "TTDownloadTncConfigManager.h"
#import "TTDownloadManager.h"
#import "TTDownloadClearCache.h"

#import <TTNetworkManager/TTNetworkManager.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const kUrlRetryTimes = @"url_retry_times";

static NSString *const kRetryTimeoutInterval = @"retry_timeout_interval";

static NSString *const kRetryTimeoutIntervalIncrement = @"retry_timeout_increment";

static NSString *const kIsSliced = @"is_sliced";

static NSString *const kSliceNumberMax = @"slice_number_max";

static NSString *const kDevisionSizeMin = @"devision_size_min";

static NSString *const kMergeDataLength = @"merge_data_length";

static NSString *const kSliceRetryTimesMax = @"slice_retry_times_max";

static NSString *const kContentLengthWaitMaxInterval = @"content_length_wait_interval_max";

static NSString *const kThrottleNetSpeed = @"throttle_net_speed";

static NSString *const kIsHttps2HttpFallback = @"is_https_fallback";

static NSString *const kIsDownloadWifiOnly = @"is_wifi_only";

static NSString *const kAutomaticRestoreTimes = @"automatic_restore_times";

static NSString *const kIsTrackerEnable = @"is_tracker_enable";

static NSString *const kIsBackgroundDownloadEnable = @"is_bg_enable";

static NSString *const kDisableBackgroundDownloadIOSVersionList = @"bg_disable_list";

static NSString *const kIsBackgroundDownloadWifiOnlyDisable = @"is_bg_wifi_only_disable";

static NSString *const kBackgroundDownloadDisableWifiOnlyVersionList = @"bg_disable_wifi_only_list";

//isSkipGetContentLength
static NSString *const kIsSkipGetContentLength = @"is_skip_get_content_length";
static NSString *const kIsServerSupportRangeDefault = @"is_server_support_range";
static NSString *const kIsCheckCache = @"is_check_cache";
static NSString *const kIsIgnoreMaxAgeCheck = @"is_ignore_max_age_check";
static NSString *const kIsRetainCacheIfCheckFailed = @"is_retain_cache_if_check_failed";
static NSString *const kIsUrgentModeEnable = @"is_urgent_mode_enable";
static NSString *const kIsTTNetUrgentModeEnable = @"is_ttnet_urgent_mode_enable";
static NSString *const kIsClearCacheIfNoMaxAge = @"is_clear_cache_if_no_max_age";
static NSString *const kPreCheckFileLength = @"is_precheck_file_length";
static NSString *const kDownloadRequestTimeout = @"ttnet_request_timeout";
static NSString *const kDownloadReadDataTimeout = @"ttnet_read_timeout";
static NSString *const kDownloadRcvHeaderTimeout = @"ttnet_rcv_header_timeout";
static NSString *const kDownloadProtectTimeout = @"ttnet_protect_timeout";
static NSString *const kClearCacheRules = @"clear_cache_rules";

static NSString *const kRestartImmediatelyWhenNetworkChange = @"restart_if_net_change";
static NSString *const kIsCommonParamEnable = @"is_common_param_enable";
static NSString *const kIsForceTTLToCache = @"is_force_ttl_to_cache";
static NSString *const kDLCacheCapacityMax = @"cache_capacity_max";
static NSString *const kDLCacheClearOnceCount = @"clear_once_count";
static NSString *const kDataBaseStrategy = @"data_base_strategy";

@interface TTDownloadTncConfigManager()
@property (atomic, strong) DownloadGlobalParameters *tncServerConfig;

@property (atomic, assign, readwrite) BOOL isTncSetThrottleNetSpeed;
@property (atomic, assign, readwrite) int8_t tncIsSliced;
@property (atomic, assign, readwrite) int8_t tncIsHttps2HttpFallback;
@property (atomic, assign, readwrite) int8_t tncIsDownloadWifiOnly;
@property (atomic, assign, readwrite) int8_t tncIsUseTracker;
@property (atomic, assign, readwrite) int8_t tncIsBackgroundDownloadEnable;
@property (atomic, assign, readwrite) int8_t tncIsBackgroundDownloadWifiOnlyDisable;
@property (atomic, assign, readwrite) int8_t tncIsSkipGetContentLength;
@property (atomic, assign, readwrite) int8_t tncIsServerSupportRangeDefault;
@property (atomic, assign, readwrite) int8_t tncIsCheckCache;
@property (atomic, assign, readwrite) int8_t tncIsRetainCacheIfCheckFailed;
@property (atomic, assign, readwrite) int8_t tncIsUrgentModeEnable;
@property (atomic, assign, readwrite) int8_t tncIsClearCacheIfNoMaxAge;
@property (atomic, assign, readwrite) int8_t preCheckFileLength;
@property (atomic, assign, readwrite) int8_t tncIsTTNetUrgentModeEnable;
@property (atomic, assign, readwrite) int8_t restartImmediatelyWhenNetworkChange;
@property (atomic, assign, readwrite) int8_t tncIsIgnoreMaxAgeCheck;
@property (atomic, assign, readwrite) int8_t tncIsCommonParamEnable;
@property (atomic, assign, readwrite) int8_t tncIsForceCacheLifeTimeMaxEnable;
@property (atomic, assign, readwrite) uint32_t tncDLCacheCapacityMax;
@property (atomic, assign, readwrite) uint32_t tncDLCacheClearOnceCount;
@property (atomic, assign, readwrite) int8_t tncDataBaseStrategy;
@end

@implementation TTDownloadTncConfigManager
- (id)init {
    self = [super init];
    if (self) {
        _tncIsSliced = -1;
        _tncIsHttps2HttpFallback = -1;
        _tncIsDownloadWifiOnly = -1;
        _tncIsUseTracker = -1;
        _tncIsBackgroundDownloadEnable = -1;
        _tncIsBackgroundDownloadWifiOnlyDisable = -1;
        _tncIsSkipGetContentLength = -1;
        _tncIsServerSupportRangeDefault = -1;
        _tncIsCheckCache = -1;
        _tncIsRetainCacheIfCheckFailed = -1;
        _tncIsUrgentModeEnable = -1;
        _tncIsClearCacheIfNoMaxAge = -1;
        _preCheckFileLength = -1;
        _tncIsTTNetUrgentModeEnable = -1;
        _restartImmediatelyWhenNetworkChange = -1;
        _tncIsIgnoreMaxAgeCheck = -1;
        _tncIsCommonParamEnable = -1;
        _tncIsForceCacheLifeTimeMaxEnable = -1;
        _tncDLCacheCapacityMax = 0U;
        _tncDLCacheClearOnceCount = 0U;
        _tncDataBaseStrategy = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(ttnetServerConfigChanged:)
                                                     name:kTTNetServerConfigChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTTNetServerConfigChangeNotification object:nil];
}

- (void)tncConfigParser:(NSData *)data {
    if (!data) {
        return;
    }
    NSError *jsonError = nil;
    DLLOGD(@"%s GetDomainblock is %@", __FUNCTION__, data);
    id dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    DLLOGD(@"%s dict=%@", __FUNCTION__, dict);
    if (!jsonError && [dict isKindOfClass:NSDictionary.class]) {
    
        id dataDic = [dict objectForKey:@"data"];
        if (![dataDic isKindOfClass:NSDictionary.class]) {
            return;
        }

        id jsonDict = [dataDic objectForKey:@"ios_downloader"];
    
        DLLOGD(@"%s jsonDict=%@", __FUNCTION__, jsonDict);
        if (!jsonDict || ![jsonDict isKindOfClass:NSDictionary.class]) {
            return;
        }
        if (!self.tncServerConfig) {
            self.tncServerConfig = [[DownloadGlobalParameters alloc] init];
        }
        NSInteger urlRetryTimes = [[jsonDict objectForKey:kUrlRetryTimes] longValue];
        self.tncServerConfig.urlRetryTimes = (urlRetryTimes > 0 && urlRetryTimes < 10) ? urlRetryTimes : 0;
        DLLOGD(@"%s self.tncServerConfig.urlRetryTimes=%ld", __FUNCTION__, (long)self.tncServerConfig.urlRetryTimes);
    
        NSTimeInterval retryTimeoutInterval = [[jsonDict objectForKey:kRetryTimeoutInterval] longLongValue];
        self.tncServerConfig.retryTimeoutInterval = (retryTimeoutInterval > 0 && retryTimeoutInterval < 100) ? retryTimeoutInterval : 0;
        DLLOGD(@"%s self.tncServerConfig.retryTimeoutInterval=%f", __FUNCTION__, self.tncServerConfig.retryTimeoutInterval);
    
        NSTimeInterval retryTimeoutIntervalIncrement = [[jsonDict objectForKey:kRetryTimeoutIntervalIncrement] longLongValue];
        self.tncServerConfig.retryTimeoutIntervalIncrement = (retryTimeoutIntervalIncrement > 0 && retryTimeoutIntervalIncrement < 100) ? retryTimeoutIntervalIncrement : 0;
        DLLOGD(@"%s self.tncServerConfig.retryTimeoutIntervalIncrement=%f", __FUNCTION__, self.tncServerConfig.retryTimeoutIntervalIncrement);
    
        self.tncIsSliced = -1;
        id isSliced = [jsonDict objectForKey:kIsSliced];
        if (isSliced) {
            self.tncIsSliced = ([isSliced intValue] > 0) ? 1 : 0;
            DLLOGD(@"%s self.tncServerConfig.isSliced=%d", __FUNCTION__, self.tncServerConfig.isSliced);
        }
    
        NSInteger sliceMaxNumber = [[jsonDict objectForKey:kSliceNumberMax] intValue];
        self.tncServerConfig.sliceMaxNumber = (sliceMaxNumber > 0 && sliceMaxNumber <= 4) ? sliceMaxNumber : 0;
        DLLOGD(@"%s self.tncServerConfig.sliceMaxNumber=%ld", __FUNCTION__, (long)self.tncServerConfig.sliceMaxNumber);
    
        int64_t minDevisionSize = [[jsonDict objectForKey:kDevisionSizeMin] longLongValue];
        self.tncServerConfig.minDevisionSize = minDevisionSize > 0 ? minDevisionSize : 0;
        DLLOGD(@"%s self.tncServerConfig.minDevisionSize=%lld", __FUNCTION__, self.tncServerConfig.minDevisionSize);
    
        int64_t mergeDataLength = [[jsonDict objectForKey:kMergeDataLength] longLongValue];
        self.tncServerConfig.mergeDataLength = (mergeDataLength > 0 && mergeDataLength <= 50) ? mergeDataLength : 0;
        DLLOGD(@"%s self.tncServerConfig.mergeDataLength=%lld", __FUNCTION__, self.tncServerConfig.mergeDataLength);
    
        NSInteger sliceMaxRetryTimes = [[jsonDict objectForKey:kSliceRetryTimesMax] intValue];
        self.tncServerConfig.sliceMaxRetryTimes = (sliceMaxRetryTimes > 0 && sliceMaxRetryTimes <= 10) ? sliceMaxRetryTimes : 0;
    
        NSTimeInterval contentLengthWaitMaxInterval = [[jsonDict objectForKey:kContentLengthWaitMaxInterval] longLongValue];
        self.tncServerConfig.contentLengthWaitMaxInterval = (contentLengthWaitMaxInterval > 0 && contentLengthWaitMaxInterval <= 60) ? contentLengthWaitMaxInterval : 0;
    
        self.isTncSetThrottleNetSpeed = NO;
        id throttleNetSpeed = [jsonDict objectForKey:kThrottleNetSpeed];
        if (throttleNetSpeed) {
            self.isTncSetThrottleNetSpeed = YES;
            self.tncServerConfig.throttleNetSpeed = [throttleNetSpeed longLongValue];
        }
    
        self.tncIsHttps2HttpFallback = -1;
        id isHttps2HttpFallback = [jsonDict objectForKey:kIsHttps2HttpFallback];
        if (isHttps2HttpFallback) {
            self.tncIsHttps2HttpFallback = [isHttps2HttpFallback intValue] > 0 ? 1 : 0;
        }

        self.tncIsDownloadWifiOnly = -1;
        id isDownloadWifiOnly = [jsonDict objectForKey:kIsDownloadWifiOnly];
        if (isDownloadWifiOnly) {
            self.tncIsDownloadWifiOnly = [isDownloadWifiOnly intValue] > 0 ? 1 : 0;
        }
    
        int8_t restoreTimesAutomatic = [[jsonDict objectForKey:kAutomaticRestoreTimes] intValue];
        self.tncServerConfig.restoreTimesAutomatic = (restoreTimesAutomatic > 0 && restoreTimesAutomatic <= 100) ? restoreTimesAutomatic : 0;
    
        self.tncIsUseTracker = -1;
        id isUseTracker = [jsonDict objectForKey:kIsTrackerEnable];
        if (isUseTracker) {
            self.tncIsUseTracker = [isUseTracker intValue] > 0 ? 1 : 0;
        }
    
        self.tncIsBackgroundDownloadEnable = -1;
        id isBackgroundDownloadEnable = [jsonDict objectForKey:kIsBackgroundDownloadEnable];
        if (isBackgroundDownloadEnable) {
            self.tncIsBackgroundDownloadEnable = [isBackgroundDownloadEnable intValue] > 0 ? 1 : 0;
        }
    
        //self.tncServerConfig.disableBackgroundDownloadIOSVersionList = [[jsonDict objectForKey:kDisableBackgroundDownloadIOSVersionList] componentsSeparatedByString:@","];
        id disableBackgroundDownloadIOSVersionList = [jsonDict objectForKey:kDisableBackgroundDownloadIOSVersionList];
        if (disableBackgroundDownloadIOSVersionList) {
            if ([self isMatchCurrentOS:[self parseVersionNumbers:disableBackgroundDownloadIOSVersionList separatedString:@","]]) {
                self.tncIsBackgroundDownloadEnable = 0;
            }
        }
    
        self.tncIsBackgroundDownloadWifiOnlyDisable = -1;
        id isBackgroundDownloadWifiOnlyDisable = [jsonDict objectForKey:kIsBackgroundDownloadWifiOnlyDisable];
        if (isBackgroundDownloadWifiOnlyDisable) {
            self.tncIsBackgroundDownloadWifiOnlyDisable = [isBackgroundDownloadWifiOnlyDisable intValue] > 0 ? 1 : 0;
        }

        id backgroundDownloadDisableWifiOnlyVersionList = [jsonDict objectForKey:kBackgroundDownloadDisableWifiOnlyVersionList];
        if (backgroundDownloadDisableWifiOnlyVersionList) {
            if ([self isMatchCurrentOS:[self parseVersionNumbers:backgroundDownloadDisableWifiOnlyVersionList separatedString:@","]]) {
                self.tncIsBackgroundDownloadWifiOnlyDisable = 1;
            }
        }
    
        self.tncIsSkipGetContentLength = -1;
        id isSkipGetContentLength = [jsonDict objectForKey:kIsSkipGetContentLength];
        if (isSkipGetContentLength) {
            self.tncIsSkipGetContentLength = [isSkipGetContentLength intValue] > 0 ? 1 : 0;
        }
    
        self.tncIsServerSupportRangeDefault = -1;
        id isServerSupportRangeDefault = [jsonDict objectForKey:kIsServerSupportRangeDefault];
        if (isServerSupportRangeDefault) {
            self.tncIsServerSupportRangeDefault = [isServerSupportRangeDefault intValue] > 0 ? 1 : 0;
        }
    
        self.tncIsCheckCache = -1;
        id isCheckCache = [jsonDict objectForKey:kIsCheckCache];
        if (isCheckCache) {
            self.tncIsCheckCache = [isCheckCache intValue] > 0 ? 1 : 0;
        }
    
        self.tncIsRetainCacheIfCheckFailed = -1;
        id isRetainCacheIfCheckFailed = [jsonDict objectForKey:kIsRetainCacheIfCheckFailed];
        if (isRetainCacheIfCheckFailed) {
            self.tncIsRetainCacheIfCheckFailed = [isRetainCacheIfCheckFailed intValue] > 0 ? 1 : 0;
        }
    
        self.tncIsUrgentModeEnable = -1;
        id isUrgentModeEnable = [jsonDict objectForKey:kIsUrgentModeEnable];
        if (isUrgentModeEnable) {
            self.tncIsUrgentModeEnable = [isUrgentModeEnable intValue] > 0 ? 1 : 0;
        }

        self.tncIsClearCacheIfNoMaxAge = -1;
        id isClearCacheIfNoMaxAge = [jsonDict objectForKey:kIsClearCacheIfNoMaxAge];
        if (isClearCacheIfNoMaxAge) {
            self.tncIsClearCacheIfNoMaxAge = [isClearCacheIfNoMaxAge intValue] > 0 ? 1 : 0;
        }

        self.tncIsIgnoreMaxAgeCheck = -1;
        id isIgnoreMaxAge = [jsonDict objectForKey:kIsIgnoreMaxAgeCheck];
        if (isIgnoreMaxAge) {
            self.tncIsClearCacheIfNoMaxAge = [isIgnoreMaxAge intValue] > 0 ? 1 : 0;
        }
    
        self.preCheckFileLength = -1;
        id isPreCheckFileLength = [jsonDict objectForKey:kPreCheckFileLength];
        if (isPreCheckFileLength) {
            self.preCheckFileLength = [isPreCheckFileLength intValue] > 0 ? 1 : 0;
        }
    
        self.tncIsTTNetUrgentModeEnable = -1;
        id isTTNetUrgentModeEnable = [jsonDict objectForKey:kIsTTNetUrgentModeEnable];
        if (isTTNetUrgentModeEnable) {
            self.tncIsTTNetUrgentModeEnable = [isTTNetUrgentModeEnable intValue] > 0 ? 1 : 0;
        }

        self.tncIsCommonParamEnable = -1;
        id isCommonParamEnable = [jsonDict objectForKey:kIsCommonParamEnable];
        if (isCommonParamEnable) {
            self.tncIsCommonParamEnable = [isCommonParamEnable intValue] > 0 ? 1 : 0;
        }

        int16_t requestTimeout = [[jsonDict objectForKey:kDownloadRequestTimeout] intValue];
        self.tncServerConfig.ttnetRequestTimeout = (requestTimeout > 0 && requestTimeout <= 300) ? requestTimeout : 0;
    
        int16_t readTimeout = [[jsonDict objectForKey:kDownloadReadDataTimeout] intValue];
        self.tncServerConfig.ttnetReadDataTimeout = (readTimeout > 0 && readTimeout <= 300) ? readTimeout : 0;
    
        int16_t headerTimeout = [[jsonDict objectForKey:kDownloadRcvHeaderTimeout] intValue];
        self.tncServerConfig.ttnetRcvHeaderTimeout = (headerTimeout > 0 && headerTimeout <= 300) ? headerTimeout : 0;
    
        int16_t protectTimeout = [[jsonDict objectForKey:kDownloadProtectTimeout] intValue];
        self.tncServerConfig.ttnetProtectTimeout = (protectTimeout > 0 && protectTimeout <= 300) ? protectTimeout : 0;
        
        self.tncIsForceCacheLifeTimeMaxEnable = -1;
        id isForceCacheLifeTimeMaxEnable = [jsonDict objectForKey:kIsForceTTLToCache];
        if (isForceCacheLifeTimeMaxEnable) {
            self.tncIsForceCacheLifeTimeMaxEnable = [isForceCacheLifeTimeMaxEnable intValue] > 0 ? 1 : 0;
        }
        
        self.tncDLCacheCapacityMax = 0U;
        uint32_t downloaderCacheCapacityMax = [[jsonDict objectForKey:kDLCacheCapacityMax] unsignedIntValue];
        if (downloaderCacheCapacityMax >= 500) {
            self.tncDLCacheCapacityMax = downloaderCacheCapacityMax;
        }
        
        self.tncDLCacheClearOnceCount = 0U;
        uint32_t downloaderCacheClearOnceCount = [[jsonDict objectForKey:kDLCacheClearOnceCount] unsignedIntValue];
        if (downloaderCacheClearOnceCount > 0) {
            self.tncDLCacheClearOnceCount = downloaderCacheClearOnceCount;
        }
        
        self.tncDataBaseStrategy = 0;
        int8_t databaseStrategy = [[jsonDict objectForKey:kDataBaseStrategy] intValue];
        if (databaseStrategy > 0) {
            self.tncDataBaseStrategy = databaseStrategy;
        }
        
        NSArray *clearRuleJsonArray = [jsonDict objectForKey:kClearCacheRules];
        
        DLLOGD(@"%s clearRuleJsonDic=%@", __FUNCTION__, clearRuleJsonArray);
        if (clearRuleJsonArray) {
            //Delay 5s to do clear work to avoid affecting cold start.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_global_queue(0, 0), ^{
                [TTDownloadClearCache updateClearCacheRule:clearRuleJsonArray];
            });
        }

        self.restartImmediatelyWhenNetworkChange = -1;
        id isRestartImmediately = [jsonDict objectForKey:kRestartImmediatelyWhenNetworkChange];
        if (isRestartImmediately) {
            self.restartImmediatelyWhenNetworkChange = [isRestartImmediately intValue] > 0 ? 1 : 0;
        }
    }
}

- (NSArray<NSString *> *)parseVersionNumbers:(NSString *)osVersion separatedString:(NSString *)separatedString {
    if (!osVersion || !separatedString) {
        return nil;
    }
    return [osVersion componentsSeparatedByString:separatedString];
}

- (BOOL)isValidOsNumber:(NSString *)versionNumberString {
    if (!versionNumberString) {
        return NO;
    }
    if ([versionNumberString containsString:@"."]) {
        versionNumberString = [versionNumberString stringByReplacingOccurrencesOfString:@"." withString:@""];
    }
    if ([versionNumberString containsString:@" "]) {
        versionNumberString = [versionNumberString stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    NSString *pattern = @"^\\d+$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [predicate evaluateWithObject:versionNumberString];
}

- (BOOL)isValidOsRange:(NSString *)startVersion endVersion:(NSString *)endVersion {
    if ([startVersion isEqualToString:@""]) {
        if (![endVersion isEqualToString:@""]) {
            return [self isValidOsNumber:endVersion];
        }
        return NO;
    } else {
        if ([endVersion isEqualToString:@""]) {
            return [self isValidOsNumber:startVersion];
        } else {
            return [self isValidOsNumber:startVersion] && [self isValidOsNumber:endVersion];
        }
    }
}

- (NSInteger)compareVersion:(NSString *)currentVersion toVersion:(NSString *)targetVersion isEndVersionStartWithRange:(BOOL)isRange {
    if ([currentVersion containsString:@" "]) {
        currentVersion = [currentVersion stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    if ([targetVersion containsString:@" "]) {
        targetVersion = [targetVersion stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    NSArray *currentVersionList = [self parseVersionNumbers:currentVersion separatedString:@"."];
    NSArray *targetVersionList = [self parseVersionNumbers:targetVersion separatedString:@"."];
    for (int i = 0; i < currentVersionList.count || i < targetVersionList.count; i++)
    {
        NSInteger curVerNumber = 0, tarVerNumber = 0;
        if (i < currentVersionList.count) {
            curVerNumber = [currentVersionList[i] integerValue];
        }
        if (i < targetVersionList.count) {
            tarVerNumber = [targetVersionList[i] integerValue];
        }
        if (isRange && (curVerNumber == tarVerNumber)) {
            return -1;
        }
        if (curVerNumber > tarVerNumber) {
            return 1;
        } else if (curVerNumber < tarVerNumber) {
            return -1;
        }
    }
    return 0;
}

- (BOOL)isMatchCurrentOS:(NSArray<NSString *> *)targetVersionList {
    if ([TTDownloadManager.class isArrayValid:targetVersionList]) {
        NSString *currentOsVersion = [[UIDevice currentDevice] systemVersion];
        if (![currentOsVersion containsString:@"."]) {
            currentOsVersion = [NSString stringWithFormat:@"%@.0", currentOsVersion];
        }
        for (NSString *item in targetVersionList) {
            if ([item containsString:@"~"]) {
                NSArray *beginEndVersionArray = [self parseVersionNumbers:item separatedString:@"~"];
                if (beginEndVersionArray.count != 2) {
                    DLLOGE(@"item in beginEndVersionArray error");
                    continue;
                }
                NSString *beginVersion = [beginEndVersionArray firstObject];
                NSString *endVersion = [beginEndVersionArray lastObject];
                if ([beginVersion containsString:@" "]) {
                    beginVersion = [beginVersion stringByReplacingOccurrencesOfString:@" " withString:@""];
                }
                if ([endVersion containsString:@" "]) {
                    endVersion = [endVersion stringByReplacingOccurrencesOfString:@" " withString:@""];
                }
                if (![self isValidOsRange:beginVersion endVersion:endVersion]) {
                    DLLOGE(@"invalid OS range");
                    continue;
                }
                if (([self compareVersion:beginVersion toVersion:endVersion isEndVersionStartWithRange:NO] > 0) && (![endVersion isEqualToString:@""])) {
                    DLLOGE(@"start OS version is bigger than end OS version");
                    continue;
                }
                NSInteger beginCompare = [self compareVersion:currentOsVersion toVersion:beginVersion isEndVersionStartWithRange:NO];
                NSInteger endCompare = -1;
                if (![endVersion isEqualToString:@""]) {
                    BOOL isEndVersionStartWithRange = NO;
                    if (![endVersion containsString:@"."]) {
                        isEndVersionStartWithRange = YES;
                    }
                    endCompare = [self compareVersion:currentOsVersion toVersion:endVersion isEndVersionStartWithRange:isEndVersionStartWithRange];
                }
                
                if (beginCompare >= 0 && endCompare <= 0) {
                    return YES;
                }
            } else {
                NSString *optimizedItem = item;
                if (![item containsString:@"."]) {
                    optimizedItem = [NSString stringWithFormat:@"%@.", item];
                }
                if ([currentOsVersion hasPrefix:optimizedItem]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (NSInteger)getUrlRetryTimes {
    return self.tncServerConfig.urlRetryTimes;
}

- (NSTimeInterval)getRetryTimeoutInterval {
    return self.tncServerConfig.retryTimeoutInterval;
}

- (NSTimeInterval)getRetryTimeoutIntervalIncrement {
    return self.tncServerConfig.retryTimeoutIntervalIncrement;
}

- (NSInteger)getSliceMaxNumber {
    return self.tncServerConfig.sliceMaxNumber;
}

- (int64_t)getMinDevisionSize {
    return self.tncServerConfig.minDevisionSize;
}

- (int64_t)getMergeDataLength {
    return self.tncServerConfig.mergeDataLength;
}

- (int64_t)getSliceMaxRetryTimes {
    return self.tncServerConfig.sliceMaxRetryTimes;
}

- (int64_t)getContentLengthWaitMaxInterval {
    return self.tncServerConfig.contentLengthWaitMaxInterval;
}

- (int64_t)getThrottleNetSpeed {
    return self.tncServerConfig.throttleNetSpeed;
}

- (int8_t)getRestoreTimesAutomatic {
    return self.tncServerConfig.restoreTimesAutomatic;
}

- (int16_t)getTTNetRequestTimeout {
    return self.tncServerConfig.ttnetRequestTimeout;
}

- (int16_t)getTTNetReadDataTimeout {
    return self.tncServerConfig.ttnetReadDataTimeout;
}

- (int16_t)getTTNetRcvHeaderTimeout {
    return self.tncServerConfig.ttnetRcvHeaderTimeout;
}

- (int16_t)getTTNetProtectTimeout {
    return self.tncServerConfig.ttnetProtectTimeout;
}

- (void)ttnetServerConfigChanged:(NSNotification *)notification {
    NSDictionary *infoDic = notification.userInfo;
    NSData *data = [infoDic objectForKey:kTTNetServerConfigChangeDataKey];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self tncConfigParser:data];
    });
}

@end

NS_ASSUME_NONNULL_END
