//
//  HMDClassCoverageDefine.h
//  Pods
//
//  Created by kilroy on 2020/6/10.
//

#ifndef HMDClassCoverageDefine_h
#define HMDClassCoverageDefine_h

// class is unrealized future class - must  never be set by compiler
#define RW_INITIALIZED             (1<<29)
// class is unrealized future class - must never be set by compiler
#define RO_FUTURE             (1<<30)
// 类已实化
// class is realized - must never be set by compiler
#define RO_REALIZED           (1<<31)

// class_t->data is class_rw_t, not class_ro_t
#define RW_REALIZED           (1<<31)
// class is unresolved future class
#define RW_FUTURE             (1<<30)

#define FAST_DATA_MASK          0x00007ffffffffff8UL

typedef struct v_objc_class *V_Class;
typedef unsigned long v_uintptr_t;
typedef v_uintptr_t v_cache_key_t;
typedef uint32_t v_mask_t;
typedef v_uintptr_t v_protocol_ref_t;

struct v_bucket_t {
    IMP _imp;
    v_cache_key_t _key;
};

struct v_cache_t {
    struct v_bucket_t *_buckets;
    v_mask_t _mask;
    v_mask_t _occupied;
};

union v_isa_t {
    V_Class cls;
    v_uintptr_t bits;
};

struct v_objc_object {
    v_isa_t isa;
};

template <typename Element, typename List, uint32_t FlagMask>
struct v_entsize_list_tt {
    uint32_t entsizeAndFlags;
    uint32_t count;
    Element first;
};

struct v_method_t {
    SEL name;
    const char *types;
    IMP imp;
};

struct v_method_list_t : v_entsize_list_tt<v_method_t, v_method_list_t, 0x3> {
};

struct v_protocol_list_t {
    uintptr_t count;
};

struct v_ivar_t {
    int32_t *offset;
    const char *name;
    const char *type;
    // alignment is sometimes -1; use alignment() instead
    uint32_t alignment_raw;
    uint32_t size;
};

struct v_ivar_list_t : v_entsize_list_tt<v_ivar_t, v_ivar_list_t, 0> {
};

struct v_property_t {
    const char *name;
    const char *attributes;
};

struct v_property_list_t : v_entsize_list_tt<v_property_t, v_property_list_t, 0> {
};

struct v_class_ro_t {
    uint32_t flags;
    uint32_t instanceStart;
    uint32_t instanceSize;
    uint32_t reserved;

    const uint8_t * ivarLayout;

    const char * name;
    v_method_list_t * baseMethodList;
    v_protocol_list_t*** * baseProtocols;
    const v_ivar_list_t * ivars;

    const uint8_t * weakIvarLayout;
    v_property_list_t *baseProperties;
};

template <typename Element, typename List>
class v_list_array_tt {
    union {
        List* list;
        v_uintptr_t arrayAndFlag;
    };
};

class v_method_array_t :
public v_list_array_tt<v_method_t, v_method_list_t>
{
};

class v_property_array_t :
public v_list_array_tt<v_property_t, v_property_list_t>
{
};

class v_protocol_array_t :
public v_list_array_tt<v_protocol_ref_t, v_protocol_list_t>
{
};

struct v_class_rw_t {
    uint32_t flags;
    uint32_t version;

    const v_class_ro_t *ro;

    v_method_array_t methods;
    v_property_array_t properties;
    v_protocol_array_t protocols;
};

struct v_class_data_bits_t {
    v_uintptr_t bits;

    v_class_rw_t* data() {
        return (v_class_rw_t *)(bits & FAST_DATA_MASK);
    }
};

struct v_objc_class : v_objc_object {
    V_Class superclass;
    v_cache_t cache;
    v_class_data_bits_t bits;

    v_class_rw_t *data() {
        return bits.data();
    }
    bool isInitialized() {
         return data()->flags & RW_INITIALIZED;
   }
    uint32_t meta_flag() {
        return data()->flags;
    }
};


#endif /* HMDClassCoverageDefine_h */
