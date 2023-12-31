//
//  HMDDeviceTool.m
//  Heimdallr
//
//  Created by joy on 2018/4/27.
//

#import "HMDDeviceTool.h"
#import "HMDCompactUnwind.hpp"
#include <sys/sysctl.h>

int32_t hmd_kssysctl_int32ForName(const char* const name)
{
    int32_t value = 0;
    size_t size = sizeof(value);
    
    HMDCHECK_SYSCTL_NAME(int32, sysctlbyname(name, &value, &size, NULL, 0));
    
    return value;
}

int hmd_kssysctl_stringForName(const char* const  name,
                           char* const value,
                           const int maxSize)
{
    size_t size = value == NULL ? 0 : (size_t)maxSize;
    
    HMDCHECK_SYSCTL_NAME(string, sysctlbyname(name, value, &size, NULL, 0));
    
    return (int)size;
}

uint32_t hmd_device_image_index_named(const char* const image_name, bool exact_match)
{
    __block uint32_t index = UINT32_MAX;
    if (image_name != NULL) {
        hmd_enumerate_image_list_using_block(^(hmd_async_image_t *image, int i, bool *stop) {
            const char* name = image->macho_image.name;
            if (name) {
                if (exact_match) {
                    if(strcmp(name, image_name) == 0) {
                        index = i;
                        *stop = true;
                    }
                }
                else {
                    if (strstr(name, image_name) != NULL) {
                        index = i;
                        *stop = true;
                    }
                }
            }
        });
    }
    return index;
}
