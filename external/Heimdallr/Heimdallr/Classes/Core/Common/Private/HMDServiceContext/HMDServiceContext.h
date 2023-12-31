//
//  HMDServiceContext.h
//  Heimdallr
//
//  Created by bytedance on 2022/10/27.
//

#import <Foundation/Foundation.h>
#include "HMDPublicMacro.h"
#import "HMDTTMonitorServiceProtocol.h"

@protocol HMDEvilMethodServiceProtocol;
@protocol HMDFrameDropServiceProtocol;

HMD_EXTERN id<HMDTTMonitorServiceProtocol> _Nullable hmd_get_heimdallr_ttmonitor(void);

HMD_EXTERN id<HMDTTMonitorServiceProtocol> _Nullable hmd_get_app_ttmonitor(void);

HMD_EXTERN id<HMDEvilMethodServiceProtocol> _Nullable hmd_get_evilmethod_tracer(void);

HMD_EXTERN id<HMDFrameDropServiceProtocol> _Nullable hmd_get_framedrop_monitor(void);
