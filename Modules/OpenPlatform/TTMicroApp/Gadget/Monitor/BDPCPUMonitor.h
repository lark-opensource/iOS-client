//
//  BDPCPUMonitor.h
//  Timor
//
//  Created by MacPu on 2018/10/18.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUniqueID.h>

NS_ASSUME_NONNULL_BEGIN

/// cpu 的监控
@interface BDPCPUMonitor : NSObject

+ (float)cpuUsage;

+ (float)cpuUsageForUniqueID:(BDPUniqueID *)uniqueID;
@end

NS_ASSUME_NONNULL_END
