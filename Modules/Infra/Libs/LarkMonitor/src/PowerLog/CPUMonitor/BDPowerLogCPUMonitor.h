//
//  BDPowerLogCPUMonitor.h
//  Jato
//
//  Created by ByteDance on 2022/11/15.
//

#import <Foundation/Foundation.h>
#import "BDPowerLogCPUMetrics.h"
NS_ASSUME_NONNULL_BEGIN

@interface BDPowerLogCPUMonitor : NSObject

- (BDPowerLogCPUMetrics *_Nullable)collect;

@end

NS_ASSUME_NONNULL_END
