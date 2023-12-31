//
//  AWEMemoryNodeCursor.mm
//  Hello
//
//  Created by brent.shu on 2019/10/22.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#import "AWEMemoryNodeCursor.hpp"
#import "AWEMemoryGraphUtils.hpp"
#import "AWEMemoryGraphNode.hpp"
#import "AWEMemoryGraphTimeChecker.hpp"

#import <unordered_map>

namespace MemoryGraph {

MemoryNodeCursor::MemoryNodeCursor(void *ptr, size_t offset, size_t max_cursor):
m_ptr((uint8_t *)ptr), m_cursor_left(max_cursor), m_offset(offset) {
}

const MemoryGraphEdge &
MemoryNodeCursor::next_ref_segment() {
    while (m_cursor_left >= 8) {
        void *potential_ptr = *((uint8_t **)(m_ptr + m_offset));
        auto offset_now = m_offset;
        CFMutableDictionaryRef cls_ptr = cls_ptr_helper();
        if (CFDictionaryContainsKey(cls_ptr,potential_ptr)) {//如果是oc类不进行8字节扫描
            int size = 40;
            m_offset += size;
            m_cursor_left -= size;
            continue;
        }
        m_offset += sizeof(void *);
        m_cursor_left -= sizeof(void *);
        if (is_potential_ptr(potential_ptr)) {
            auto ptr = (void *)potential_ptr; // fixed ptr
            auto vm_info = vm_info_of_ptr(ptr);
            if (vm_info.size) {
                if (MemoryGraphTimeChecker.nodeCheckPoint("time out when analysis node")) {
                    break;
                }
                return MemoryGraphEdge(m_ptr, ptr, offset_now, MemoryReferenceType::Assign, -1, true);
            }
        }
    }
    return MemoryGraphEdge(nullptr, nullptr, 0, MemoryReferenceType::Assign, -1, false);
}
const MemoryGraphEdge &
MemoryNodeCursor::next_ref() {
    while (m_cursor_left >= sizeof(void *)) {
        void *potential_ptr = *((uint8_t **)(m_ptr + m_offset));
        auto offset_now = m_offset;
        m_offset += sizeof(void *);
        m_cursor_left -= sizeof(void *);
        
        if (is_potential_ptr(potential_ptr)) {
            auto ptr = (void *)potential_ptr; // fixed ptr
            auto vm_info = vm_info_of_ptr(ptr);
            if (vm_info.size) {
                if (MemoryGraphTimeChecker.nodeCheckPoint("time out when analysis node")) {
                    break;
                }
                return MemoryGraphEdge(m_ptr, ptr, offset_now, MemoryReferenceType::Assign, -1, true);
            }
        }
    }
    return MemoryGraphEdge(nullptr, nullptr, 0, MemoryReferenceType::Assign, -1, false);
}

OCIvar::OCIvar(Ivar ivar, MemoryReferenceType ref_type) {
    m_ref_type = ref_type;
    m_offset = ivar_getOffset(ivar);
    m_name_idx = index_of_str(ivar_getName(ivar) ?: "");
    
    auto type = ivar_getTypeEncoding(ivar);
    if (type == nullptr || strlen(type) == 0) {
        m_type = Unknown;
    } else if (type[0] == '{') {
        m_type = Struct;
    } else if (type[0] == '@') {
        if (strncmp(type, "@?", 2) == 0) {
            m_type = Block;
        } else {
            m_type = Object;
        }
    } else if (strstr(type, "^{") != nullptr) {
        m_type = StructPtr;
    } else if (strstr(type, "^") != nullptr || type[0] == '*') {
        m_type = RawValuePtr;
    } else if (type[0] == 'q' || type[0] == 'L' || type[0] == 'Q' || type[0] == 'l') {//long\long long\unsigned long\unsigned long long
        m_type = RawValueFromPtr;
    } else {
        m_type = RawValue;
    }
}

OCIvarType
OCIvar::type() {
    return m_type;
}

MemoryReferenceType
OCIvar::ref_type() {
    return m_ref_type;
}

const int32_t &
OCIvar::name() {
    return m_name_idx;
}

size_t
OCIvar::offset() {
    return m_offset;
}

size_t OCClassIvarsInfo::m_get_min_ivar_index(Ivar *ivars, unsigned int count) {
    size_t min_index = 1;
    
    if (count > 0) {
        Ivar ivar = ivars[0];
        ptrdiff_t offset = ivar_getOffset(ivar);
        min_index = offset / (sizeof(void *));
    }
    
    return min_index;
}

void OCClassIvarsInfo::m_get_layouts(ZONE_SET(size_t) &output,
                                     Ivar *ivars,
                                     unsigned int count,
                                     Class cls,
                                     bool getWeak) {
    auto current_index = m_get_min_ivar_index(ivars, count);
    auto layout_description = getWeak ? class_getWeakIvarLayout(cls) : class_getIvarLayout(cls);
    
    // null if no strong/weak ref
    if (!layout_description) {
        return ;
    }
    
    while (*layout_description != '\x00') {
        int upper_nibble = (*layout_description & 0xf0) >> 4;
        int lower_nibble = *layout_description & 0xf;
        
        // Upper nimble is for skipping
        current_index += upper_nibble;
        
        // Lower nimble describes count
        
        for (auto i = 0; i < lower_nibble; ++i) {
            output.insert(current_index + i);
        }
        
        current_index += lower_nibble;
        
        ++layout_description;
    }
}

void OCClassIvarsInfo::m_append_ivars(Class cls) {
    unsigned int count = 0;
    // fetch all ivar
    Ivar *ivar_ptr = class_copyIvarList(cls, &count);
    Ivar *ivar_it = ivar_ptr;
    
    if (!ivar_ptr) {
        return ;
    }
    
    // caculate strong ivar layout
    ZONE_SET(size_t) strong_ivars;
    m_get_layouts(strong_ivars, ivar_ptr, count, cls, false);
    ZONE_SET(size_t) weak_ivars;
    m_get_layouts(weak_ivars, ivar_ptr, count, cls, true);
    
    while (count) {
        auto offset = ivar_getOffset(*ivar_it);
        bool is_strong = strong_ivars.find((offset / sizeof(void *))) != strong_ivars.end();
        bool is_weak = weak_ivars.find((offset / sizeof(void *))) != weak_ivars.end();
        m_ivars.push_back(OCIvar(*ivar_it, is_strong ? MemoryReferenceType::Strong : (is_weak ? MemoryReferenceType::Weak : MemoryReferenceType::Assign)));
        if (is_strong) {
            m_strong_objects.push_back(offset);
        } else if (is_weak) {
            m_weak_objects.push_back(offset);
        }
        
        ++ivar_it;
        --count;
    }
    
    m_ivars.shrink_to_fit();
    m_strong_objects.shrink_to_fit();
    m_weak_objects.shrink_to_fit();
    
    free(ivar_ptr);
}

OCClassIvarsInfo::OCClassIvarsInfo(Class cls): m_strong_objects(), m_weak_objects(), m_ivars(), m_super(nullptr) {
    m_append_ivars(cls);
    
    auto superCls = class_getSuperclass(cls);
    if (superCls && superCls != cls) {
        m_super = ivar_info_of_class(superCls);
    }
}

int32_t
OCClassIvarsInfo::get_ivar_name(size_t offset) {
    for (auto it = m_ivars.begin(); it != m_ivars.end(); ++it) {
        if (it->offset() == offset) {
            OCIvarType ivar_type = it->type();
            if(ivar_type == RawValue) {
                return -2;
            } else {
                return it->name();
            }
        }
    }
    
    return m_super ? m_super->get_ivar_name(offset) : -1;
}

bool
OCClassIvarsInfo::is_strong_ivar(size_t offset) {
    for (auto it = m_strong_objects.begin(); it != m_strong_objects.end(); ++it) {
        if (*it == offset) {
            return true;
        }
    }
    
    return m_super ? m_super->is_strong_ivar(offset) : false;
}

bool
OCClassIvarsInfo::is_weak_ivar(size_t offset) {
    for (auto it = m_weak_objects.begin(); it != m_weak_objects.end(); ++it) {
        if (*it == offset) {
            return true;
        }
    }
    return m_super ? m_super->is_weak_ivar(offset) : false;
}

using CACHE_TYPE = ZONE_HASH(uintptr_t, OCClassIvarsInfo *);
static CACHE_TYPE *ivar_info_cache;

OCClassIvarsInfo *ivar_info_of_class(Class cls) {
    if (!ivar_info_cache) {
        void *ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(CACHE_TYPE));
        ivar_info_cache = new(ptr) CACHE_TYPE;
    }
    
    auto it = ivar_info_cache->find((uintptr_t)cls);
    if (it != ivar_info_cache->end()) {
        return it->second;
    } else {
        void *ptr = malloc_zone_malloc(g_malloc_zone(), sizeof(OCClassIvarsInfo));
        OCClassIvarsInfo *s = new(ptr) OCClassIvarsInfo(cls);
        ivar_info_cache->insert({(uintptr_t)cls, s});
        return s;
    }
}

MemoryOcNodeCursor::MemoryOcNodeCursor(id object, size_t offset, size_t max_cursor):
m_ptr((uint8_t *)((__bridge void *)object)), m_cursor_left(max_cursor), m_offset(offset),
ivar_info(ivar_info_of_class(object_getClass(object))) {
}

const MemoryGraphEdge &
MemoryOcNodeCursor::next_ref() {
    while (m_cursor_left >= sizeof(void *)) {
        void *potential_ptr = *((uint8_t **)(m_ptr + m_offset));
        auto offset_now = m_offset;
        m_offset += sizeof(void *);
        m_cursor_left -= sizeof(void *);
        
        if (is_potential_ptr(potential_ptr)) {
            auto ptr = (void *)potential_ptr; // fixed ptr
            auto vm_info = vm_info_of_ptr(ptr);
            if (vm_info.size) {
                if (MemoryGraphTimeChecker.nodeCheckPoint("time out when analysis OC node")) {
                    break;
                }
                auto ivar_name = ivar_info->get_ivar_name(offset_now);
                if (ivar_name == -2) {//-2：该类型属性无法建立正确的引用关系，如BOOL类型
                    continue;
                } else if (ivar_name != -1) {//-1：非属性offset，如struct中成员变量
                    mark_used_str_idx(ivar_name);
                }
                bool is_strong = ivar_info->is_strong_ivar(offset_now);
                bool is_weak = ivar_info->is_weak_ivar(offset_now);
                return MemoryGraphEdge(m_ptr,
                                       ptr,
                                       offset_now,
                                       is_strong ? MemoryReferenceType::Strong : (is_weak ? MemoryReferenceType::Weak : MemoryReferenceType::Assign),
                                       ivar_name,
                                       true);
            }
        }
    }
    return MemoryGraphEdge(nullptr, nullptr, 0, MemoryReferenceType::Assign, -1, false);
}

void ivar_cache_push_class(Class cls) {
    if (!cls) {
        return ;
    }
    ivar_info_of_class(cls);
}

void clear_ivar_cache() {
    if (ivar_info_cache) {
        ivar_info_cache = nullptr;
        // do not need delete ivar info explicate, malloc_zone_destory will clean them
    }
}

} // MemoryGraph
