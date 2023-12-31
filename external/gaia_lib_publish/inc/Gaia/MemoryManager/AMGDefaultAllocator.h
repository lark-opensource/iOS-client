/**
 * @file AMGDefaultAllocator.h
 * @author fan jiaqi (fanjiaqi.837@bytedance.com)
 * @brief The default allocator of memory manager
 * @version 0.1
 * @date 2020-02-20
 * 
 * @copyright Copyright (c) 2020
 * 
 */
#pragma once
#ifndef AMG_DEFAULT_ALLOCATOR_H
#define AMG_DEFAULT_ALLOCATOR_H
#include "Gaia/AMGPrerequisites.h"
#include "Gaia/MemoryManager/AMGBaseAllocator.h"
#include "Gaia/MemoryManager/AMGMemoryManagerCommon.h"
#include <mutex>
#include <unordered_map>
NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief The static calctlation of log2.
 * 
 * @tparam n The number to calculate.
 */
template <int n>
struct StaticLog2
{
    /**
     * @brief The value of log2 of n.
     * 
     */
    static const int value = StaticLog2<n / 2>::value + 1;
};
/**
 * @brief The static calctlation of log2 of 1.
 * 
 */
template <>
struct StaticLog2<1>
{
    /**
     * @brief The value of log2 of 1.
     * 
     */
    static const int value = 0;
};

/**
 * @brief The default allocator in memory manager.
 * 
 * @tparam LLAlloctor The low level allocator.
 */
template <class LLAlloctor>
class DefaultAllocator : public BaseAllocator
{
    enum RequestType
    {
        Register,
        Unregister,
        Test
    };

public:
    /**
     * @brief Construct a new default allocator.
     * 
     * @param name The name of current allocator.
     */
    DefaultAllocator(const char* name);

    /**
     * @brief Allocate a memory block with size and align.
     * 
     * @param size the size of memory block.
     * @param align The align of memory block.
     * @return void* The pointer of memory block.
     */
    virtual void* allocate(std::size_t size, int align) override;
    /**
     * @brief Reallocate the allocated memory pointer.
     * 
     * @param p The allocated memory pointer.
     * @param size The size of reallocation.
     * @param align The align of reallocation.
     * @return void* The pointer of reallocation.
     */
    virtual void* reallocate(void* p, std::size_t size, int align) override;
    /**
     * @brief Deallocate memory pointer.
     * 
     * @param p The allocated memory pointer.
     */
    virtual void deallocate(void* p) override;
    /**
     * @brief Whether the pointer is allocated by current allocator.
     * 
     * @param p The target memory pointer.
     * @return true The pointer is allocated by current allocator.
     * @return false The pointer is not allocated by current allocator.
     */
    virtual bool contains(const void* p) override;
    /**
     * @brief Get the the size of allocated pointer.
     * 
     * @return int The size of target pointer.
     */
    virtual int getPtrSize(const void* ptr) const override;

    /**
     * @brief Get size of pointer and header.
     * 
     * @param ptr The memory pointer.
     * @return int The total size of pointer and header.
     */
    static int getOverheadSize(void* ptr);

private:
    // needs 30 bit (4byte aligned allocs and packed as bitarray) ( 1 byte -> 32Bytes, 4bytes rep 128Bytes(7bit))
    enum
    {
        TargetBitsRepresentedPerBit = StaticLog2<DefaultMemoryAlignment>::value,
        TargetBitsRepresentedPerByte = 5 + TargetBitsRepresentedPerBit,
        Page1Bits = 7, // 128*4Bytes = 512Bytes (page: 4GB/128 = 32MB per pointer)
        Page2Bits = 7, // 128*4Bytes = 512Bytes (page: 32MB/128 = 256KB per pointer)
        Page3Bits = 5, // 32*4Bytes = 128Bytes (page: 256K/32 = 8K per pointer)
        Page4Bits = 32 - Page1Bits - Page2Bits - Page3Bits - TargetBitsRepresentedPerByte
    };

    struct PageAllocationElement
    {
        PageAllocationElement()
            : m_HighBits(0)
            , m_PageAllocations(nullptr)
        {
        }
        uint32_t m_HighBits;
        int**** m_PageAllocations;
    };

    std::unordered_map<uint32_t, PageAllocationElement> m_PageAllocationMap;

    template <RequestType requestType>
    bool allocationPage(const void* p);

    std::mutex m_AllocLock;

    void registerAllocation(const void* p);
    void registerDeallocation(const void* p);

    void* addHeaderAndFooter(void* ptr, std::size_t size, int align) const;

    LLAlloctor m_allocator;
};

NAMESPACE_AMAZING_ENGINE_END
#endif
