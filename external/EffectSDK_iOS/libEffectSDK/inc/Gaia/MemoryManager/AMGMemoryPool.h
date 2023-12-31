/**
 * @file AMGMemoryPool.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Memory pool.
 * @version 0.1
 * @date 2019-11-25
 * 
 * @copyright Copyright (c) 2019
 * 
 */

#pragma once

#include <vector>
#include <mutex>
#include "Gaia/AMGPrerequisites.h"
#include "Gaia/MemoryManager/AMGMemoryLabels.h"
NAMESPACE_AMAZING_ENGINE_BEGIN
class MemoryManager;
class MessageCenter;
/**
 * @brief The minimal block size can be set.
 * 
 */
static int MinBlockSize = sizeof(void*);
/**
 * @brief Memory pool is a container that can allocate memory with fixed size.
 * Block is the unit that is allocated one time, bubble is the unit that stored in pool.
 */
class GAIA_LIB_EXPORT MemoryPool
{
    friend class MemoryManager;
    friend class MessageCenter; // Temp, Memory Pool in Message Center need to be managered by MemoryManager
    friend void MemoryPoolTest();

private:
    struct Bubble
    {
        char data[1];
    };
    typedef std::vector<Bubble*> Bubbles;
    /**
     * @brief Construct a new Memory Pool object
     * 
     * @param name Memory pool name.
     * @param blockSize The size of memory for one allocation.
     * @param bubbleSize The size of memory that stored in memory pool.
     * @param label The label of memory.
     */
    MemoryPool(const char* name, int blockSize, int bubbleSize, AMGMemLabelIdentifier label = AMGMemLabelIdentifier::Default);
    /**
     * @brief Destroy the Memory Pool object
     * 
     */
    ~MemoryPool();

public:
    /**
     * @brief Allocate one block.
     * 
     * @return void* Memory address for this allocation.
     */
    void* allocate();
    /**
     * @brief Allocate less than single block.
     * 
     * @param amount The size for this allocation.
     * @return void* Memory address for this allocation.
     */
    void* allocate(size_t amount);
    /**
     * @brief Deallocate one block.
     * 
     * @param ptr Pointer for memory of block.
     */
    void deallocate(void* ptr);
    /**
     * @brief Deallocate all blocks
     * 
     */
    void deallocateAll();
    /**
     * @brief Get bubble count in current pool.
     * 
     * @return size_t Bubble count.
     */
    size_t getBubbleCount() const { return m_bubbles.size(); }
    /**
     * @brief Get allocated blcok count in current pool.
     * 
     * @return int Block count.
     */
    int getAllocCount() const { return m_allocCount; }
    /**
     * @brief Get the total bytes count in bubbles.
     * 
     * @return int Total bytes count.
     */
    int getAllocatedBytes() { return int(m_bubbles.size()) * m_blocksPerBubble * m_blockSize; }
    /**
     * @brief Get allocated block count in current pool.
     * 
     * @return int Block count.
     */
    int getAllocatedObjectsCount() { return m_allocCount; }

    /**
     * @brief Pre allocate memory manually
     * 
     * @param size The size of pre allocate memory.
     */
    void preAllocateMemory(int size);
    // Set allocate memory automatically
    /**
     * @brief Set allocate memory automatically, if it is setted to false, total allocated memory size cannot be larger than pre allcated memory.
     * 
     * @param allocateMemoryAuto  Allocate memory automatically.
     */
    void setAllocateMemoryAutomatically(bool allocateMemoryAuto) { m_allocateMemoryAutomatically = allocateMemoryAuto; }

    /// Set Memory Manager for this Memory Pool
    void setMemoryManager(MemoryManager* manager) { m_memoryManager = manager; }

    /// Check Wthether this pool contains target ptr
    bool contains(void* ptr);

private:
    void allocNewBubble();

    void reset();

private:
    MemoryManager* m_memoryManager = nullptr;
    int m_blockSize = 0;
    int m_bubbleSize = 0;
    int m_blocksPerBubble = 0;

    Bubbles m_bubbles;
    const char* m_name = nullptr;
    void* m_headOfFreeList = nullptr;
    bool m_allocateMemoryAutomatically = false;
    std::mutex m_mutex;
    AMGMemLabelIdentifier m_allocLabel = AMGMemLabelIdentifier::Default;

    int m_allocCount = 0; // number of blocks currently allocated
};

// --------------------------------------------------------------------------
//  Macros for class fixed-size pooled allocations:
//        DECLARE_POOLED_ALLOC in the .h file, in a private section of a class,
//        DEFINE_POOLED_ALLOC in the .cpp file

#define STATIC_INITIALIZE_POOL(_class) _class::s_PoolAllocator() = new MemoryPool(#_class, sizeof(_class), _class::s_PoolSize())
#define STATIC_DESTROY_POOL(_class) delete _class::s_PoolAllocator()

#define DECLARE_POOLED_ALLOC(_class)                                                     \
public:                                                                                  \
    inline void* operator new(size_t size) { return s_PoolAllocator()->allocate(size); } \
    inline void operator delete(void* p) { s_PoolAllocator()->deallocate(p); }           \
    static MemoryPool*& s_PoolAllocator();                                               \
    static int s_PoolSize();                                                             \
                                                                                         \
private:

#define DEFINE_POOLED_ALLOC(_class, _bubbleSize) \
    MemoryPool*& _class::s_PoolAllocator()       \
    {                                            \
        static MemoryPool* pool = nullptr;       \
        return pool;                             \
    }                                            \
    int _class::s_PoolSize()                     \
    {                                            \
        return _bubbleSize;                      \
    }

/**
 * @brief MemoryPool unit test.
 */
void MemoryPoolTest();

NAMESPACE_AMAZING_ENGINE_END
