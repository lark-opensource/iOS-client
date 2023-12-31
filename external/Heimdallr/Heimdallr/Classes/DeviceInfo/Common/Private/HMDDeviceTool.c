//
//  HMDDeviceTool.m
//  Heimdallr
//
//  Created by joy on 2018/4/27.
//

#import "HMDDeviceTool.h"
#include <sys/sysctl.h>
#include <dispatch/dispatch.h>

#define HMD_CHECK_SYSCTL_NAME(TYPE, CALL) if (0 != (CALL)) { return 0; }

/// [Fix] Xcode 9 Build 没有 define `CPU_SUBTYPE_ARM64E`
#define CPU_SUBTYPE_ARM64E              ((cpu_subtype_t) 2)

int32_t hmd_kssysctl_int32ForName(const char * const name) {
    int32_t value = 0;
    size_t size = sizeof(value);
    
    HMD_CHECK_SYSCTL_NAME(int32, sysctlbyname(name, &value, &size, NULL, 0));
    return value;
}

int hmd_kssysctl_stringForName(const char *name, char *value, int maxSize) {
    size_t size = value == NULL ? 0 : (size_t)maxSize;
    
    HMD_CHECK_SYSCTL_NAME(string, sysctlbyname(name, value, &size, NULL, 0));
    return (int)size;
}

char * hmd_system_cpu_arch(void) {
    cpu_type_t cpuType = hmd_kssysctl_int32ForName("hw.cputype");
    cpu_subtype_t cpuSubType = hmd_kssysctl_int32ForName("hw.cpusubtype");
    return hmd_cpu_arch(cpuType, cpuSubType, false);
}

char * hmd_cpu_arch(cpu_type_t majorCode, cpu_subtype_t minorCode, bool need_strdup) {
    char *result = NULL;
    minorCode = minorCode & ~CPU_SUBTYPE_MASK;
    
    switch (majorCode) {
        case CPU_TYPE_ARM: {
            switch (minorCode) {
                case CPU_SUBTYPE_ARM_V6:
                    result = "armv6";
                    break;
                case CPU_SUBTYPE_ARM_V7:
                    result = "armv7";
                    break;
                case CPU_SUBTYPE_ARM_V7F:
                    result = "armv7f";
                    break;
                case CPU_SUBTYPE_ARM_V7K:
                    result = "armv7k";
                    break;
#ifdef CPU_SUBTYPE_ARM_V7S
                case CPU_SUBTYPE_ARM_V7S:
                    result = "armv7s";
                    break;
#endif /* CPU_SUBTYPE_ARM_V7S */
                default:
                    result = "arm";
                    break;
            }
            break;
        }
#ifdef CPU_TYPE_ARM64
        case CPU_TYPE_ARM64: {
            switch (minorCode) {
#ifdef CPU_SUBTYPE_ARM64E
                case CPU_SUBTYPE_ARM64E:
                    result = "arm64e";
                    break;
#endif /* CPU_SUBTYPE_ARM64E */
#ifdef CPU_SUBTYPE_ARM64_ALL
                case CPU_SUBTYPE_ARM64_ALL:
                    result = "arm64";
                    break;
#endif /* CPU_SUBTYPE_ARM64_ALL */
#ifdef CPU_SUBTYPE_ARM64_V8
                case CPU_SUBTYPE_ARM64_V8:
                    result = "arm64v8";
                    break;
#endif /* CPU_SUBTYPE_ARM64_V8 */
                default:
                    result = "arm64";
                    break;
            }
            break;
        }
#endif /* CPU_TYPE_ARM64 */
        case CPU_TYPE_X86:
            result = "i386";
            break;
        case CPU_TYPE_X86_64:
            result = "x86_64";
            break;
        default:
            result = NULL;
            break;
    }
    
    if (result != NULL) {
        if (need_strdup) { return strdup(result); }
        return result;
    }
    
    if (!need_strdup) { return "unknown_arch"; }
    
    char *arch = (char *)calloc(100, sizeof(char));
    if (arch == NULL) { return NULL; }
    snprintf(arch, 100, "unknown(%d,%d)", majorCode, minorCode);
    return arch;
}
