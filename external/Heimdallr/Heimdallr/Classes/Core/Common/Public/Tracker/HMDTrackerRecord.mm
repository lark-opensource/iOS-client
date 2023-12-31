//
//  HMDTrackerRecord.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDTrackerRecord.h"
#import "HMDSessionTracker.h"
#import "HMDInfo+AppInfo.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDApplicationSession.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDNetworkHelper.h"

@interface HMDTrackerRecord()<HMDRecordStoreObject>
@end

@implementation HMDTrackerRecord

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

+ (instancetype)newRecord
{
    HMDTrackerRecord *record = [[self alloc] init];
    record.timestamp = [[NSDate date] timeIntervalSince1970];
    record.sessionID = [HMDSessionTracker currentSession].sessionID;
    record.inAppTime = [HMDSessionTracker currentSession].timeInSession;
    record.osVersion = [HMDInfo defaultInfo].systemVersion;
    record.appVersion = [HMDInfo defaultInfo].shortVersion;
    record.buildVersion = [HMDInfo defaultInfo].buildVersion;
    record.sdkVersion = [HMDInfo defaultInfo].sdkVersion;
    record.netQualityType = [HMDNetworkHelper currentNetQuality];

    return record;
}

+ (NSString *)tableName {
    return NSStringFromClass(self);
}

+ (NSUInteger)cleanupWeight {
    return 15;
}

- (NSDictionary *)environmentInfo {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict hmd_setSafeObject:self.appVersion forKey:@"app_version"];
    [dict hmd_setSafeObject:self.buildVersion forKey:@"update_version_code"];
    [dict hmd_setSafeObject:self.osVersion forKey:@"os_version"];
    [dict hmd_setSafeObject:self.sdkVersion forKey:@"heimdallr_version"];
    [dict hmd_setSafeObject:@(self.netQualityType) forKey:@"network_quality"];
    return [dict copy];
}

- (void)recoverWithSessionRecord:(HMDApplicationSession *)sessionRecord {
    self.appVersion = sessionRecord.appVersion;
    self.buildVersion = sessionRecord.buildVersion;
    self.sdkVersion = sessionRecord.sdkVersion;
    self.osVersion = sessionRecord.osVersion;
}

- (NSDictionary *)reportDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict hmd_setSafeObject:self.appVersion forKey:@"app_version"];
    [dict hmd_setSafeObject:self.buildVersion forKey:@"update_version_code"];
    [dict hmd_setSafeObject:self.osVersion forKey:@"os_version"];
    [dict hmd_setSafeObject:self.sdkVersion forKey:@"heimdallr_version"];
    [dict hmd_setSafeObject:@(self.netQualityType) forKey:@"network_quality"];
    [dict hmd_setSafeObject:@(self.timestamp) forKey:@"timestamp"];
    [dict hmd_setSafeObject:self.sessionID forKey:@"session_id"];
    [dict hmd_setSafeObject:@(self.inAppTime) forKey:@"in_app_time"];
    [dict hmd_setObject:@(self.enableUpload) forKey:@"enable_upload"];
    return [dict copy];
}
@end
