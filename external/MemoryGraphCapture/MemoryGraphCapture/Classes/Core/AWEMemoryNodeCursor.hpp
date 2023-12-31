//
//  AWEMemoryNodeCursor.hpp
//  Hello
//
//  Created by brent.shu on 2019/10/21.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#ifndef AWEMemoryNodeCursor_hpp
#define AWEMemoryNodeCursor_hpp

#import "AWEMemoryAllocator.hpp"
#import "MemoryGraphVMHelper.hpp"
#import <malloc/malloc.h>
#import <objc/runtime.h>
#import <memory>
#import <vector>
#import <string>
#import <unordered_set>

namespace MemoryGraph {

struct VMInfo;
class MemoryGraphEdge;

enum MemoryReferenceType: uint8_t {
    Assign = 1 << 0,
    Strong = 1 << 1,
    Weak = 1 << 2,
};

inline MemoryReferenceType operator| (MemoryReferenceType a, MemoryReferenceType b)
{
    return static_cast<MemoryReferenceType>(static_cast<uint8_t>(a) | static_cast<uint8_t>(b));
}

enum MemoryNodeType: uint8_t {
    Nothing, // 无效节点
    StructOrBuffer, // 结构体或基本数据类型
    Oc, // Objective-C 对象
    MemoryArea, // 一块内存区域
    UserSpace, // 用户内存空间
    Cpp, // virtual c++ object
    TransferToCache, //cache
    TransferToRwt   //rw_t
};

enum OCIvarType: uint8_t {
    RawValue,
    Struct,
    Object,
    Block,
    StructPtr,
    RawValuePtr,
    Unknown,
    RawValueFromPtr
};

class OCIvar {
    int32_t m_name_idx;
    OCIvarType m_type;
    MemoryReferenceType m_ref_type;
    size_t m_offset;
public:
    
    OCIvar(Ivar ivar, MemoryReferenceType ref_type);
    
    OCIvarType type();
    
    const int32_t &name();
    
    MemoryReferenceType ref_type();
    
    size_t offset();
};

class OCClassIvarsInfo {
    ZONE_VECTOR(OCIvar) m_ivars;
    ZONE_VECTOR(size_t) m_strong_objects;
    ZONE_VECTOR(size_t) m_weak_objects;
    OCClassIvarsInfo *m_super;
    
    size_t m_get_min_ivar_index(Ivar *ivars, unsigned int count);
    
    void m_get_layouts(ZONE_SET(size_t) &output,
                       Ivar *ivars,
                       unsigned int count, Class cls,
                       bool getWeak);
    
    void m_append_ivars(Class cls);
public:
    OCClassIvarsInfo(Class cls);
    
    int32_t get_ivar_name(size_t offset);
    bool is_strong_ivar(size_t offset);
    bool is_weak_ivar(size_t offset);
};

class MemoryNodeCursor {
    uint8_t *m_ptr;
    int m_offset;
    int m_cursor_left;
    void *m_rw_ext_t_ptr;
public:
    MemoryNodeCursor(void *ptr, size_t offset, size_t max_cursor);
    
    const MemoryGraphEdge &next_ref();
    
    const MemoryGraphEdge &next_ref_segment();
};

class MemoryOcNodeCursor {
    OCClassIvarsInfo *ivar_info;
    
    uint8_t *m_ptr;
    size_t m_offset;
    size_t m_cursor_left;
public:
    MemoryOcNodeCursor(id object, size_t offset, size_t max_cursor);
    
    const MemoryGraphEdge &next_ref();
};

OCClassIvarsInfo *ivar_info_of_class(Class cls);

void clear_ivar_cache();

void ivar_cache_push_class(Class cls);

} // MemoryGraph

#endif /* AWEMemoryNodeCursor_hpp */
