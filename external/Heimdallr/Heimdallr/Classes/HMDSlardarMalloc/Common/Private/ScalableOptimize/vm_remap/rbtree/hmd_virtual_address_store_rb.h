//
//  virtual_address_store_rb.hpp
//  Heimdallr
//  
//  Created by zhouyang11 on 2023/2/20
//

#ifndef virtual_address_store_rb_hpp
#define virtual_address_store_rb_hpp

#include <stdio.h>
#include "hmd_virtual_address_store_header.h"
#include "hmd_virtual_memory_macro.h"

namespace HMDVirtualMemoryManager {

RB_PROTOTYPE(rb_size_head, file_map_store, entry, rb_node_compare_size);
RB_PROTOTYPE(rb_addr_head, file_map_store, entry, rb_node_compare_addr);

void
file_map_store_init_rb(file_map_header_t);

bool
file_map_store_lookup_entry_rb(file_map_header_t mapHdr, uintptr_t address, file_map_entry_t *vm_entry, file_map_entry_t *vm_entry_prev, file_map_entry_t *vm_entry_next);

void
file_map_store_entry_link_rb(file_map_header_t mapHdr, __unused file_map_entry_t after_where, file_map_entry_t entry);

void
file_map_store_entry_unlink_rb(file_map_header_t mapHdr, file_map_entry_t entry);

void
file_map_enumerate_rb(file_map_header_t mapHdr);
}

#endif /* virtual_address_store_rb_hpp */
