//
//  IESGurdAppLogger.h
//  IESGurdKit
//
//  Created by li keliang on 2019/3/13.
//

#import <Foundation/Foundation.h>
#import "IESGeckoDefines.h"
#import "IESGurdProtocolDefines.h"

typedef NS_ENUM(NSInteger, IESGurdAppLogEventType) {
    IESGurdAppLogEventTypeDownload = 100,
    IESGurdAppLogEventTypeActive = 200,
    IESGurdAppLogEventTypeClearCache = 300,
    IESGurdAppLogEventTypeMetadata = 600,
    IESGurdAppLogEventTypeSettings = 1000,
    IESGurdAppLogEventTypeExtra = 1100,
    
    IESGurdAppLogEventTypeOnDemand = 7,
};

typedef NS_ENUM(NSInteger, IESGurdAppLogEventSubtype) {
    // download
    IESGurdAppLogEventSubtypeNoNeedToDownload = 101,
    IESGurdAppLogEventSubtypeCancelDownload = 102,
    // clearCache
    IESGurdAppLogEventSubtypeBlocklistValidateFailed = 301,
    IESGurdAppLogEventSubtypeLastReadTimestampError = 302,
    IESGurdAppLogEventSubtypeBlocklistDownloadException = 303,
    // metadata
    IESGurdAppLogEventSubtypeMetadataLoad = 601,
    IESGurdAppLogEventSubtypeMetadataInternalError = 602,
    IESGurdAppLogEventSubtypeMetadataWriteFailed = 603,
    IESGurdAppLogEventSubtypeMetadataDuplicated = 697,
    IESGurdAppLogEventSubtypeMetadataUnarchived = 698,
    IESGurdAppLogEventSubtypeMetadataMigrate = 699,
    // settings
    IESGurdAppLogEventSubtypeSettingsVersion = 1001,
    // extra
    IESGurdAppLogEventSubtypeReadExtraError = 1101,
    IESGurdAppLogEventSubtypeWriteExtraError = 1102,
    
    // ondemand
    IESGurdAppLogEventSubtypeOnDemandNoCache = 701,
};

NS_ASSUME_NONNULL_BEGIN

@class IESGurdMultiAccessKeysRequest;

@interface IESGurdAppLogger : NSObject

@property (class, nonatomic, strong) id<IESGurdAppLogDelegate> appLogDelegate;

// 最新一次的query_pkg请求的logid，会随着update和query_pkg的埋点上报，用于排查问题
@property (class, nonatomic, copy) NSString *lastestQueryPkgsLogid;

+ (void)recordCleanStats:(IESGurdStatsType)type
               accessKey:(NSString *)accessKey
                 channel:(NSString *)channel
               packageID:(uint64_t)packageID
                   extra:(nullable NSDictionary *)extra;
+ (void)recordUpdateStats:(nullable NSDictionary *)extra;
+ (void)recordQueryPkgsStats:(NSDictionary *)extra;

+ (void)recordStatsWithSyncStatusType:(NSInteger)syncStatusType
                               taskId:(NSInteger)taskId
                             taskType:(NSInteger)taskType;

+ (void)recordEventWithType:(IESGurdAppLogEventType)eventType
                    subtype:(IESGurdAppLogEventSubtype)subtype
                     params:(nullable NSDictionary *)params
                  extraInfo:(nullable NSString *)extraInfo
               errorMessage:(nullable NSString *)errorMessage;

+ (void)recordEventWithType:(IESGurdAppLogEventType)eventType
                    subtype:(IESGurdAppLogEventSubtype)subtype
                     params:(nullable NSDictionary *)params
                  extraInfo:(nullable NSString *)extraInfo
               errorMessage:(nullable NSString *)errorMessage
                  accessKey:(nullable NSString *)accessKey
                   channels:(nullable NSString *)channels;

+ (void)recordQuerySettingsWithResponse:(IESGurdNetworkResponse *)networkResponse;

+ (void)recordResourceInfoWithAccessKey:(NSString *)accessKey
                 accessKeyResourceUsage:(NSInteger)accessKeyResourceUsage
                           channelCount:(int)channelCount
                geckoTotalResourceUsage:(NSInteger)geckoTotalResourceUsage;

@end

NS_ASSUME_NONNULL_END
