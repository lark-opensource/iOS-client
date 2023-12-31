//
//  BDPMonitor.h
//  Timor
//
//  Created by MacPu on 2018/10/18.
//

#import <Foundation/Foundation.h>
#import "BDPMonitorProtocol.h"
#import <OPFoundation/BDPUniqueID.h>

NS_ASSUME_NONNULL_BEGIN

/// 小程序的性能监控
@interface BDPMonitor : NSObject <BDPMonitorProtocol>

@property (nonatomic, strong) BDPUniqueID *uniqueID;  // 应用的Id
@property (nonatomic, assign) BOOL isActive;   // 是否是活跃的

@end

NS_ASSUME_NONNULL_END
