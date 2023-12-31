//
//  HMDTTMonitorHelper.h
//  Heimdallr
//
//  Created by 崔晓兵 on 16/3/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HMDTTMonitorTrackerType);

@class HMDTTMonitorUserInfo;

@interface HMDTTMonitorHelper : NSObject

+ (NSString * _Nullable)logTypeStrForType:(HMDTTMonitorTrackerType)type;

+ (NSDictionary *)filterTrackerReservedKeysWithDataDict:(NSDictionary *)dataDict;

+ (NSString *)generateLogID;

+ (NSNumber *)generateUploadID;

+ (BOOL)checkDictionaryDataFormat:(NSDictionary *)data;

+ (BOOL)fastCheckDictionaryDataFormat:(NSDictionary *)data;

+ (BOOL)checkArrayDataFormat:(NSArray *)array;

+ (BOOL)fastCheckArrayDataFormat:(NSArray *)array;

+ (NSDictionary *)reportHeaderParamsWithInjectedInfo:(HMDTTMonitorUserInfo *)info;

+ (void)registerCrashCallbackToLog;

+ (void)saveLatestLogWithServiceName:(NSString *)serviceName logType:(NSString *)logType appID:(NSString *)appID;
@end

NS_ASSUME_NONNULL_END
