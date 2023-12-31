//
//  hmd_mmap_memory_allocator.h
//  Heimdallr
//
//  Created by zhouyang11 on 2023/7/20.
//

#ifndef hmd_mmap_memory_allocator_h
#define hmd_mmap_memory_allocator_h

#include <stdio.h>
#include <malloc/malloc.h>
#include <cstddef>
#include <climits>

namespace HMDMMapAllocator {

#define ZONE_HASH(k_type, v_type) std::unordered_map<k_type, v_type, std::hash<k_type>, std::equal_to<k_type>, ZoneAllocator<std::pair<const k_type, v_type>>>
#define ZONE_VECTOR(v_type) std::vector<v_type, ZoneAllocator<v_type>>
#define MATCHED_ZONE_SET(v_type, hash) std::unordered_set<v_type, hash, std::equal_to<v_type>, ZoneAllocator<v_type>>
#define ENTRY_ZONE_SET(v_type) std::unordered_set<v_type, std::hash<v_type>, std::equal_to<v_type>, ZoneAllocator<v_type>>


malloc_zone_t * g_malloc_zone();

void g_malloc_zone_destory();

template <class T>
class ZoneAllocator {
public:
    typedef T value_type;
    typedef value_type* pointer;
    typedef const value_type* const_pointer;
    typedef value_type& reference;
    typedef const value_type& const_reference;
    typedef typename std::size_t size_type;
    typedef std::ptrdiff_t difference_type;
    template <class tTarget>
    struct rebind
    {
        typedef ZoneAllocator<tTarget> other;
    };
    
    ZoneAllocator() {}
    
    ~ZoneAllocator() {}
    
    template <class T2>
    ZoneAllocator(ZoneAllocator<T2> const&)
    {
    }
    
    pointer
    address(reference ref)
    {
        return &ref;
    }
    
    const_pointer
    address(const_reference ref)
    {
        return &ref;
    }
    
    pointer
    allocate(size_type count, const void* = 0)
    {
        size_type byteSize = count * sizeof(T);
        auto zone = g_malloc_zone();
        void* result = malloc_zone_malloc(zone, byteSize);
        return reinterpret_cast<pointer>(result);
    }
    
    void deallocate(pointer ptr, size_type)
    {
        malloc_zone_free(g_malloc_zone(), ptr);
    }

    size_type
    max_size() const
    {
        return ULONG_MAX / sizeof(T);
    }
    
    void
    construct(pointer ptr, const T& t)
    {
        new(ptr) T(t);
    }
    
    void
    destroy(pointer ptr)
    {
        ptr->~T();
    }
    
    template <class T2> bool
    operator==(ZoneAllocator<T2> const&) const
    {
        return true;
    }
    
    template <class T2> bool
    operator!=(ZoneAllocator<T2> const&) const
    {
        return false;
    }
};

} // HMDMMapAllocator

#endif /* hmd_mmap_memory_allocator_h */
