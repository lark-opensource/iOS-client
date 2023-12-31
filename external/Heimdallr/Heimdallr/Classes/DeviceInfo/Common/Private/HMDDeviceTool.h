//
//  HMDDeviceTool.h
//  Heimdallr
//
//  Created by joy on 2018/4/27.
//

#include <stdio.h>
#include <stdbool.h>
#include <mach/mach.h>
#import "HMDPublicMacro.h"

HMD_EXTERN_SCOPE_BEGIN

int32_t hmd_kssysctl_int32ForName(const char * _Nonnull const name);
int hmd_kssysctl_stringForName(const char * _Nonnull name, char * _Nullable value, int maxSize);
char * _Nullable hmd_system_cpu_arch(void);
char * _Nullable hmd_cpu_arch(cpu_type_t majorCode, cpu_subtype_t minorCode, bool need_strdup);

HMD_EXTERN_SCOPE_END
