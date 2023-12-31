/**
 * @file AMGAllocationHeader.h
 * @author fan jiaqi (fanjiaqi.837@bytedance.com)
 * @brief The header of memory manager allocation
 * @version 0.1
 * @date 2020-02-20
 * 
 * @copyright Copyright (c) 2020
 * 
 */
#pragma once
#ifndef AMG_ALLOCATION_HEADER_H
#define AMG_ALLOCATION_HEADER_H
#include "Gaia/AMGPrerequisites.h"
#include "Gaia/MemoryManager/AMGMemoryManagerCommon.h"
NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Memory manager allocation header
 * 
 */
struct AllocationHeader
{
public:
    /**
     * @brief Construct a new allocation header.
     * 
     */
    AllocationHeader()
        : m_HasPadding(0)
        , m_AllocationSize(0)
    {
    }
    /**
     * @brief Set the content of header of one ptr.
     * 
     * @param ptr Memory pointer.
     * @param size The size of current memory pointer allocation.
     * @param padCount The padding count of current allocation header.
     */
    static void set(void* ptr, std::size_t size, int padCount);

    /**
     * @brief Get the header of one pointer.
     * 
     * @param ptr Target pointer.
     * @return AllocationHeader* The header of target pointer.
     */
    static AllocationHeader* getHeader(const void* ptr);

    /**
     * @brief Get the padding count of current header.
     * 
     * @return uint32_t Padding count.
     */
    uint32_t getPadding() const { return m_HasPadding ? *(((uint32_t*)(this)) - 1) : 0; }
    /**
     * @brief Get the size of current allocation.
     * 
     * @return int The size of current allocation.
     */
    int getRequestedSize() const { return m_AllocationSize; }
    /**
     * @brief Calculate needed size including header with align.
     * 
     * @param size The origin size of one allocation.
     * @param align Align value.
     * @return std::size_t The size including pointer and header.
     */
    static std::size_t calculateNeededAllocationSize(std::size_t size, int align);
    /**
     * @brief Get the Real Pointer object
     * 
     * @param ptr Get the real allocation pointer of one pointer with header.
     * @return void* The real allocation pointer.
     */
    static void* getRealPointer(const void* ptr);
    /**
     * @brief Get the required padding count with align.
     * 
     * @param realptr The real allocated pointer.
     * @param align Align value.
     * @return int The required podding count.
     */
    static int getRequiredPadding(const void* realptr, int align);
    /**
     * @brief Get the size of header.
     * 
     * @return int The size of header.
     */
    static int getHeaderSize();
    /**
     * @brief Get the total size of header and padding count.
     * 
     * @return int The total size.
     */
    int getOverheadSize();

private:
    /**
     * @brief Whether has padding.
     * 
     */
    uint32_t m_HasPadding : 1;
    /**
     * @brief Allocation size.
     * 
     */
    uint32_t m_AllocationSize : 31;
};

/**
 * @brief Set the content of header of one ptr.
 * 
 * @param ptr Memory pointer.
 * @param size The size of current memory pointer allocation.
 * @param padCount The padding count of current allocation header.
 */
inline void AllocationHeader::set(void* ptr, std::size_t size, int padCount)
{
    AllocationHeader* header = getHeader(ptr);
    header->m_AllocationSize = (uint32_t)size;
    header->m_HasPadding = padCount != 0;
    if (header->m_HasPadding)
    {
        *((reinterpret_cast<uint32_t*>(header)) - 1) = padCount;
    }
}

/**
 * @brief Get the header of one pointer.
 * 
 * @param ptr Target pointer.
 * @return AllocationHeader* The header of target pointer.
 */
inline AllocationHeader* AllocationHeader::getHeader(const void* ptr)
{
    return (AllocationHeader*)(reinterpret_cast<const char*>(ptr) - getHeaderSize());
}

/**
 * @brief Get the size of header.
 * 
 * @return int The size of header.
 */
inline int AllocationHeader::getHeaderSize()
{
    return sizeof(AllocationHeader);
}

/**
 * @brief Get the required padding count with align.
 * 
 * @param realptr The real allocated pointer.
 * @param align Align value.
 * @return int The required podding count.
 */
inline int AllocationHeader::getRequiredPadding(const void* realptr, int align)
{
    return align - ((((uintptr_t)realptr + getHeaderSize() - 1) & (align - 1)) + 1);
}

/**
 * @brief Calculate needed size including header with align.
 * 
 * @param size The origin size of one allocation.
 * @param align Align value.
 * @return std::size_t The size including pointer and header.
 */
inline std::size_t AllocationHeader::calculateNeededAllocationSize(std::size_t size, int align)
{
    int alignMask = align - 1;
    return size + getHeaderSize() + alignMask;
}

/**
 * @brief Get the Real Pointer object
 * 
 * @param ptr Get the real allocation pointer of one pointer with header.
 * @return void* The real allocation pointer.
 */
inline void* AllocationHeader::getRealPointer(const void* ptr)
{
    AllocationHeader* header = getHeader(ptr);
    int padCount = header->getPadding();
    return reinterpret_cast<char*>(header) - padCount;
}

/**
 * @brief Get the total size of header and padding count.
 * 
 * @return int The total size.
 */
inline int AllocationHeader::getOverheadSize()
{
    int alignMask = DefaultMemoryAlignment - 1; // estimate
    return getHeaderSize() + alignMask;
}

NAMESPACE_AMAZING_ENGINE_END
#endif
