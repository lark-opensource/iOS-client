//
//  BDPLLogMonitorManager.h
//  LarkMonitor
//
//  Created by ByteDance on 2023/4/24.
//

#import <Foundation/Foundation.h>
#import "BDPLLogMonitorConfig.h"
#import "BDPLLogMonitor.h"
#import "BDPowerLogDataListener.h"
NS_ASSUME_NONNULL_BEGIN

@interface BDPLLogMonitorManager : NSObject<BDPowerLogDataListener>

@property(nonatomic, weak) id<BDPLLogMonitorDelegate> delegate;

+ (instancetype)sharedManager;

+ (BDPLLogMonitor *)monitorWithType:(NSString *)type config:(BDPLLogMonitorConfig *)config;

+ (NSArray<BDPLLogMonitor *> *)allLogMonitors;

@end

NS_ASSUME_NONNULL_END
