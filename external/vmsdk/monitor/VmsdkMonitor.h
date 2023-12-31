//
//  VmsdkMonitor.h
//  Playground
//
//  Created by bytedance on 2021/11/15.
//

#import "MonitorInfo.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"
#import <Heimdallr/HMDInjectedInfo.h>
#import <Heimdallr/HMDTTMonitor.h>
#pragma clang diagnostic pop

@interface VmsdkMonitor : NSObject
/**
 Singleton method
 @return return VmsdkMonitor initialized only by vmsdk's appID
 */
+ (instancetype)sharedOnlyAppID;

/**
 Singleton method
 @return return VmsdkMonitor initialized by MonitorInfo
 */
+ (instancetype)sharedMonitorInfo:(MonitorInfo*)info;

+ (HMDTTMonitor*)getMonitor;

/**
 event reporting api
 */
- (void)monitorEvent:(NSString*)serviceName
              metric:(NSDictionary*)metric
            category:(NSDictionary*)category
               extra:(NSDictionary*)extra;

+ (void)monitorEventStatic:(NSString*)serviceName
                    metric:(NSDictionary*)metric
                  category:(NSDictionary*)category
                     extra:(NSDictionary*)extra;
@end
