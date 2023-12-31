/**
 * @file AMGLowLevelAllocator.h
 * @author fan jiaqi (fanjiaqi.837@bytedance.com)
 * @brief The low level allocator of memory manager.
 * @version 0.1
 * @date 2020-02-20
 * 
 * @copyright Copyright (c) 2020
 * 
 */
#pragma once
#ifndef AMG_LOW_LEVEL_ALLOCATOR_H
#define AMG_LOW_LEVEL_ALLOCATOR_H
#include "Gaia/AMGPrerequisites.h"

NAMESPACE_AMAZING_ENGINE_BEGIN
/**
 * @brief Low level allocator.
 * 
 */
class LowLevelAllocator
{
public:
    /**
     * @brief Allocate a memory block with size and align.
     * 
     * @param size the size of memory block.
     * @param align The align of memory block.
     * @return void* The pointer of memory block.
     */
    void* allocate(std::size_t size, int align);
    /**
     * @brief Reallocate the allocated memory pointer.
     * 
     * @param p The allocated memory pointer.
     * @param size The size of reallocation.
     * @param align The align of reallocation.
     * @return void* The pointer of reallocation.
     */
    void* reallocate(void* p, std::size_t size, int align);
    /**
     * @brief Deallocate memory pointer.
     * 
     * @param p The allocated memory pointer.
     */
    void deallocate(void* p);
};

NAMESPACE_AMAZING_ENGINE_END
#endif
