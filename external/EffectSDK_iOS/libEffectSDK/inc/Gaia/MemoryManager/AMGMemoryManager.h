/**
 * @file AMGMemoryManager.h
 * @author fan jiaqi (fanjiaqi.837@bytedance.com)
 * @brief The memory manager.
 * @version 0.1
 * @date 2020-02-20
 * 
 * @copyright Copyright (c) 2020
 * 
 */
#pragma once
#ifndef AMG_MEMORY_MANAGER_H
#define AMG_MEMORY_MANAGER_H

#include "Gaia/AMGPrerequisites.h"
#include "Gaia/MemoryManager/AMGMemoryLabels.h"
#include "Gaia/MemoryManager/AMGMemoryManagerCommon.h"
#include <unordered_map>
#include <set>
#include <map>
#include <mutex>
NAMESPACE_AMAZING_ENGINE_BEGIN

class MemoryPool;
class BaseAllocator;
/**
 * @brief Memory manager.
 * 
 */
class GAIA_LIB_EXPORT MemoryManager
{
public:
    /**
     * @brief Construct a new memory manager.
     * 
     */
    MemoryManager();
    /**
     * @brief Destroy the memory manager.
     * 
     */
    ~MemoryManager();
    /**
     * @brief Initialize memory manager.
     * 
     */
    void init();
    /**
     * @brief Deinit memory manager.
     * 
     */
    void deinit();
    /**
     * @brief Get the allocator which contains the target pointer.
     * 
     * @param ptr The target pointer.
     * @return BaseAllocator* The allocator which contains the target pointer.
     */
    BaseAllocator* getAllocatorContainingPtr(const void* ptr);
    /**
     * @brief Get the allocator by memory label.
     * 
     * @param label Memory label.
     * @return BaseAllocator* The allocator 
     */
    BaseAllocator* getAllocator(AMGMemLabelIdentifier label);
    /**
     * @brief Whether current memory manager is active.
     * 
     * @return true Current manager is active.
     * @return false Current manager is not active.
     */
    bool IsActive() { return m_IsActive; }
    /**
     * @brief Allocate new memory block.
     * 
     * @param size The size of new memory block.
     * @param align The align value of new memory block.
     * @param label The memory label of new memory block.
     * @param file The file name of current allocation.
     * @param line Tne line of file of current allocation.
     * @return void* The pointer of new memory block.
     */
    void* allocate(std::size_t size, int align, AMGMemLabelIdentifier label, const char* file = nullptr, int line = 0);
    /**
     * @brief Reallocate allocated memory block.
     * 
     * @param ptr The alllocated memory pointer.
     * @param size The size of reallocation.
     * @param align The align value of reallocation.
     * @param label The memory label of reallocation.
     * @param file The file name of current reallocation.
     * @param line The line in file of current reallocation.
     * @return void* The pointer of reallocated memory.
     */
    void* reallocate(void* ptr, std::size_t size, int align, AMGMemLabelIdentifier label, const char* file = nullptr, int line = 0);
    /**
     * @brief Deallcate memory.
     * 
     * @param ptr The pointer of allocated memory.
     */
    void deallocate(void* ptr);
    /**
     * @brief Deallocate memory.
     * 
     * @param ptr The pointer of allcoated memory.
     * @param label The memory label of allocated memory.
     */
    void deallocate(void* ptr, AMGMemLabelIdentifier label);
    /**
     * @brief Low level allocation.
     * 
     * @param size The size of allocation.
     * @return void* The pointer of allcated memory.
     */
    static void* lowLevelAllocate(std::size_t size);
    /**
     * @brief Low level callocation.
     * 
     * @param count The number of allocaiton.
     * @param size The size of one allocation.
     * @return void* The pointer of allocated memory.
     */
    static void* lowLevelCAllocate(std::size_t count, std::size_t size);
    /**
     * @brief Low level reallocation.
     * 
     * @param p The poiner of allocated memory to reallocate.
     * @param size The size of reallocation.
     * @return void* The pointer of reallocation.
     */
    static void* lowLevelreallocate(void* p, std::size_t size);
    /**
     * @brief Low level free.
     * 
     * @param p The memory pointer of allocated memory.
     */
    static void lowLevelFree(void* p);

    /**
     * @brief Get the total allocated memory of current memory manager.
     * 
     * @return std::size_t The total allocated memory.
     */
    std::size_t getTotalAllocatedMemory();
    /**
     * @brief Get the number of allocators.
     * 
     * @return int The number of allocators in memory manager.
     */
    int getAllocatorCount();
    /**
     * @brief Get the allocated memory with memory label.
     * 
     * @param label The target memory label.
     * @return std::size_t The size of allocated memory.
     */
    std::size_t getAllocatedMemory(AMGMemLabelIdentifier label);
    /**
     * @brief Get the number of allocation with memory label.
     * 
     * @param label The target memory label.
     * @return int The number of allocation.
     */
    int getAllocCount(AMGMemLabelIdentifier label);
    /**
     * @brief Get the largest allocation of memory label.
     * 
     * @param label The target memory label.
     * @return std::size_t The size of largest allocation.
     */
    std::size_t getLargestAlloc(AMGMemLabelIdentifier label);

public:
    /**
     * @brief Print the memory status of current memory manager.
     * 
     * @param str The string to print.
     */
    void printShortMemoryStats(String& str);

public:
    /**
     * @brief Get the memory pool by key.
     * 
     * @param keyPool Memory pool key.
     * @return MemoryPool* The pointer of target memory pool.
     */
    MemoryPool* getMemoryPool(int keyPool);
    /**
     * @brief Create a new memory pool.
     * 
     * @param name The name of memory pool.
     * @param blockSize The block size of memory pool.
     * @param BubbleSize The bubble size of memory pool.
     * @param label The memory label of memory pool.
     * @return int The memory pool key.
     */
    int createMemoryPool(const char* name, int blockSize, int BubbleSize, AMGMemLabelIdentifier label);

    /**
     * @brief The info to construct a new memory pool.
     * 
     */
    struct MemoryPoolInfo
    {
        /**
         * @brief Memory pool name.
         * 
         */
        const char* name;
        /**
         * @brief Block size of memory pool.
         * 
         */
        int blockSize;
        /**
         * @brief Bubble size of memory pool.
         * 
         */
        int bubbleSize;
        /**
         * @brief Memory label of memory pool.
         * 
         */
        AMGMemLabelIdentifier label = AMGMemLabelIdentifier::Default;
    };
    /**
     * @brief Register reserved memory pool info.
     * 
     * @param name The name of memory pool.
     * @param blcokSize The block size of memory pool.
     * @param BubbleSize The bubble size of memory pool.
     * @param label The memory label of memory pool.
     * @return int The memory pool key.
     */
    static int registerReservedPoolInfo(const char* name, int blcokSize, int BubbleSize, AMGMemLabelIdentifier label);
    /**
     * @brief The vector of reserved memory pool.
     * 
     */
    static std::vector<MemoryPoolInfo> s_ReservedPoolInfo;

private:
    std::vector<MemoryPool*> m_MemPools;

private:
    void initAllAllocators();

    int m_NumAllocators = 0;

    static const int m_MaxAllocators = 16;
    bool m_IsActive = true;
    BaseAllocator* m_Allocators[m_MaxAllocators];

    struct LabelInfo
    {
        BaseAllocator* alloc = nullptr;
        std::size_t allocatedMemory = 0;
        int numAllocs = 0;
        std::size_t largestAlloc = 0;
    };
    LabelInfo m_AllocatorMap[AMGMemLabelIdentifier::LabelCount];

#if ENABLE_MEMORY_PROFILER
private:
    void registerAllocation(void* ptr, std::size_t size, BaseAllocator* alloc, MemLabelRef label, const char* file, int line);
    void registerDeallocation(void* ptr, BaseAllocator* alloc, MemLabelRef label);
    void RegisterAllocationSite(void* ptr, MemLabelRef label, const char* file, int line, std::size_t allocSize = 0);
    void UnregisterAllocationSite(void* ptr, BaseAllocator* alloc, std::size_t freeSize, MemLabelRef label);

    struct AllocationSite
    {
        AMGMemLabelIdentifier label;
        const char* file;
        int line;
        int allocated;
        int allocCount;
        int ownedAllocated;
        int ownedCount;
        size_t cummulativeAllocated;
        size_t cummulativeAllocCount;

        bool operator()(const AllocationSite& s1, const AllocationSite& s2) const
        {
            return s1.line != s2.line ? s1.line < s2.line : s1.label != s2.label ? s1.label < s2.label : s1.file < s2.file;
        }

        struct Sorter
        {
            bool operator()(const AllocationSite* a, const AllocationSite* b) const
            {
                return a->allocated > b->allocated;
            }
        };
    };

private:
    std::mutex m_SiteMutex;

    struct LocalHeaderInfo
    {
        size_t size;
        const AllocationSite* site;
    };
    typedef std::set<AllocationSite, AllocationSite> AllocationSites;
    AllocationSites* m_AllocationSites;

    typedef std::map<void*, LocalHeaderInfo, std::less<void*>> AllocationSizes;
    AllocationSizes* m_AllocationSizes;

#endif
};
/**
 * @brief Return whether the given number is power of two.
 * 
 * @param mask The given number to calculate.
 * @return true The number is power of 2.
 * @return false The number is not power of 2.
 */
inline bool IsPowerOfTwo(uint32_t mask)
{
    return (mask & (mask - 1)) == 0;
}

NAMESPACE_AMAZING_ENGINE_END
#endif
