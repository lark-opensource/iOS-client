//
//  HMDInjectedInfo+UniqueKey.m
//  AFgzipRequestSerializer
//
//  Created by fengyadong on 2019/7/1.
//

#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDMacro.h"
#import "NSDictionary+HMDSafe.h"

@implementation HMDInjectedInfo (UniqueKey)

- (void)confUniqueKeyForData:(NSMutableDictionary *)data timestamp:(long long)timestamp eventType:(NSString *)eventType {
    [self confUniqueKeyForData:data timestamp:timestamp eventType:eventType appID:self.appID];
}

- (void)confUniqueKeyForData:(NSMutableDictionary *)data timestamp:(long long)timestamp eventType:(NSString *)eventType appID:(NSString *)appID {
    //ignore invalid parameters
    if (HMDIsEmptyDictionary(data) ||
        HMDIsEmptyString(self.appID) ||
        HMDIsEmptyString(self.deviceID) ||
        HMDIsEmptyString(eventType)) {
        return;
    }
    
    //unique key for preventing duplication format:aid_deviceid_crashtime_eventtype
    NSString *uniqueKey = [NSString stringWithFormat:@"%@_%@_%lld_%@", appID, self.deviceID, timestamp, eventType];
    [data hmd_setObject:uniqueKey forKey:@"unique_key"];
}

@end
