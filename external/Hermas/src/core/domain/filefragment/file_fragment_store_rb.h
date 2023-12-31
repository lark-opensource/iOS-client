//
//  file_fragment_store_rb.hpp
//  FileFragment
//
//  Created by zhouyang11 on 2022/1/24.
//

#ifndef file_fragment_store_rb_hpp
#define file_fragment_store_rb_hpp

#include <stdio.h>
#include "file_fragment_header.h"

namespace hermas {

RB_PROTOTYPE(rb_size_head, file_map_store, entry, rb_node_compare_size);
RB_PROTOTYPE(rb_addr_head, file_map_store, entry, rb_node_compare_addr);

void
file_map_store_init_rb(file_map_header_t);

bool
file_map_store_lookup_entry_rb(file_map_header_t mapHdr, uintptr_t address, file_map_entry_t *vm_entry, rb_tree_type tree_type);

void
file_map_store_entry_link_rb(file_map_header_t mapHdr, __unused file_map_entry_t after_where, file_map_entry_t entry, rb_tree_type tree_type);

void
file_map_store_entry_unlink_rb(file_map_header_t mapHdr, file_map_entry_t entry, rb_tree_type tree_type);

void
file_map_enumerate_rb(file_map_header_t mapHdr, rb_tree_type tree_type);
}

#endif /* file_fragment_store_rb_hpp */
