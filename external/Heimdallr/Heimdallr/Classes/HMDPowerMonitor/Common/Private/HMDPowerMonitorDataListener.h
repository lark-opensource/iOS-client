//
//  BDPowerLogDataListener.h
//  LarkMonitor
//
//  Created by ByteDance on 2023/4/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//extern NSString *BDPowerLogDataType_app_state;

#define DEFINE_EXTERN_KEY(name) extern NSString *BDPowerLogDataType_##name;

DEFINE_EXTERN_KEY(cpu)
DEFINE_EXTERN_KEY(thermal_state)
DEFINE_EXTERN_KEY(power_mode)
DEFINE_EXTERN_KEY(battery_level)
DEFINE_EXTERN_KEY(battery_state)
DEFINE_EXTERN_KEY(brightness)
DEFINE_EXTERN_KEY(app_state)
DEFINE_EXTERN_KEY(scene)
DEFINE_EXTERN_KEY(memory)
DEFINE_EXTERN_KEY(io)
DEFINE_EXTERN_KEY(gpu)
DEFINE_EXTERN_KEY(net)
DEFINE_EXTERN_KEY(net_type)

@protocol HMDPowerMonitorDataListener <NSObject>

- (void)dataChanged:(NSString *)dataType data:(NSDictionary *)data init:(BOOL)init;

@end

NS_ASSUME_NONNULL_END
