//
//  virtual_address_store_header.h
//  Heimdallr
//  
//  Created by zhouyang11 on 2023/2/20
//

#ifndef virtual_address_store_header_h
#define virtual_address_store_header_h

#include "hmd_memory_rbtree.h"
#include <assert.h>

#define k_mb (1024*1024)
#define k_gb (1024L*1024L*1024L)

namespace HMDVirtualMemoryManager {

#define FILE_MAP_ENTRY_NULL       ((file_map_entry_t) NULL)
#define DECODE_ENTRY_ADDR(entry) (entry->mixed_addr)
#define ENCODE_ENTRY_ADDR(entry, addr) entry->mixed_addr = addr
#define ENTRY_RIGHT_BOUNDRY(x) (DECODE_ENTRY_ADDR(x)+x->size)

RB_HEAD(rb_size_head, file_map_store);
RB_HEAD(rb_addr_head, file_map_store);

//红黑树节点
struct file_map_store {
    RB_ENTRY(file_map_store) entry;
};

//双向链表节点
struct file_map_links {
    struct file_map_entry     *prev;            /* previous entry */
    struct file_map_entry     *next;            /* next entry */
    size_t         start;                       /* offset to the beginning of the file */
    size_t         length;                      /* size of flie fragment */
};

//核心数据结构entry
struct file_map_entry {
    size_t                    size;
    uintptr_t                 mapped_addr;
    struct file_map_store     addr_store;
    uintptr_t                 mixed_addr;             /* virtual address */
};

//红黑树的根节点
struct file_map_header {
    struct rb_addr_head  rb_addr_head_store;    /* rbtree root for address */
};

typedef struct file_map_entry     *file_map_entry_t;
typedef struct file_map_header    *file_map_header_t;
}
#endif /* virtual_address_store_header_h */
