//
//  HMDDeviceImageTool.c
//  Pods
//
//  Created by Nickyo on 2023/10/7.
//

#include "HMDDeviceImageTool.h"
#import "HMDCompactUnwind.hpp"

uint32_t hmd_device_image_index_named(const char * const image_name, bool exact_match) {
    __block uint32_t index = UINT32_MAX;
    if (image_name == NULL) {
        return index;
    }
    hmd_enumerate_image_list_using_block(^(hmd_async_image_t *image, int idx, bool *stop) {
        const char *name = image->macho_image.name;
        if (!name) { return; }
        if (exact_match) {
            if (strcmp(name, image_name) == 0) {
                index = idx;
                *stop = true;
            }
        } else {
            if (strstr(name, image_name) != NULL) {
                index = idx;
                *stop = true;
            }
        }
    });
    return index;
}
