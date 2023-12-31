/**
 * @file AMGAllocationHeader.h
 * @author fan jiaqi (fanjiaqi.837@bytedance.com)
 * @brief The base allocator in memory manager.
 * @version 0.1
 * @date 2020-02-20
 * 
 * @copyright Copyright (c) 2020
 * 
 */
#ifndef AMG_BASE_ALLOCATOR_H
#define AMG_BASE_ALLOCATOR_H
#include "Gaia/AMGPrerequisites.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Base allocator of memory manager.
 * 
 */
class BaseAllocator
{
public:
    /**
     * @brief Construct a new base allocator.
     * 
     * @param name The name of allocator.
     */
    BaseAllocator(const char* name);
    /**
     * @brief Destroy the base allocator.
     * 
     */
    virtual ~BaseAllocator() {}
    /**
     * @brief Allocate a memory block with size and align.
     * 
     * @param size the size of memory block.
     * @param align The align of memory block.
     * @return void* The pointer of memory block.
     */
    virtual void* allocate(std::size_t size, int align) = 0;
    /**
     * @brief Reallocate the allocated memory pointer.
     * 
     * @param p The allocated memory pointer.
     * @param size The size of reallocation.
     * @param align The align of reallocation.
     * @return void* The pointer of reallocation.
     */
    virtual void* reallocate(void* p, std::size_t size, int align) { return nullptr; }
    /**
     * @brief Deallocate memory pointer.
     * 
     * @param p The allocated memory pointer.
     */
    virtual void deallocate(void* p) = 0;

    /**
     * @brief Whether the pointer is allocated by current allocator.
     * 
     * @param p The target memory pointer.
     * @return true The pointer is allocated by current allocator.
     * @return false The pointer is not allocated by current allocator.
     */
    virtual bool contains(const void* p) = 0;

    /**
     * @brief Return the actual number of requests bytes
     * 
     * @return std::size_t The actual number of requests bytes.
     */
    virtual std::size_t getAllocatedMemorySize() const { return m_TotalRequestedBytes; }

    /**
     * @brief Get total used size (including overhead allocations)
     * 
     * @return std::size_t The total used size of current allocator.
     */
    virtual std::size_t getAllocatorSizeTotalUsed() const { return m_TotalRequestedBytes + m_BookKeepingMemoryUsage; }

    /**
     * @brief Get the reserved size of the allocator (including all overhead memory allocated)
     * 
     * @return std::size_t The reserved size of allocator.
     */
    virtual std::size_t getReservedSizeTotal() const { return m_TotalReservedMemory; }

    /**
     * @brief Get the peak allocated size of the allocator.
     * 
     * @return std::size_t The peak allocated size of current allocator.
     */
    virtual std::size_t getPeakAllocatedMemorySize() const { return m_PeakRequestedBytes; }

    /**
     * @brief Get the the size of allocated pointer.
     * 
     * @return int The size of target pointer.
     */
    virtual int getPtrSize(const void* ptr) const { return 0; }

    /**
     * @brief Get the name of current allocator.
     * 
     * @return const char* The name of allocator.
     */
    virtual const char* getName() const { return m_Name; }

protected:
    void registerAllocationData(std::size_t requestedSize, std::size_t overhead);
    void registerDeallocationData(std::size_t requestedSize, std::size_t overhead);

    const char* m_Name = nullptr;
    int m_AllocatorIdentifier = 0;
    std::size_t m_TotalRequestedBytes = 0;    // Memory requested by the allocator
    std::size_t m_TotalReservedMemory = 0;    // All memory reserved by the allocator
    std::size_t m_BookKeepingMemoryUsage = 0; // memory used for bookkeeping (headers etc.)
    std::size_t m_PeakRequestedBytes = 0;     // Memory requested by the allocator
    int m_NumAllocations = 0;                 // Allocation count
};
/**
 * @brief Register one allocation for recording.
 * 
 * @param requestedSize The size of allocation.
 * @param overhead The size of header.
 */
inline void BaseAllocator::registerAllocationData(std::size_t requestedSize, std::size_t overhead)
{
    m_TotalRequestedBytes += requestedSize;
    m_BookKeepingMemoryUsage += overhead;
    m_PeakRequestedBytes = m_TotalRequestedBytes > m_PeakRequestedBytes ? m_TotalRequestedBytes : m_PeakRequestedBytes;
    m_NumAllocations++;
}
/**
 * @brief Register one deallocation for recording.
 * 
 * @param requestedSize The size of allocation.
 * @param overhead The size of header.
 */
inline void BaseAllocator::registerDeallocationData(std::size_t requestedSize, std::size_t overhead)
{
    m_TotalRequestedBytes -= requestedSize;
    m_BookKeepingMemoryUsage -= overhead;
    m_NumAllocations--;
}

NAMESPACE_AMAZING_ENGINE_END
#endif
