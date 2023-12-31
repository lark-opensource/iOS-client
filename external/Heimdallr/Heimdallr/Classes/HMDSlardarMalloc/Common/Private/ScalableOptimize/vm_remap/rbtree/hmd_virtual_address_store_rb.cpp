//
//  virtual_address_store_rb.cpp
//  Heimdallr
//  
//  Created by zhouyang11 on 2023/2/20
//

#include "hmd_virtual_address_store_rb.h"
#include "HMDMacro.h"

#define VME_FOR_STORE(store)   \
(file_map_entry_t)(((unsigned long)store) - 16)

namespace HMDVirtualMemoryManager {

int
rb_node_compare_addr(struct file_map_store *node, struct file_map_store *parent)
{
    file_map_entry_t vme_c;
    file_map_entry_t vme_p;
    
    vme_c = VME_FOR_STORE(node);
    vme_p =  VME_FOR_STORE(parent);
    if (DECODE_ENTRY_ADDR(vme_c) < DECODE_ENTRY_ADDR(vme_p)) {
        return -1;
    }
    if (DECODE_ENTRY_ADDR(vme_c) >= (DECODE_ENTRY_ADDR(vme_p)+vme_p->size)) {
        return 1;
    }
    return 0;
}

RB_GENERATE(rb_addr_head, file_map_store, entry, rb_node_compare_addr);

void file_map_store_init_rb(file_map_header_t mapHdr) {
    RB_INIT(&(mapHdr->rb_addr_head_store));
}

bool
file_map_store_lookup_entry_rb(file_map_header_t mapHdr, uintptr_t factor, file_map_entry_t *vm_entry, file_map_entry_t *vm_entry_prev, file_map_entry_t *vm_entry_next)
{
    struct file_map_store  *rb_entry;
    
    rb_entry = RB_ROOT(&(mapHdr->rb_addr_head_store));
    file_map_entry_t       cur = VME_FOR_STORE(rb_entry);
    file_map_entry_t       prev = FILE_MAP_ENTRY_NULL;
    file_map_entry_t       next = FILE_MAP_ENTRY_NULL;
    
    uintptr_t address = factor;
    while (rb_entry != (struct file_map_store*)NULL) {
        cur =  VME_FOR_STORE(rb_entry);
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
}

void
file_map_store_entry_link_rb( struct file_map_header *mapHdr, __unused file_map_entry_t after_where, file_map_entry_t entry)
{
    struct rb_addr_head *rbh = &(mapHdr->rb_addr_head_store);
    struct file_map_store *store = &(entry->addr_store);
    struct file_map_store *tmp_store;
    if ((tmp_store = RB_INSERT( rb_addr_head, rbh, store )) != NULL) {
        //        ff_printf("VMSEL: INSERT FAILED: 0x%lx, 0x%lx, 0x%lx, 0x%lx\n", (uintptr_t)entry->vme_start, (uintptr_t)entry->size,
        //                  (uintptr_t)(VME_FOR_STORE(tmp_store, tree_type))->vme_start, (uintptr_t)(VME_FOR_STORE(tmp_store, tree_type))->size);
        
        ff_assert(0);
    }
}

void
file_map_store_entry_unlink_rb( struct file_map_header *mapHdr, file_map_entry_t entry)
{
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
}

void
file_map_enumerate_rb(file_map_header_t mapHdr) {
    file_map_store* rb_entry;
    ff_printf("vmrecorder-enumerate::\n");
    RB_FOREACH(rb_entry, rb_addr_head, &mapHdr->rb_addr_head_store) {
        CLANG_DIAGNOSTIC_PUSH
        CLANG_DIAGNOSTIC_IGNORE_UNUSED_VARIABLE
        file_map_entry_t       cur = VME_FOR_STORE(rb_entry);
        CLANG_DIAGNOSTIC_POP
        ff_printf("ff-heap-vm: 0x%lx~~~0x%lx, mmap-vm: 0x%lx~~~0x%lx, size = %ld\n", cur->mixed_addr, cur->mixed_addr+cur->size, cur->mapped_addr, cur->mapped_addr+cur->size, cur->size);
    }
}
}
