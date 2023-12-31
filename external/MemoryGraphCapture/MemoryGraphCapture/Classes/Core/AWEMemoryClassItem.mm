//
//  AWEMemoryClassItem.mm
//  MemoryGraphCapture-Pods-Aweme
//
//  Created by brent.shu on 2020/2/10.
//

#import "AWEMemoryClassItem.hpp"
#import "AWEMemoryGraphUtils.hpp"

namespace MemoryGraph {

static const size_t CF_TYPE_HASH_OFFSET = 300;

MemoryClassItemKey::MemoryClassItemKey(const void *ptr, Class cls, const VMInfo &vm_info): m_size(vm_info.size) {
    if (cls) {
        if (is_cf_cls(cls)) {
            m_cls_hash_code = CFGetTypeID((CFTypeRef)ptr) + CF_TYPE_HASH_OFFSET;
        } else {
            m_cls_hash_code = (size_t)(uintptr_t)cls;
        }
    } else {
        m_cls_hash_code = vm_info.type;
        if (vm_info.type == Heap) {
            auto vtable = vtable_of_cpp_object(ptr);
            if (vtable) {
                m_cls_hash_code = (size_t)(uintptr_t)vtable;
            }
        }
    }
}

void
MemoryClassItemKey::set_name(const ZONE_STRING &name) {
    m_name = name;
}
MemoryClassItem::MemoryClassItem(const VMInfo &vm_info, Class cls, const void *instance):
m_cls(cls), m_vm_info(vm_info), m_count(1), m_type_id(0), m_is_cf(false), m_vtable(0) {
    if (cls) {
        m_type = MemoryNodeType::Oc;
        if (is_cf_cls(cls)) {
            m_type_id = CFGetTypeID((CFTypeRef)instance);
            m_is_cf = true;
        }
    } else {
        auto vtable = vtable_of_cpp_object(instance);
        if (vtable) {
            m_vtable = vtable;
            m_type = MemoryNodeType::Cpp;
        } else {
            m_type = MemoryNodeType::StructOrBuffer;
        }
    }
}

void
MemoryClassItem::add_count() {
    ++m_count;
}

ZONE_STRING
MemoryClassItem::cls_name() {
    if (m_cls) {
        if (m_is_cf && is_valid_cftype_id(m_type_id)) {
            auto desc = CFCopyTypeIDDescription(m_type_id);
            auto desc_len = desc ? CFStringGetLength(desc) : 0;
            auto desc_char = "__NSCFType";
            if (desc_len) {
                char *buffer = (char *)malloc_zone_calloc(g_malloc_zone(), desc_len + 1, sizeof(char)); // not need to free
                if (CFStringGetCString(desc, buffer, desc_len + 1, kCFStringEncodingUTF8)) {
                    desc_char = buffer;
                }
            }
            if (desc) CFRelease(desc);
            return desc_char;
        } else {
            return class_getName(m_cls) ?: "";
        }
    } else if (m_vtable) {
        return name_of_vtable(m_vtable).c_str();
    } else if (m_name.length()>0) {
        return m_name;
    }
    return "";
}

#define MAIN_ITEM_TYPE_BYTE 1 // 1byte for item type

#define ITEM_VM_SIZE_BYTE 4 // 4 byte for vm size
#define ITEM_VM_TYPE_BYTE 1 // 1 byte for vm type
#define ITEM_TYPE_BYTE 1 // 1 byte for type
#define ITEM_COUNT_BYTE 4 // 4 byte for count
#define ITEM_CLASS_LEN_BYTE 2 // 4 byte for cls index

size_t
MemoryClassItem::serialized_size() {
    return MAIN_ITEM_TYPE_BYTE + ITEM_VM_SIZE_BYTE + ITEM_VM_TYPE_BYTE + ITEM_TYPE_BYTE + ITEM_COUNT_BYTE + ITEM_CLASS_LEN_BYTE + cls_name().size();
}

void
MemoryClassItem::write_to(Writer &writer) {
    MainItemType type = MainItemType::ClassItem;
    writer.append(&type, MAIN_ITEM_TYPE_BYTE);
    
    writer.append(&m_vm_info.size, ITEM_VM_SIZE_BYTE);
    writer.append(&m_vm_info.type, ITEM_VM_TYPE_BYTE);
    writer.append(&m_type, ITEM_TYPE_BYTE);
    writer.append(&m_count, ITEM_COUNT_BYTE);
    
    auto symbol = cls_name();
    auto len = symbol.size();
    writer.append(&len, ITEM_CLASS_LEN_BYTE);
    if (len) {
        writer.append(symbol.c_str(), len);
    }
}

void
MemoryClassItem::set_name(const ZONE_STRING &name) {
    m_name = name;
}
}

