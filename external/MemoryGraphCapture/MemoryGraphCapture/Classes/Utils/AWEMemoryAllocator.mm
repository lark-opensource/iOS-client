//
//  AWEMemoryAllocator.cpp
//  MemoryGraphDemo
//
//  Created by brent.shu on 2019/10/28.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#import "AWEMemoryAllocator.hpp"

namespace MemoryGraph {

static malloc_zone_t *g_m_z;

malloc_zone_t * g_malloc_zone() {
    if (!g_m_z) {
        g_m_z = malloc_create_zone(0, 0);
    }
    return g_m_z;
}

void g_malloc_zone_destory() {
    if (g_m_z) {
        malloc_destroy_zone(g_m_z);
        g_m_z = nullptr;
    }
}

void *zone_malloc(CFIndex allocSize, CFOptionFlags hint, void *info) {
    return malloc_zone_malloc(g_malloc_zone(), allocSize);
}

void * zone_relloac(void *ptr, CFIndex newsize, CFOptionFlags hint, void *info) {
    return malloc_zone_realloc(g_malloc_zone(), ptr, newsize);
}

void zone_free(void *ptr, void *info) {
    malloc_zone_free(g_malloc_zone(), ptr);
}

CFIndex zone_preferred_size(CFIndex size, CFOptionFlags hint, void *info) {
    return malloc_good_size(size);
}

static CFAllocatorContext zone_malloc_context = {
    .version = 0,
    .info = NULL,
    .retain = NULL,
    .release = NULL,
    .copyDescription = NULL,
    .allocate = zone_malloc,
    .reallocate = zone_relloac,
    .deallocate = zone_free,
    .preferredSize = zone_preferred_size,
};

CFAllocatorRef g_zone_allocator() {
    static CFAllocatorRef allocator = NULL;
    if (!allocator) {
        allocator = CFAllocatorCreate(kCFAllocatorDefault, &zone_malloc_context);
    }
    return allocator;
}

} // MemoryGraph
