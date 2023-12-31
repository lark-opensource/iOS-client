//
//  hmd_runloop_define.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/3/30.
//

#ifndef hmd_runloop_define_h
#define hmd_runloop_define_h

#include <stdio.h>

/**
 * Runloop状态
 */
typedef NS_ENUM(NSUInteger, HMDRunloopStatus) {
    HMDRunloopStatusBegin = 0,
    HMDRunloopStatusDuration,
    HMDRunloopStatusOver,
};

#endif /* hmd_runloop_define_h */
