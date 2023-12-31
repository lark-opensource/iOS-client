//
//  HMDServiceContext.m
//  Heimdallr
//
//  Created by bytedance on 2022/10/27.
//

#import "HMDServiceContext.h"
#import "HMDDynamicCall.h"
#import "HMDEvilMethodServiceProtocol.h"
#import "HMDFrameDropServiceProtocol.h"


#define getServiceInstance(module, shared, protocolName) \
({\
static dispatch_once_t onceToken;\
static id<protocolName> instance = nil;\
dispatch_once(&onceToken, ^{\
__kindof NSObject *maybeInstance = DC_CL(module, shared);\
if([maybeInstance conformsToProtocol:@protocol(protocolName)]) {\
instance = maybeInstance;\
};\
});\
instance;\
})\

id<HMDTTMonitorServiceProtocol> hmd_get_heimdallr_ttmonitor(void) {
    return getServiceInstance(HMDTTMonitor, heimdallrTTMonitor, HMDTTMonitorServiceProtocol);
}

id<HMDTTMonitorServiceProtocol> hmd_get_app_ttmonitor(void) {
    return getServiceInstance(HMDTTMonitor, defaultManager, HMDTTMonitorServiceProtocol);
}

id<HMDEvilMethodServiceProtocol> hmd_get_evilmethod_tracer(void) {
    return getServiceInstance(HMDEvilMethodTracer, sharedInstance, HMDEvilMethodServiceProtocol);
}

id<HMDFrameDropServiceProtocol> hmd_get_framedrop_monitor(void) {
    return getServiceInstance(HMDFrameDropMonitor, sharedMonitor, HMDFrameDropServiceProtocol);
}
