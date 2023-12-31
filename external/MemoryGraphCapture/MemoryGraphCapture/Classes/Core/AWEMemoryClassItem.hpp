//
//  AWEMemoryClassItem.hpp
//  MemoryGraphCapture-Pods-Aweme
//
//  Created by brent.shu on 2020/2/10.
//

#ifndef AWEMemoryClassItem_hpp
#define AWEMemoryClassItem_hpp

#import "AWEMemoryAllocator.hpp"
#import "MemoryGraphVMHelper.hpp"
#import "AWEMemoryGraphWriter.hpp"
#import "AWEMemoryGraphNode.hpp"

#import <string>

namespace MemoryGraph {

class MemoryClassItemKey {
    size_t m_cls_hash_code;
    size_t m_size;
    ZONE_STRING m_name;
public:
    MemoryClassItemKey(const void *ptr, Class cls, const VMInfo &vm_info);
    
    bool operator==(const MemoryClassItemKey& p) const {
        return m_cls_hash_code == p.m_cls_hash_code && m_size == p.m_size && m_name == p.m_name;
    }
    
    friend class MemoryClassItemKeyHasher;
    
    void set_name(const ZONE_STRING &name);
};

template <class T>
static void hash_combine(std::size_t& seed, const T& v)
{
    std::hash<T> hasher;
    seed ^= hasher(v) + 0x9e3779b9 + (seed<<6) + (seed>>2);
}

class MemoryClassItemKeyHasher {
public:
    size_t operator()(const MemoryClassItemKey& p) const
    {
        std::size_t seed = 0;
        hash_combine<size_t>(seed, p.m_cls_hash_code);
        hash_combine<size_t>(seed, p.m_size);
        hash_combine<ZONE_STRING>(seed, p.m_name);
        return seed;
    }
};

class MemoryClassItem {
    Class m_cls;
    uintptr_t m_vtable;
    CFTypeID m_type_id;
    VMInfo m_vm_info;
    uint32_t m_count;
    MemoryNodeType m_type;
    bool m_is_cf;
    ZONE_STRING m_name;
public:
    MemoryClassItem(const VMInfo &vm_info, Class cls, const void *instance);
    
    // invoke outside suspend env
    ZONE_STRING cls_name();
    
    void add_count();
    
    size_t serialized_size();
    
    void write_to(Writer &writer);
    
    void set_name(const ZONE_STRING &name);
};

}

#endif /* AWEMemoryClassItem_hpp */
