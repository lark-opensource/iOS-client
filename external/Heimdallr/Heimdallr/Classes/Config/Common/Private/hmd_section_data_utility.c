//
//  hmd_section_data_utility.c
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/14.
//

#include "hmd_section_data_utility.h"
#include <mach-o/getsect.h>
#include <mach-o/dyld.h>
#include <stdatomic.h>

static atomic_uintptr_t latest_mach_header;

char const ** hmd_get_sectiondata_with_header(mach_header_t *header, char *section_name, unsigned long *count) {
    unsigned long size = 0;
    uintptr_t *memory = (uintptr_t*)getsectiondata(header, SEG_DATA, section_name, &size);
    if (size > 0) {
    #if __has_feature(address_sanitizer)
        // 无法直接转为struct __asan_global，否则会触发ASan的crash
        *count = size/sizeof(struct __asan_global_var);
    #else
        *count = size/sizeof(void *);
    #endif
        return (char const **)memory;
    }
    
    return NULL;
}

char const ** hmd_get_sectiondata_with_name(char *section_name, unsigned long *count) {
    const uint32_t image_count = _dyld_image_count();
    mach_header_t *header = 0;
    
    if ((header = (mach_header_t *)atomic_load_explicit(&latest_mach_header, memory_order_acquire)) != 0) {
        char const **result = hmd_get_sectiondata_with_header(header, section_name, count);
        if (result) {
            return result;
        }
    }
    
    for(uint32_t i = 0; i < image_count; i++)
    {
        header = (mach_header_t *)_dyld_get_image_header(i);
        char const **result = hmd_get_sectiondata_with_header(header, section_name, count);
        if (result) {
            atomic_store_explicit(&latest_mach_header, (uintptr_t)header, memory_order_release);
            return result;
        }
    }
    return NULL;
}
