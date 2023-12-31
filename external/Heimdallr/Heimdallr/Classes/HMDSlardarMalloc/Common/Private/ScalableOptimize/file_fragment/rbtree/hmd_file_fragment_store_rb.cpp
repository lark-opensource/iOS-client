//
//  file_fragment_store_rb.cpp
//  FileFragment
//
//  Created by zhouyang11 on 2022/1/24.
//

#include "hmd_file_fragment.h"
#include "hmd_file_fragment_store_rb.h"
#include "hmd_virtual_memory_macro.h"
#include "HMDMacro.h"

#define VME_FOR_STORE(store, type)   \
    (file_map_entry_t)(((unsigned long)store) - ((unsigned long)sizeof(struct file_map_links)) - (type==rb_tree_type_size?((unsigned long)sizeof(struct file_map_store)):0))

namespace HMDMemoryAllocator {

int
rb_node_compare_size(struct file_map_store *node, struct file_map_store *parent)
{
    file_map_entry_t vme_c;
    file_map_entry_t vme_p;

    vme_c = VME_FOR_STORE(node, rb_tree_type_size);
    vme_p =  VME_FOR_STORE(parent, rb_tree_type_size);
    if (vme_c->vme_length < vme_p->vme_length) {
        return -1;
    }
    if (vme_c->vme_length > vme_p->vme_length) {
        return 1;
    }
    return 0;
}

int
rb_node_compare_addr(struct file_map_store *node, struct file_map_store *parent)
{
    file_map_entry_t vme_c;
    file_map_entry_t vme_p;

    vme_c = VME_FOR_STORE(node, rb_tree_type_addr);
    vme_p =  VME_FOR_STORE(parent, rb_tree_type_addr);
    if (DECODE_ENTRY_ADDR(vme_c) < DECODE_ENTRY_ADDR(vme_p)) {
        return -1;
    }
    if (DECODE_ENTRY_ADDR(vme_c) >= (DECODE_ENTRY_ADDR(vme_p)+vme_p->vme_length)) {
        return 1;
    }
    return 0;
}

RB_GENERATE(rb_size_head, file_map_store, entry, rb_node_compare_size);
RB_GENERATE(rb_addr_head, file_map_store, entry, rb_node_compare_addr);

void file_map_store_init_rb(file_map_header_t mapHdr) {
    RB_INIT(&(mapHdr->rb_size_head_store));
    RB_INIT(&(mapHdr->rb_addr_head_store));
}

bool
file_map_store_lookup_entry_rb(file_map_header_t mapHdr, uintptr_t factor, file_map_entry_t *vm_entry, file_map_entry_t *vm_entry_prev, file_map_entry_t *vm_entry_next, rb_tree_type tree_type)
{
    struct file_map_store  *rb_entry;
    
    if (tree_type == rb_tree_type_addr) {
        rb_entry = RB_ROOT(&(mapHdr->rb_addr_head_store));
        file_map_entry_t       cur = VME_FOR_STORE(rb_entry, tree_type);
        file_map_entry_t       prev = FILE_MAP_ENTRY_NULL;
        file_map_entry_t       next = FILE_MAP_ENTRY_NULL;
        
        uintptr_t address = factor;
        while (rb_entry != (struct file_map_store*)NULL) {
            cur =  VME_FOR_STORE(rb_entry, tree_type);
            if (cur == FILE_MAP_ENTRY_NULL) {
                ff_printf("no entry\n");
                ff_assert(0);
            }
            if (address >= DECODE_ENTRY_ADDR(cur)) {
                if (address < ENTRY_RIGHT_BOUNDRY(cur)) {
                    *vm_entry = cur;
                    return true;
                }
                rb_entry = RB_RIGHT(rb_entry, entry);
                prev = cur;
            } else {
                rb_entry = RB_LEFT(rb_entry, entry);
                next = cur;
            }
        }
        *vm_entry = FILE_MAP_ENTRY_NULL;
        if (vm_entry_prev != NULL) {
            *vm_entry_prev = prev;
        }
        if (vm_entry_next != NULL) {
            *vm_entry_next = next;
        }
        return false;
        
    }else {
        rb_entry = RB_ROOT(&(mapHdr->rb_size_head_store));
        file_map_entry_t       cur = VME_FOR_STORE(rb_entry, tree_type);
        file_map_entry_t       prev = FILE_MAP_ENTRY_NULL;
        size_t size = factor;
        
        while (rb_entry != (struct file_map_store*)NULL) {
            cur =  VME_FOR_STORE(rb_entry, tree_type);
            if (cur == FILE_MAP_ENTRY_NULL) {
                ff_printf("no entry\n");
                ff_assert(0);
            }
            if (size > cur->vme_length) {
                rb_entry = RB_RIGHT(rb_entry, entry);
            }else {
                prev = cur;
                rb_entry = RB_LEFT(rb_entry, entry);
            }
        }
        if (prev == FILE_MAP_ENTRY_NULL) {
//            prev = VME_FOR_STORE(rb_entry, tree_type);
            *vm_entry = prev;
            return false;
        }
        *vm_entry = prev;
        return true;
    }
}

void
file_map_store_entry_link_rb( struct file_map_header *mapHdr, __unused file_map_entry_t after_where, file_map_entry_t entry, rb_tree_type tree_type)
{
    if (tree_type == rb_tree_type_addr) {
        struct rb_addr_head *rbh = &(mapHdr->rb_addr_head_store);
        struct file_map_store *store = &(entry->addr_store);
        struct file_map_store *tmp_store;
        if ((tmp_store = RB_INSERT( rb_addr_head, rbh, store )) != NULL) {
            ff_printf("VMSEL: INSERT FAILED: 0x%lx, 0x%lx, 0x%lx, 0x%lx\n", (uintptr_t)entry->vme_start, (uintptr_t)entry->vme_length,
                  (uintptr_t)(VME_FOR_STORE(tmp_store, tree_type))->vme_start, (uintptr_t)(VME_FOR_STORE(tmp_store, tree_type))->vme_length);
            
            ff_assert(0);
        }
    }else {
        struct rb_size_head *rbh = &(mapHdr->rb_size_head_store);
        struct file_map_store *store = &(entry->size_store);
        struct file_map_store *tmp_store;
        if ((tmp_store = RB_INSERT( rb_size_head, rbh, store )) != NULL) {
            ff_printf("VMSEL: INSERT FAILED: 0x%lx, 0x%lx, 0x%lx, 0x%lx\n", (uintptr_t)entry->vme_start, (uintptr_t)entry->vme_length,
                  (uintptr_t)(VME_FOR_STORE(tmp_store, tree_type))->vme_start, (uintptr_t)(VME_FOR_STORE(tmp_store, tree_type))->vme_length);
            ff_assert(0);
        }
    }
}

void
file_map_store_entry_unlink_rb( struct file_map_header *mapHdr, file_map_entry_t entry, rb_tree_type tree_type)
{
    if (tree_type == rb_tree_type_addr) {
        struct rb_addr_head *rbh = &(mapHdr->rb_addr_head_store);
        struct file_map_store *store = &(entry->addr_store);
/*
        struct file_map_store *rb_entry;
        rb_entry = RB_FIND( rb_addr_head, rbh, store);
        if (rb_entry == NULL) {
            ff_printf("NO ENTRY TO DELETE\n");
            ff_assert(0);
        }
*/
        RB_REMOVE( rb_addr_head, rbh, store );
    }else {
        struct rb_size_head *rbh = &(mapHdr->rb_size_head_store);
        struct file_map_store *store = &(entry->size_store);
/*
        struct file_map_store *rb_entry;
        rb_entry = RB_FIND( rb_size_head, rbh, store);
        if (rb_entry == NULL) {
            ff_printf("NO ENTRY TO DELETE\n");
            ff_assert(0);
        }
 */
        RB_REMOVE( rb_size_head, rbh, store );
    }
}

void
file_map_enumerate_rb(file_map_header_t mapHdr, rb_tree_type tree_type) {
    if (tree_type == rb_tree_type_addr) {
        file_map_store* rb_entry;
        ff_printf("addr_tree enumerate::\n");
        RB_FOREACH(rb_entry, rb_addr_head, &mapHdr->rb_addr_head_store) {
#ifdef HMDBytestDefine
            CLANG_DIAGNOSTIC_PUSH
            CLANG_DIAGNOSTIC_IGNORE_UNUSED_VARIABLE
            file_map_entry_t       cur = VME_FOR_STORE(rb_entry, tree_type);
            CLANG_DIAGNOSTIC_POP
            ff_printf("mmap addr: 0x%lx~~~0x%lx, size = %ld --- in_use = %s\n", cur->mixed_addr, cur->mixed_addr+cur->vme_length, cur->vme_length, cur->in_use?"true":"false");
#endif
        }
    }else {
        file_map_store* rb_entry;
        ff_printf("size_tree enumerate::\n");
        RB_FOREACH(rb_entry, rb_size_head, &mapHdr->rb_size_head_store) {
#ifdef HMDBytestDefine
            CLANG_DIAGNOSTIC_PUSH
            CLANG_DIAGNOSTIC_IGNORE_UNUSED_VARIABLE
            file_map_entry_t       cur = VME_FOR_STORE(rb_entry, tree_type);
            CLANG_DIAGNOSTIC_POP
            ff_printf("mmap addr: 0x%lx~~~0x%lx, size = %ld --- in_use = %s\n", cur->mixed_addr, cur->mixed_addr+cur->vme_length, cur->vme_length, cur->in_use?"true":"false");
#endif
        }
    }
}

}
