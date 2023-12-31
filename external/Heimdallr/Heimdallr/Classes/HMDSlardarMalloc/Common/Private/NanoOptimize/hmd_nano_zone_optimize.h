//
//  hmd_nano_zone_optimize.h
//  Heimdallr
//
//  Created by zhouyang11 on 2023/10/25.
//

#ifndef hmd_nano_zone_optimize_h
#define hmd_nano_zone_optimize_h

#include <stdio.h>
#import "HMDSlardarMallocOptimizeConfig.h"

#ifdef __cplusplus
extern "C" {
#endif

HMDNanoOptimizeResult hmd_nano_zone_optimize_invoke(hmd_nanozone_optimize_config config, uint64_t* duration);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* hmd_nano_zone_optimize_h */
