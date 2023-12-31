//
//  BDAutoTrackDevEventData.m
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 2022/10/27.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackDevEventData.h"

@implementation BDAutoTrackDevEventData

- (instancetype)init {
    self = [super init];
    if (self) {
        self.statusList = [[NSMutableArray alloc] initWithCapacity:4];
        self.statusStrList = [[NSMutableArray alloc] initWithCapacity:4];
    }
    return self;
}

- (void)addStatus:(BDAutoTrackEventStatus)status {
    [self.statusList addObject:@(status)];
    [self.statusStrList addObject:[BDAutoTrackDevEventData status2String:status]];
}

- (void)setType:(BDAutoTrackEventAllType)type {
    _type = type;
    self.typeStr = [BDAutoTrackDevEventData type2String:type];
//    NSLog(@"label >>> %@", self.typeStr);
}

- (void)setProperties:(NSDictionary *)properties {
    _properties = properties;
    
    NSError *error;
    NSData *json = [NSJSONSerialization dataWithJSONObject:properties options:NSJSONWritingPrettyPrinted error:&error];
    if (json) {
        self.propertiesJson = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    } else {
        self.propertiesJson = error.localizedDescription;
    }
    
    static NSDateFormatter* dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    });
    
    id timestamp = [properties objectForKey:@"local_time_ms"];
    if (timestamp) {
        self.timestamp = [timestamp longValue];
        self.timeStr = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.timestamp / 1000]];
    } else {
        self.timestamp = 0;
        self.timeStr = @"";
    }
}

+ (NSString *)status2String:(BDAutoTrackEventStatus) status {
    switch (status) {
        case BDAutoTrackEventStatusCreated:
            return @"已采集";
            
        case BDAutoTrackEventStatusSaved:
            return @"已落库";
            
        case BDAutoTrackEventStatusReported:
            return @"已上报";
            
        case BDAutoTrackEventStatusSaveFailed:
            return @"落库失败";
        
        default:
            return @"未知状态";
    }
}

+ (NSString *)type2String:(BDAutoTrackEventAllType) type {
    switch (type) {
        case BDAutoTrackEventAllTypeLaunch:
            return @"Launch";
        
        case BDAutoTrackEventAllTypeTerminate:
            return @"Terminate";
        
        case BDAutoTrackEventAllTypeProfile:
            return @"Profile";
        
        case BDAutoTrackEventAllTypeEventV3:
            return @"EventV3";
        
        case BDAutoTrackEventAllTypeUIEvent:
            return @"UITracker";
            
        default:
            return @"Unknown";
    }
}

+ (BOOL)hasStatus:(BDAutoTrackEventStatus) status {
    return status == BDAutoTrackEventStatusCreated ||
        status == BDAutoTrackEventStatusSaved ||
        status == BDAutoTrackEventStatusReported ||
        status == BDAutoTrackEventStatusSaveFailed;
}

+ (BOOL)hasType:(BDAutoTrackEventAllType) type {
    return type == BDAutoTrackEventAllTypeLaunch ||
        type == BDAutoTrackEventAllTypeTerminate ||
        type == BDAutoTrackEventAllTypeProfile ||
        type == BDAutoTrackEventAllTypeEventV3 ||
        type == BDAutoTrackEventAllTypeUIEvent;
}

@end
