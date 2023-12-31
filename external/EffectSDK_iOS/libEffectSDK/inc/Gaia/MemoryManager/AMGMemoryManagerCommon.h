/**
 * @file AMGMemoryManagerCommon.h
 * @author fan jiaqi (fanjiaqi.837@bytedance.com)
 * @brief The common defination of memory manager
 * @version 0.1
 * @date 2020-02-20
 * 
 * @copyright Copyright (c) 2020
 * 
 */
#ifndef AMG_MEOMRY_MANAGER_COMMON_H
#define AMG_MEOMRY_MANAGER_COMMON_H
#include "Gaia/AMGPrerequisites.h"
NAMESPACE_AMAZING_ENGINE_BEGIN

#define ENABLE_MEMORY_PROFILER 0

#define DefaultMemoryAlignment 16
/**
 * @brief Get the preallocated memory.
 * 
 * @param size The size of preallocated memory.
 * @return void* The pointer of preallocated memory.
 */
void* GetPreallocatedMemory(std::size_t size);

/**
 * @brief Construct object in heap.
 * 
 */
#define HEAP_NEW(cls) new (GetPreallocatedMemory(sizeof(cls))) cls
/**
 * @brief Delete object in heap.
 * 
 */
#define HEAP_DELETE(obj, cls) obj->~cls();

NAMESPACE_AMAZING_ENGINE_END
#endif
