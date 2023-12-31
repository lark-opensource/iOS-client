//
//  PNSMonitorProtocol.h
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/15.
//

#import "PNSServiceCenter.h"

#ifndef PNSMonitorProtocol_h
#define PNSMonitorProtocol_h

#define PNSMonitor PNS_GET_INSTANCE(PNSMonitorProtocol)

@protocol PNSMonitorProtocol <NSObject>

- (void)trackService:(NSString * _Nonnull)serviceName
              metric:(NSDictionary * _Nullable)metric
            category:(NSDictionary * _Nullable)category
          attributes:(NSDictionary * _Nullable)attributes;

- (void)trackLogType:(NSString * _Nonnull)logTypeName
            category:(NSDictionary * _Nullable)category;

@end

#endif /* PNSMonitorProtocol_h */
