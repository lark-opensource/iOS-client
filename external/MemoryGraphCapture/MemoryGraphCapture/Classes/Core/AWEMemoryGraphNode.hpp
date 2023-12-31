//
//  AWEMemoryGraphNode.hpp
//  Hello
//
//  Created by brent.shu on 2019/10/20.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#ifndef AWEMemoryGraphNode_hpp
#define AWEMemoryGraphNode_hpp

#import "MemoryGraphVMHelper.hpp"
#import "AWEMemoryNodeCursor.hpp"
#import "AWEMemoryGraphWriter.hpp"

#import <vector>
#import <string>

namespace MemoryGraph {

enum MainItemType: uint8_t {
    NodeItem = 0,
    EdgeItem = 1,
    ClassItem = 2,
};

enum IvarValueType: uint8_t {
    Offset = 0,
    NameIdx = 1
};

class MemoryGraphEdge {
    void *m_from;
    void *m_to;
    int32_t m_ivar_name_idx;
    uint32_t m_value;
    IvarValueType m_value_type;
    MemoryReferenceType m_ref_type;
public:
    const bool is_valid;
    
    MemoryGraphEdge(void *from, void *to, size_t offset, MemoryReferenceType ref_type, int32_t ivar_idx, bool is_valid);
    
    size_t serialized_size();
    
    void write_to(Writer &writer);
};

class MemoryGraphNode {
    void  *m_raw_ptr;
    VMInfo m_vm_info;
    int32_t m_cls_idx: 24;
    MemoryNodeType m_type;
    size_t m_offset;
    
    void m_block_init();
public:
    // whole user space
    MemoryGraphNode();
    
    // for a memory area
    MemoryGraphNode(void *ptr, const ZONE_STRING &area_name, VMInfo vm_info);
    
    // for a root pointer
    MemoryGraphNode(void *ptr);
    
    // for a root pointer with vm_info
    MemoryGraphNode(void *ptr, VMInfo vm_info);
    
    MemoryGraphNode(void *ptr, size_t offset, VMInfo vm_info);
    
    MemoryGraphNode(void *ptr, VMInfo vm_info, Class cls);
    
    //for chache/rwt node
    MemoryGraphNode(void *ptr,MemoryNodeType type);
    
    void update_cls_idx(int32_t idx);
    
    void find_child(const std::function<void (MemoryGraphNode *node, const ZONE_STRING &cus_cls, MemoryGraphEdge &edge, bool &stop)> &call_back);
    
    MemoryNodeType node_type();
    
    VMInfo vm_info();
    
    void *raw_ptr();
    
    size_t serialized_size();
    
    void write_to(Writer &writer);
};

} // MemoryGraph

#endif /* AWEMemoryGraphNode_h */
