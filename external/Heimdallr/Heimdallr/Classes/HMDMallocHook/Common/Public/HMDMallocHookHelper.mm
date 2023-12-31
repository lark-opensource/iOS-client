//
//  HMDMallocHookHelper.cpp
//  Heimdallr-_Dummy
//
//  Created by zhouyang11 on 2021/12/3.
//

#include "HMDMallocHookHelper.h"
#include "HMDThreadSuspender.h"
#include <mutex>
#import "HMDMacro.h"
#import "HMDALogProtocol.h"

NSString *const kHMDSlardarMallocInuseNotification = @"kHMDSlardarMallocInuseNotification";

namespace {

struct MallocHookZoneWrapper {
    malloc_zone_t *zone;
    HMDMallocHookPriority priority;
    HMDMallocHookType type;
};

typedef MallocHookZoneWrapper Wrapper;
typedef std::pair<Wrapper*, size_t> SizePair;

Wrapper malloc_hook_wrappers[(int)HMDMallocHookPriorityHigh+1] = {0}; // record all malloc zones to be manipulated
malloc_zone_t* default_zone_ptr = nullptr;
malloc_zone_t* hmd_malloc_helper_zone_ptr = nullptr;
bool initialized = false;
std::mutex mutex;

SizePair
mz_size_verbose(const void* ptr) {
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr) {
            size_t size = wrapper.zone->size(wrapper.zone, ptr);
            if (size != 0) {
                return {&wrapper, size};
            }
        }
    }
    return {nullptr, 0};
}

size_t
mz_size(malloc_zone_t* zone, const void* ptr) {
    auto pair = mz_size_verbose(ptr);
    size_t ptr_size = pair.second;
    if (ptr_size == 0) {
        return default_zone_ptr->size(default_zone_ptr, ptr);
    }
    /*兼容gwpasan的代码先加回来，版本同步之后再删除*/
    if (pair.first->type == HMDMallocHookTypePartialReplace && (ptr_size & size_t(15)) != 0) {
        ptr_size = (ptr_size + size_t(15)) & ~size_t(15);
    }

    return ptr_size;
}

void*
mz_malloc(malloc_zone_t* zone, size_t size) {
    void *ptr = nullptr;
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr) {
            ptr = wrapper.zone->malloc(wrapper.zone, size);
            if (ptr != nullptr || wrapper.type == HMDMallocHookTypeReplace) {
                return ptr;
            }
        }
    }
    return default_zone_ptr->malloc(default_zone_ptr, size);
}

void*
mz_calloc(malloc_zone_t* zone, size_t num_items, size_t size) {
    void *ptr = nullptr;
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr) {
            ptr = wrapper.zone->calloc(wrapper.zone, num_items, size);
            if (ptr != nullptr || wrapper.type == HMDMallocHookTypeReplace) {
                return ptr;
            }
        }
    }
    return default_zone_ptr->calloc(default_zone_ptr, num_items, size);
}

void*
mz_valloc(malloc_zone_t* zone, size_t size) {
    void *ptr = nullptr;
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr && wrapper.zone->valloc != nullptr) {
            ptr = wrapper.zone->valloc(wrapper.zone, size);
            if (ptr != nullptr || wrapper.type == HMDMallocHookTypeReplace) {
                return ptr;
            }
        }
    }
    return default_zone_ptr->valloc(default_zone_ptr, size);
}

void
mz_free(malloc_zone_t* zone, void* ptr) {
    SizePair pair = mz_size_verbose(ptr);
    if (pair.second != 0) {
        malloc_zone_t *loc_zone = pair.first->zone;
        if (loc_zone->version >= 6 && loc_zone->free_definite_size != nullptr) {
            loc_zone->free_definite_size(loc_zone, ptr, pair.second);
        }else {
            loc_zone->free(loc_zone, ptr);
        }
    }else {
        default_zone_ptr->free(default_zone_ptr, ptr);
    }
}

void
mz_free_definite(malloc_zone_t* zone, void* ptr, size_t size) {
    mz_free(zone, ptr);
}

void*
mz_realloc(malloc_zone_t* zone, void* ptr, size_t size) {
    void* ptr_out = nullptr;
    SizePair pair = mz_size_verbose(ptr);
    if (pair.second != 0) {
        ptr_out = pair.first->zone->realloc(pair.first->zone, ptr, size);
        if (ptr_out == nullptr) {
            ptr_out = default_zone_ptr->malloc(default_zone_ptr, size);
            // If there is not enough memory, the old memory block is not freed and null pointer is returned.
            if (ptr_out != nullptr) {
                memcpy(ptr_out, ptr, MIN(size, pair.second));
                pair.first->zone->free(pair.first->zone, ptr);
            }
        }
        return ptr_out;
    }else {
        // 调用malloc_zone_realloc(default_zone, ptr, size)会进入此逻辑
        return default_zone_ptr->realloc(default_zone_ptr, ptr, size);
    }
}

void*
mz_memalign(malloc_zone_t* zone, size_t align, size_t size) {
    void *ptr = nullptr;
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr && wrapper.zone->version >= 5 && wrapper.zone->memalign != nullptr) {
            ptr = wrapper.zone->memalign(wrapper.zone, align, size);
            if (ptr != nullptr || wrapper.type == HMDMallocHookTypeReplace) {
                return ptr;
            }
        }
    }
    return default_zone_ptr->memalign(default_zone_ptr, align, size);
}

void
mz_destroy(malloc_zone_t* zone) {
    /*
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr && wrapper.zone->destroy != nullptr) {
            wrapper.zone->destroy(wrapper.zone);
        }
    }
    */
}

unsigned
mz_batch_malloc(malloc_zone_t *zone, size_t size, void **results, unsigned count) {
    unsigned count_out = 0;
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr && wrapper.zone->batch_malloc != nullptr) {
            count_out = wrapper.zone->batch_malloc(wrapper.zone, size, results, count);
            if (count_out != 0 || wrapper.type == HMDMallocHookTypeReplace) {
                return count_out;
            }else if (count_out == 0 && wrapper.type == HMDMallocHookTypePartialReplace){
                count_out = default_zone_ptr->batch_malloc(default_zone_ptr, size, results, count);
            }
        }
    }
    return count_out;
}

void
mz_batch_free(malloc_zone_t *zone, void **to_be_freed, unsigned num_to_be_freed) {
    if (num_to_be_freed == 0) {
        return;
    }
    void *ptr = to_be_freed[0];
    SizePair pair = mz_size_verbose(ptr);
    if (pair.second == 0) {
        return default_zone_ptr->batch_free(default_zone_ptr, to_be_freed, num_to_be_freed);
    }
    malloc_zone_t *loc_zone = pair.first->zone;
    loc_zone->batch_free(loc_zone, to_be_freed, num_to_be_freed);
}

kern_return_t
mi_enumerator(task_t task, void *context,
                            unsigned type_mask, vm_address_t zone_address,
                            memory_reader_t reader,
                            vm_range_recorder_t recorder) {
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr && wrapper.zone->introspect != nullptr && wrapper.zone->introspect->enumerator != nullptr) {
            wrapper.zone->introspect->enumerator(task,
                                                 context,
                                                 type_mask,
                                                 zone_address,
                                                 reader,
                                                 recorder);
        }
    }
    return KERN_SUCCESS;
}

size_t
mi_good_size(malloc_zone_t *zone, size_t size) {
    size_t size_out = 0;
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr && wrapper.zone->introspect != nullptr && wrapper.zone->introspect->good_size != nullptr) {
            size_out = wrapper.zone->introspect->good_size(wrapper.zone, size);
            if (size_out != 0) {
                return size_out;
            }
        }
    }
    return size;
}

boolean_t
mi_check(malloc_zone_t *zone) {
    boolean_t res = true;
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr && wrapper.zone->introspect != nullptr && wrapper.zone->introspect->check != nullptr) {
            res = res && wrapper.zone->introspect->check(wrapper.zone);
        }
    }
    return res;
}

void
mi_print(malloc_zone_t *zone, boolean_t verbose) {
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr && wrapper.zone->introspect != nullptr && wrapper.zone->introspect->print != nullptr) {
            wrapper.zone->introspect->print(wrapper.zone, verbose);
        }
    }
}

void
mi_log(malloc_zone_t *zone, void *address) {
    // I don't think we support anything like this
}

void
mi_force_lock(malloc_zone_t *zone) {
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr && wrapper.zone->introspect != nullptr && wrapper.zone->introspect->force_lock != nullptr) {
            wrapper.zone->introspect->force_lock(wrapper.zone);
        }
    }
}

void
mi_force_unlock(malloc_zone_t *zone) {
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr && wrapper.zone->introspect != nullptr && wrapper.zone->introspect->force_unlock != nullptr) {
            wrapper.zone->introspect->force_unlock(wrapper.zone);
        }
    }
}

void
mi_statistics(malloc_zone_t *zone, malloc_statistics_t *stats) {
    malloc_statistics_t tmp = {0};
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr && wrapper.zone->introspect != nullptr && wrapper.zone->introspect->statistics != nullptr) {
            wrapper.zone->introspect->statistics(wrapper.zone, &tmp);
            stats->blocks_in_use += tmp.blocks_in_use;
            stats->size_in_use += tmp.size_in_use;
            stats->max_size_in_use = std::max(stats->max_size_in_use, tmp.max_size_in_use);
            stats->size_allocated += tmp.size_allocated;
        }
    }
}

boolean_t
mi_zone_locked(malloc_zone_t *zone) {
    boolean_t res = false;
    for (int i = HMDMallocHookPriorityHigh; i >= 0; i--) {
        Wrapper &wrapper = malloc_hook_wrappers[i];
        if (wrapper.zone != nullptr && wrapper.zone->introspect != nullptr && wrapper.zone->introspect->zone_locked != nullptr) {
            res = res || wrapper.zone->introspect->zone_locked(wrapper.zone);
        }
    }
    return res;
}

malloc_zone_t*
zone_init() {
    static malloc_introspection_t hmd_malloc_hook_helper_introspection;
    memset(&hmd_malloc_hook_helper_introspection, 0, sizeof(hmd_malloc_hook_helper_introspection));
    
    hmd_malloc_hook_helper_introspection.enumerator = &mi_enumerator;
    hmd_malloc_hook_helper_introspection.good_size = &mi_good_size;
    hmd_malloc_hook_helper_introspection.check = &mi_check;
    hmd_malloc_hook_helper_introspection.print = &mi_print;
    hmd_malloc_hook_helper_introspection.log = &mi_log;
    hmd_malloc_hook_helper_introspection.statistics = &mi_statistics;
    hmd_malloc_hook_helper_introspection.force_lock = &mi_force_lock;
    hmd_malloc_hook_helper_introspection.force_unlock = &mi_force_unlock;
    
    static malloc_zone_t hmd_malloc_hook_helper_zone;
    memset(&hmd_malloc_hook_helper_zone, 0, sizeof(malloc_zone_t));
    
    hmd_malloc_hook_helper_zone.version = 6;
    hmd_malloc_hook_helper_zone.zone_name = "hmd_malloc_hook_helper_zone";
    hmd_malloc_hook_helper_zone.size = &mz_size;
    hmd_malloc_hook_helper_zone.malloc = &mz_malloc;
    hmd_malloc_hook_helper_zone.calloc = &mz_calloc;
    hmd_malloc_hook_helper_zone.valloc = &mz_valloc;
    hmd_malloc_hook_helper_zone.free = &mz_free;
    hmd_malloc_hook_helper_zone.realloc = &mz_realloc;
    hmd_malloc_hook_helper_zone.destroy = &mz_destroy;
    hmd_malloc_hook_helper_zone.batch_malloc = &mz_batch_malloc;
    hmd_malloc_hook_helper_zone.batch_free = &mz_batch_free;
    hmd_malloc_hook_helper_zone.introspect = &hmd_malloc_hook_helper_introspection;
    hmd_malloc_hook_helper_zone.free_definite_size = &mz_free_definite;
    hmd_malloc_hook_helper_zone.memalign = &mz_memalign;
    hmd_malloc_hook_helper_introspection.zone_locked = &mi_zone_locked;
    
    hmd_malloc_helper_zone_ptr = &hmd_malloc_hook_helper_zone;
    
    return &hmd_malloc_hook_helper_zone;
}

malloc_zone_t *
zone_default_get(void) {
    malloc_zone_t **malloc_zones = NULL;
    unsigned int count = 0;

    if (KERN_SUCCESS != malloc_get_all_zones(0, NULL,
        (vm_address_t**)&malloc_zones, &count)) {
        count = 0;
    }

    if (count) {
        return malloc_zones[0];
    }

    return malloc_default_zone();
}

bool
check_registed_zone(Wrapper& wrapper) {
    if (malloc_hook_wrappers[wrapper.priority].zone != nullptr) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"pritory %d has been taken", (int)wrapper.priority);
        DEBUG_C_ASSERT(0);
        return false;
    }
    bool result = false;
    if (wrapper.type == HMDMallocHookTypeReplace) {
        result = wrapper.zone->malloc != nullptr &&
                        wrapper.zone->calloc != nullptr &&
                        wrapper.zone->valloc != nullptr &&
                        wrapper.zone->realloc != nullptr &&
                        wrapper.zone->free != nullptr &&
                        wrapper.zone->free_definite_size != nullptr &&
                        wrapper.zone->batch_malloc != nullptr &&
                        wrapper.zone->batch_free != nullptr &&
                        wrapper.zone->introspect != nullptr &&
                        wrapper.zone->introspect->enumerator != nullptr &&
                        wrapper.zone->introspect->zone_locked != nullptr;
        DEBUG_C_ASSERT(result);
    }else if (wrapper.type == HMDMallocHookTypePartialReplace) {
        result = wrapper.zone->malloc != nullptr &&
                        wrapper.zone->calloc != nullptr &&
                        wrapper.zone->realloc != nullptr &&
                        wrapper.zone->free != nullptr &&
                        wrapper.zone->introspect != nullptr &&
                        wrapper.zone->introspect->enumerator != nullptr &&
                        wrapper.zone->introspect->zone_locked != nullptr;
        DEBUG_C_ASSERT(result);
    }
    return result;
}

void
zone_promote(void) {
    malloc_zone_t *zone;
    HMDThreadSuspender::ThreadSuspender suspend;
    if (suspend.is_suspended) {
        do {
            /*
             * Unregister and reregister the default zone.  On OSX >= 10.6,
             * unregistering takes the last registered zone and places it
             * at the location of the specified zone.  Unregistering the
             * default zone thus makes the last registered one the default.
             * On OSX < 10.6, unregistering shifts all registered zones.
             * The first registered zone then becomes the default.
             */
            malloc_zone_unregister(default_zone_ptr);
            malloc_zone_register(default_zone_ptr);

            zone = zone_default_get();
        } while (zone != hmd_malloc_helper_zone_ptr);
    }
}

bool
zone_register(void) {
    /*
     * If something else replaced the system default zone allocator, don't
     * register hmd_malloc_hook_zone
     */
    default_zone_ptr = zone_default_get();
    if (!default_zone_ptr->zone_name || strcmp(default_zone_ptr->zone_name,
        "DefaultMallocZone") != 0) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Failed to register malloc hook zone because %s has been registed", default_zone_ptr->zone_name);
        return false;
    }

    /* Register the custom zone.  At this point it won't be the default. */
    zone_init();
    malloc_zone_register(hmd_malloc_helper_zone_ptr);

    /* Promote the custom zone to be default. */
    zone_promote();
    
    return true;
}

void
slardar_malloc_notify(malloc_zone_t* zone) {
    /*SlardarMalloc切换的通知*/
    if(zone != NULL && strcmp(malloc_get_zone_name(zone), "jemalloc_zone") == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kHMDSlardarMallocInuseNotification object:nil];
    }
}
}  // unnamed namespace

bool
manageHookWithMallocZone(malloc_zone_t* mallocZone, HMDMallocHookPriority priority, HMDMallocHookType type) {
    Wrapper wrapper = {mallocZone, priority, type};
    if (check_registed_zone(wrapper) == false) {
        return false;
    }
    mutex.lock();
    if (initialized == false) {
        if (zone_register() == false) {
            mutex.unlock();
            return false;
        }
        initialized = true;
    }
    malloc_hook_wrappers[priority] = wrapper;
    mutex.unlock();
    
    slardar_malloc_notify(mallocZone);
    
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"priority %d has been taken by %s", (int)wrapper.priority, wrapper.zone->zone_name);
    
    return true;
}
