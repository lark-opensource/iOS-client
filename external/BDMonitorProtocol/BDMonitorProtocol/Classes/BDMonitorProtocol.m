//
//  BDMonitorProtocol.m
//  BDAlogProtocol
//
//  Created by 李琢鹏 on 2019/3/11.
//

#import "BDMonitorProtocol.h"
#if __has_include(<Heimdallr/HMDTTMonitor.h>)
#define BDMonitorEnabled 1
#include <Heimdallr/HMDTTMonitor.h>
#endif


@implementation BDMonitorProtocol

+ (void)hmdTrackService:(NSString *)serviceName metric:(NSDictionary<NSString *,NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue {
#if BDMonitorEnabled
    [[HMDTTMonitor defaultManager] hmdTrackService:serviceName metric:metric category:category extra:extraValue];
#endif
}

+ (void)hmdTrackData:(NSDictionary *)data logType:(NSString *)logType {
#if BDMonitorEnabled
        [[HMDTTMonitor defaultManager] hmdTrackData:data logTypeStr:logType];
#endif
}

@end
