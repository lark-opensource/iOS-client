//
//  HMDDeviceImageTool.h
//  Pods
//
//  Created by Nickyo on 2023/10/7.
//

#ifndef HMDDeviceImageTool_h
#define HMDDeviceImageTool_h

#include <stdio.h>
#include <stdbool.h>
#import "HMDPublicMacro.h"

HMD_EXTERN_SCOPE_BEGIN

uint32_t hmd_device_image_index_named(const char * _Nonnull const image_name, bool exact_match);

HMD_EXTERN_SCOPE_END

#endif /* HMDDeviceImageTool_h */
