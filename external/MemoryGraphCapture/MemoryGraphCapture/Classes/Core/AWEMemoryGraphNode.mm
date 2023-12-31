//
//  AWEMemoryGraphNode.mm
//  Hello
//
//  Created by brent.shu on 2019/10/22.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#import "AWEMemoryGraphNode.hpp"
#import "AWEMachOImageHelper.hpp"
#import "AWEMemoryGraphUtils.hpp"

#import <Foundation/Foundation.h>

namespace MemoryGraph {

void
MemoryGraphNode::find_child(const std::function<void (MemoryGraphNode *node, const ZONE_STRING &cus_cls, MemoryGraphEdge &edge, bool &stop)> &call_back) {
    bool stop = false;
    if (m_type == MemoryNodeType::UserSpace) {
        auto node_cache = MemoryGraphNode((void *)0x1,MemoryNodeType::TransferToCache);
        auto edge_cache = MemoryGraphEdge(m_raw_ptr, node_cache.raw_ptr(), 0,  MemoryReferenceType::Assign, -1, true);
        call_back(&node_cache, "Only_for_cache", edge_cache, stop);

        auto node_rwt = MemoryGraphNode((void *)0x2,MemoryNodeType::TransferToRwt);
        auto edge_rwt = MemoryGraphEdge(m_raw_ptr, node_rwt.raw_ptr(), 0,  MemoryReferenceType::Assign, -1, true);
        call_back(&node_rwt, "Only_for_rwt", edge_rwt, stop);

        ZONE_VECTOR(ImageSegment) data_segs;
        getSections(SEG_DATA, data_segs);
        for (auto seg = data_segs.begin(); seg != data_segs.end(); ++seg) {
            if (strstr(seg->name().c_str(), "__DATA_CONST")) {
                continue;
            }
            
            auto &sections = seg->sections();
            for (auto secIt = sections.begin(); secIt != sections.end(); ++secIt) {
                auto sec = *secIt;
                auto node = MemoryGraphNode(sec.range().first,
                                            "",
                                            {sec.range().second, Segment});
                auto edge = MemoryGraphEdge(m_raw_ptr, node.raw_ptr(), 0,  MemoryReferenceType::Assign, -1, true);
                call_back(&node, seg->name() + " " + sec.name(), edge, stop);
                
                if (stop) {
                    break;
                }
            }
            if (stop) {
                break;
            }
        }
    } else if (m_type  == MemoryNodeType::TransferToCache) {
        ZONE_SET(uintptr_t)* cls_cache = cls_cache_ptr_helper();
        for(auto iter = cls_cache->begin();iter != cls_cache->end();++iter) {
            auto edge = MemoryGraphEdge(m_raw_ptr, (void *)*iter, 0,  MemoryReferenceType::Assign, -1, true);
            call_back(nullptr,"",edge,stop);
            if (stop) break;
        }
    } else if (m_type  == MemoryNodeType::TransferToRwt) {
        ZONE_SET(uintptr_t)* rwt_ptr = cls_rwt_ptr_helper();
        for(auto iter = rwt_ptr->begin();iter != rwt_ptr->end();++iter) {
            auto edge = MemoryGraphEdge(m_raw_ptr, (void *)*iter, 0,  MemoryReferenceType::Assign, -1, true);
            call_back(nullptr,"",edge,stop);
            if (stop) break;

        }
    } else if (m_type == MemoryNodeType::Oc) {
        id object = (__bridge id)m_raw_ptr;
        auto cursor = MemoryOcNodeCursor(object, m_offset, m_vm_info.size);
        while (true) {
            auto next_ref = cursor.next_ref();
            if (!next_ref.is_valid) {
                break;
            }
            
            call_back(nullptr, "", next_ref, stop);
            if (stop) {
                break;
            }
        }
    } else if (m_type == MemoryNodeType::MemoryArea && cls_cache_ptr_helper()->size()) {
        auto cursor = MemoryNodeCursor(m_raw_ptr, m_offset, m_vm_info.size);
        while (true) {
            auto next_ref = cursor.next_ref_segment();
            if (!next_ref.is_valid) {
                break;
            }
            
            call_back(nullptr, "", next_ref, stop);
            if (stop) {
                break;
            }
        }
    } else {
        ZONE_SET(uintptr_t)* rwt_ptr = cls_rwt_ptr_helper();
        //如果是class_rw_t则单独处理，ios14以上版本class_rw_ext_t对应dirty memory
        if(rwt_ptr->find((uintptr_t)m_raw_ptr) != rwt_ptr->end()) {
            uint8_t *m_ptr = (uint8_t *)m_raw_ptr;
            void *potential_ptr = *(uint8_t **)(m_ptr+8);
            uintptr_t tmp_ptr = (uintptr_t)potential_ptr;
            void *m_rw_ext_t_ptr = nullptr;
            if(((uintptr_t)potential_ptr & 1) == 1) {//判断最后一位是否为1,如果是1则表示为heap=class_rw_ext_t
                tmp_ptr = (uintptr_t)potential_ptr & (~1);//最后一位置0为真实地址
                m_rw_ext_t_ptr = (void *)tmp_ptr;
            }
            auto next_ref = MemoryGraphEdge(m_raw_ptr, (void *)tmp_ptr, 8, MemoryReferenceType::Assign, -1, true);
            call_back(nullptr, "", next_ref, stop);
            if(m_rw_ext_t_ptr != nullptr) {
                uintptr_t addr = (uintptr_t)m_rw_ext_t_ptr;
                int count = 1;
                while(count <= 3) {
                    int ptr_offset = count*8;
                    count++;
                    void *potential_ptr = *(void **)(addr+ptr_offset);
                    uintptr_t ptr_fix = (uintptr_t)potential_ptr;
                    if(((uintptr_t)potential_ptr & 1) == 1) {
                        ptr_fix = (uintptr_t)potential_ptr & (~1);
                    }
                    auto next_ref = MemoryGraphEdge(m_raw_ptr, (void *)ptr_fix, ptr_offset, MemoryReferenceType::Assign, -1, true);
                    call_back(nullptr, "", next_ref, stop);
                }
            }
        } else {
            auto cursor = MemoryNodeCursor(m_raw_ptr, m_offset, m_vm_info.size);
            while (true) {
                auto next_ref = cursor.next_ref();
                if (!next_ref.is_valid) {
                    break;
                }
                
                call_back(nullptr, "", next_ref, stop);
                if (stop) {
                    break;
                }
            }
        }
    }
}

void MemoryGraphNode::m_block_init() {
    if (!m_vm_info.size) {
        return ;
    }
    
    if (!m_type) {
        m_type = MemoryNodeType::StructOrBuffer;
        if (m_vm_info.type == Heap) {
            auto cpp_idx = str_index_of_cpp_object(m_raw_ptr);
            if (cpp_idx != -1) {
                m_type = MemoryNodeType::Cpp;
                m_cls_idx = cpp_idx;
            }
        }
    }
}

MemoryGraphNode::MemoryGraphNode():
m_vm_info({0, VMInfoType::Process}),
m_cls_idx(-1),
m_type(MemoryNodeType::UserSpace),
m_raw_ptr(nullptr),
m_offset(0)
{
}

MemoryGraphNode::MemoryGraphNode(void *ptr):
m_cls_idx(-1),
m_type(MemoryNodeType::Nothing),
m_raw_ptr(ptr),
m_vm_info(vm_info_of_ptr(m_raw_ptr)),
m_offset(0)
{
    m_block_init();
}

MemoryGraphNode::MemoryGraphNode(void *ptr,MemoryNodeType type):
m_cls_idx(-1),
m_type(type),
m_raw_ptr(ptr),
m_vm_info({0,VMInfoType::ClassHelper}),
m_offset(0)
{

}

MemoryGraphNode::MemoryGraphNode(void *ptr, VMInfo vm_info):
m_vm_info(vm_info),
m_cls_idx(-1),
m_type(MemoryNodeType::Nothing),
m_raw_ptr(ptr),
m_offset(0)
{
    m_block_init();
}

MemoryGraphNode::MemoryGraphNode(void *ptr, size_t offset, VMInfo vm_info):
m_vm_info(vm_info),
m_cls_idx(-1),
m_type(MemoryNodeType::Nothing),
m_raw_ptr(ptr),
m_offset(offset)
{
    m_block_init();
}

MemoryGraphNode::MemoryGraphNode(void *ptr, VMInfo vm_info, Class cls):
m_vm_info(vm_info),
m_cls_idx(index_of_cls(cls, ptr)),
m_type(MemoryNodeType::Oc),
m_raw_ptr(ptr),
m_offset(0)
{
}

MemoryGraphNode::MemoryGraphNode(void *ptr, const ZONE_STRING &area_name, VMInfo vm_info):
m_vm_info(vm_info),
m_cls_idx(-1),
m_type(MemoryNodeType::MemoryArea),
m_raw_ptr(ptr),
m_offset(0)
{
}

MemoryNodeType MemoryGraphNode::node_type() {
    return m_type;
}

VMInfo MemoryGraphNode::vm_info() {
    return m_vm_info;
}

void *
MemoryGraphNode::raw_ptr() {
    return m_raw_ptr;
}

void MemoryGraphNode::update_cls_idx(int32_t idx) {
    m_cls_idx = idx;
}

#define MAIN_ITEM_TYPE_BYTE 1 // 1byte for item type

#define NODE_VM_SIZE_BYTE 4 // 4 byte for vm size
#define NODE_VM_TYPE_BYTE 1 // 1 byte for vm type
#define NODE_TYPE_BYTE 1 // 1 byte for type
#define NODE_PTR_BYTE sizeof(void *) // byte of ptr size
#define NODE_CLS_INDEX_BYTE 4 // 4 byte for cls index

size_t
MemoryGraphNode::serialized_size() {
    return MAIN_ITEM_TYPE_BYTE + NODE_VM_SIZE_BYTE + NODE_VM_TYPE_BYTE + NODE_TYPE_BYTE + NODE_PTR_BYTE + NODE_CLS_INDEX_BYTE;
}

void
MemoryGraphNode::write_to(Writer &writer) {
    MainItemType type = MainItemType::NodeItem;
    writer.append(&type, MAIN_ITEM_TYPE_BYTE);
    
    uint32_t size = m_vm_info.size;
    if (m_type == MemoryNodeType::MemoryArea) {
        size = 0;
    }
    writer.append(&size, NODE_VM_SIZE_BYTE);
    writer.append(&m_vm_info.type, NODE_VM_TYPE_BYTE);
    int32_t cls_idx = m_cls_idx;
    writer.append(&cls_idx, NODE_CLS_INDEX_BYTE);
    writer.append(&m_type, NODE_TYPE_BYTE);
    writer.append(&m_raw_ptr, NODE_PTR_BYTE);
}

MemoryGraphEdge::MemoryGraphEdge(void *from, void *to, size_t offset, MemoryReferenceType ref_type, int32_t ivar_idx, bool is_valid):
m_from(from),
m_to(to),
m_ref_type(ref_type),
m_ivar_name_idx(ivar_idx),
is_valid(is_valid) {
    if (ivar_idx != -1) {
        m_value_type = IvarValueType::NameIdx;
        m_value = ivar_idx;
    } else {
        m_value_type = IvarValueType::Offset;
        m_value = (uint32_t)offset;
    }
}

#define EDGE_FROM_BYTE sizeof(void *) // byte of ptr size
#define EDGE_TO_BYTE sizeof(void *) // byte of ptr size
#define EDGE_IVAR_VALUE_BYTE 4 // 4 byte for ivar value(ivar_name_len/offset)
#define EDGE_VALUE_TYPE_BYTE 1 // 1 byte for value type
#define EDGE_REF_TYPE_BYTE 1 // 1 byte for ref type

size_t
MemoryGraphEdge::serialized_size() {
    return MAIN_ITEM_TYPE_BYTE + EDGE_FROM_BYTE + EDGE_TO_BYTE + EDGE_IVAR_VALUE_BYTE + EDGE_VALUE_TYPE_BYTE + EDGE_REF_TYPE_BYTE;
}

void
MemoryGraphEdge::write_to(Writer &writer) {
    MainItemType type = MainItemType::EdgeItem;
    writer.append(&type, MAIN_ITEM_TYPE_BYTE);
    
    writer.append(&m_from, EDGE_FROM_BYTE);
    writer.append(&m_to, EDGE_TO_BYTE);
    writer.append(&m_ref_type, EDGE_REF_TYPE_BYTE);
    writer.append(&m_value, EDGE_IVAR_VALUE_BYTE);
    writer.append(&m_value_type, EDGE_VALUE_TYPE_BYTE);
}

} // MemoryGraph
