//
//  HMDMonitorService.m
//  Heimdallr
//
//  Created by Nickyo on 2023/6/14.
//

#import "HMDMonitorService.h"
#if RANGERSAPM
#import "RangersAPMMonitorServiceIMP.h"
#endif

@implementation HMDMonitorService

+ (void)trackService:(NSString *)serviceName metrics:(NSDictionary<NSString *,NSNumber *> *)metrics dimension:(NSDictionary<NSString *,NSString *> *)dimension extra:(NSDictionary *)extra {
    [[self service] trackService:serviceName metrics:metrics dimension:dimension extra:extra];
}

+ (void)trackService:(NSString *)serviceName metrics:(NSDictionary<NSString *,NSNumber *> *)metrics dimension:(NSDictionary<NSString *,NSString *> *)dimension extra:(NSDictionary *)extra syncWrite:(BOOL)sync {
    [[self service] trackService:serviceName metrics:metrics dimension:dimension extra:extra syncWrite:sync];
}

+ (Class<HMDMonitorServiceProtocol>)service {
#if RANGERSAPM
    return [RangersAPMMonitorServiceIMP class];
#else
    return NSClassFromString(@"HMDTTMonitor");
#endif
}

@end
