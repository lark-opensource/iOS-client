//
//  PNSMonitorImpl.m
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/20.
//

#import "PNSMonitorImpl.h"
#import "PNSServiceCenter+private.h"
#import <Heimdallr/HMDTTMonitor.h>

PNS_BIND_DEFAULT_SERVICE(PNSMonitorImpl, PNSMonitorProtocol)

@implementation PNSMonitorImpl

- (void)trackService:(NSString *)serviceName
              metric:(NSDictionary *)metric
            category:(NSDictionary *)category
          attributes:(NSDictionary *)attributes {
    [[HMDTTMonitor defaultManager] hmdTrackService:serviceName
                                            metric:metric
                                          category:category
                                             extra:attributes];
}

- (void)trackLogType:(NSString *)logTypeName
            category:(NSDictionary *)category {
    [[HMDTTMonitor defaultManager] hmdTrackData:category logTypeStr:logTypeName];
}

@end
