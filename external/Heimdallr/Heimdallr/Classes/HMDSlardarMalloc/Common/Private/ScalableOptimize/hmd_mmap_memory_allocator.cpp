//
//  hmd_mmap_memory_allocator.c
//  Heimdallr
//
//  Created by zhouyang11 on 2023/7/20.
//

#include "hmd_mmap_memory_allocator.hpp"

namespace HMDMMapAllocator {
    
    static malloc_zone_t *g_m_z;
    
    malloc_zone_t * g_malloc_zone() {
        if (!g_m_z) {
            g_m_z = malloc_create_zone(0, 0);
            malloc_set_zone_name(g_m_z, "hmd_mmap_allocator_internal_zone");
//            malloc_zone_unregister(g_m_z);
        }
        return g_m_z;
    }
    
    void g_malloc_zone_destory() {
        if (g_m_z) {
            malloc_destroy_zone(g_m_z);
            g_m_z = nullptr;
        }
    }
}
