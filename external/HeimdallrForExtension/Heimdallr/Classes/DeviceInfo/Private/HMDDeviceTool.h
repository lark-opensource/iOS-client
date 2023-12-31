//
//  HMDDeviceTool.h
//  Heimdallr
//
//  Created by joy on 2018/4/27.
//

#include <stdio.h>
#include <mach-o/nlist.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#include <mach/mach.h>

#define HMDCHECK_SYSCTL_NAME(TYPE, CALL) \
if(0 != (CALL)) \
{ \
return 0; \
}

int hmd_kssysctl_stringForName(const char* name, char* value, int maxSize);
int32_t hmd_kssysctl_int32ForName(const char* const name);
uint32_t hmd_device_image_index_named(const char* const image_name, bool exact_match);
