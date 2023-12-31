//
//  IESGurdDefines.h
//  Pods
//
//  Created by willorfang on 2018/6/15.
//

#ifndef IESGurdDefines_h
#define IESGurdDefines_h

#import "IESGurdStatusCodes.h"

NS_ASSUME_NONNULL_BEGIN

//某个channel缓存的状态
typedef NS_ENUM(NSInteger, IESGurdChannelCacheStatus) {
    IESGurdChannelCacheStatusNotFound,  //未找到
    IESGurdChannelCacheStatusInactive,  //未激活
    IESGurdChannelCacheStatusActive     //已激活
};

//某个channel文件类型
typedef NS_ENUM(NSInteger, IESGurdChannelFileType) {
    IESGurdChannelFileTypeCompressed,
    IESGurdChannelFileTypeUncompressed,
    IESGurdChannelFileTypeSettingsFile,
    IESGurdChannelFileTypeSettingsData
};

typedef NS_ENUM(NSInteger, IESGurdRequestChannelConfigStatus) {
    IESGurdRequestChannelConfigStatusNotFound,      //未找到channel包
    IESGurdRequestChannelConfigStatusNewVersion,    //找到channel包，需要下载
    IESGurdRequestChannelConfigStatusLatestVersion  //找到channel包，已经是最新版本
};

typedef NS_ENUM(NSInteger, IESGurdCleanCachePolicy) {
    IESGurdCleanCachePolicyNone,
    IESGurdCleanCachePolicyFIFO,
    IESGurdCleanCachePolicyLRU
};

@class IESGurdResourceModel;

typedef void(^IESResourceConfigResponse)(IESGurdSyncStatus status, NSArray<IESGurdResourceModel *> *_Nullable recordList);

typedef NS_ENUM(NSInteger, IESGurdStatsType)
{
    IESGurdStatsTypeCleanCacheSucceed = 200, // 资源清理成功
    IESGurdStatsTypeCleanCacheFail = 201, // 资源清理失败
    IESGurdStatsTypeCleanExpiredCacheSucceed = 202, // 资源过期清理成功
    IESGurdStatsTypeCleanExpiredCacheFail = 203, // 资源清理过期失败
};

typedef NS_ENUM(NSInteger, IESGurdDownloadContinuationType)
{
    // 正常下载
    IESGurdDownloadContinuationTypeNormal = 0,
    // 基于断点的续传下载
    IESGurdDownloadContinuationTypeContinuation = 1
};

typedef NS_ENUM(NSInteger, IESGurdDownloadType)
{
    // 原有下载方式
    IESGurdDownloadTypeOriginal = 0,
    // 接入 TTDownloader 的下载方式
    IESGurdDownloadTypeTTDownloader = 1
};

typedef NS_ENUM(NSInteger, IESGurdPackagesConfigRequestType) {
    IESGurdPackagesConfigRequestTypeNormal = 1,
    IESGurdPackagesConfigRequestTypeRetry = 2,
    IESGurdPackagesConfigRequestTypePolling = 3,
    IESGurdPackagesConfigRequestTypeByteSync = 4,
    IESGurdPackagesConfigRequestTypeLazy = 5,
    IESGurdPackagesConfigRequestTypeQueue = 6
};

typedef NS_ENUM(NSInteger, IESGurdPollingPriority) {
    IESGurdPollingPriorityNone,
    // High priority
    IESGurdPollingPriorityLevel1,
    // Normal priority
    IESGurdPollingPriorityLevel2,
    // Low priority
    IESGurdPollingPriorityLevel3
};

typedef NS_ENUM(NSInteger, IESGurdDownloadPriority) {
    IESGurdDownloadPriorityLow,
    IESGurdDownloadPriorityMedium,
    IESGurdDownloadPriorityHigh,
    IESGurdDownloadPriorityUserInteraction
};

typedef NS_ENUM(NSInteger, IESGurdDataAccessPolicy) {
    // 只读取平台下发资源
    IESGurdDataAccessPolicyNormal,
    // 优先读取平台下发资源，内置包作为备份读取
    IESGurdDataAccessPolicyInternalPackageBackup,
    // 优先读取内置包
    IESGurdDataAccessPolicyInternalPackageFirst
};

typedef NS_ENUM(NSInteger, IESGurdSettingsPipelineType) {
    IESGurdSettingsPipelineTypeGurd = 1,
    IESGurdSettingsPipelineTypeCDN,
    IESGurdSettingsPipelineTypeBuiltin,
};

typedef NS_ENUM(NSInteger, IESGurdSettingsPipelineUpdatePolicy) {
    // 不更新
    IESGurdSettingsPipelineUpdatePolicyNone,
    // 触发更新
    IESGurdSettingsPipelineUpdatePolicyNormal,
    // 插队更新
    IESGurdSettingsPipelineUpdatePolicyHighPriority,
};

typedef NS_ENUM(NSInteger, IESGurdLogLevel) {
    IESGurdLogLevelInfo,
    IESGurdLogLevelWarning,
    IESGurdLogLevelError
};

typedef NS_ENUM(NSInteger, IESGurdEnvType) {
    IESGurdEnvTypeTest = 1,
    IESGurdEnvTypeOnline = 2
};

typedef NS_ENUM(NSInteger, IESGurdSettingsStatus) {
    IESGurdSettingsStatusNoUpdate = 0,
    IESGurdSettingsStatusDidUpdate = 1,
    IESGurdSettingsStatusUnavailable = 2
};

// 资源下载方式
// 0-正常下载；1-命中lazy下载，针对业务sync按需加载场景；2-命中lazy不下载，针对settings queue里的请求场景
typedef NS_ENUM(NSInteger, IESGurdPackageModelActivePolicy) {
    IESGurdPackageModelActivePolicyNormal = 0,
    IESGurdPackageModelActivePolicyMatchLazy = 1,
    IESGurdPackageModelActivePolicyFilterLazy = 2
};

typedef NS_ENUM(NSInteger, IESGurdSettingsRequestType) {
    IESGurdSettingsRequestTypeNormal = 1,
    IESGurdSettingsRequestTypeRetry = 2,
    IESGurdSettingsRequestTypePolling = 3
};

#define IESGeckoSyncStatusDict IESGurdSyncStatusDict
/**
 * 对于每个app，所有channel更新的status。
 *
 * Key：channel名称；Value：IESGurdSyncStatus
 */
typedef NSDictionary<NSString *, NSNumber *> *IESGurdSyncStatusDict;

@class IESGurdFetchResourcesParams;
typedef void(^IESGurdFetchResourcesParamsBlock)(IESGurdFetchResourcesParams *params);

typedef void(^IESGurdSyncStatusBlock)(BOOL succeed, IESGurdSyncStatus status);
typedef void(^IESGurdSyncStatusDictionaryBlock)(BOOL succeed, IESGurdSyncStatusDict dict);
typedef void(^IESGurdSyncAccessKeyStatusDictionaryBlock)(BOOL succeed, IESGurdSyncStatusDict dict, NSString *accessKey);

typedef void(^IESGurdAccessResourceCompletion)(NSData * _Nullable data);
typedef void(^IESGurdLoadResourceCompletion)(NSData * _Nullable data, IESGurdSyncStatus status);

typedef void(^IESGurdDownloadResourceCompletion)(NSURL * _Nullable pathURL, NSDictionary *downloadInfo, NSError * _Nullable error);

/**
 * IESGurdSyncStatusDict中，代表整个business的channel
 */
__unused static NSString * const IESGurdChannelPlaceHolder = @"__channel_ph__";

/**
 * IESGurdMakePlaceHolder
 */
__unused static inline IESGurdSyncStatusDict IESGurdMakePlaceHolder(IESGurdSyncStatus status)
{
    return @{ IESGurdChannelPlaceHolder : @(status) };
}

/**
 * IESGurdStatusForChannel
 */
__unused static inline IESGurdSyncStatus IESGurdStatusForChannel(IESGurdSyncStatusDict _Nonnull dict, NSString * _Nonnull channel)
{
    NSNumber *statusNumber = [dict objectForKey:channel];
    if (statusNumber != nil) {
        return (IESGurdSyncStatus)statusNumber.integerValue;
    }
    return (IESGurdSyncStatus)[[dict objectForKey:IESGurdChannelPlaceHolder] integerValue];
}

/**
 * IESGurdStatusForBusiness
 */
__unused static inline IESGurdSyncStatus IESGurdStatusForBusiness(IESGurdSyncStatusDict _Nonnull dict)
{
    return IESGurdStatusForChannel(dict, IESGurdChannelPlaceHolder);
}

__unused static NSDateFormatter *IESGurdDateFormatter (NSString *dateFormat)
{
    if (dateFormat.length == 0) {
        return nil;
    }
    
    static NSMutableDictionary<NSString *, NSDateFormatter *> *dateFormatterDictionary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatterDictionary = [NSMutableDictionary dictionary];
    });
    
    __block NSDateFormatter *dateFormatter = nil;
    @synchronized (dateFormatterDictionary) {
        dateFormatter = dateFormatterDictionary[dateFormat];
        if (!dateFormatter) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = dateFormat;
            dateFormatterDictionary[dateFormat] = dateFormatter;
        }
    }
    return dateFormatter;
}

__unused static NSDateFormatter *IESGurdNormalDateFormatter (void)
{
    return IESGurdDateFormatter(@"yyyy-MM-dd HH:mm:ss");
}

#define IESGurdKitDidRegisterAccessKeyNotification @"IESGurdKitDidRegisterAccessKeyNotification"

#define IESGurdKitDidSetEnableGurdNotification @"IESGurdKitDidSetEnableGurdNotification"
#define IESGurdKitDidSetupGurdNotification @"IESGurdKitDidSetupGurdNotification"

#define IESGurdSettingsDidFetchNotification @"IESGurdSettingsDidFetchNotification"
#define IESGurdSettingsFetchStatusKey @"status"
#define IESGurdSettingsFetchResponseKey @"response"

#ifndef dispatch_queue_async_safe
#define dispatch_queue_async_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
    block();\
} else {\
    dispatch_async(queue, block);\
}
#endif

#ifndef dispatch_queue_sync_safe
#define dispatch_queue_sync_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
block();\
} else {\
dispatch_sync(queue, block);\
}
#endif

NS_ASSUME_NONNULL_END

#endif /* IESGurdDefines_h */
