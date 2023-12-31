//
//  file_fragment_header.h
//  FileFragment
//
//  Created by zhouyang11 on 2022/1/25.
//

#ifndef file_fragment_header_h
#define file_fragment_header_h

#include "hmd_memory_rbtree.h"

namespace HMDMemoryAllocator {

#define FILE_MAP_ENTRY_NULL       ((file_map_entry_t) NULL)
//#define DECODE_ENTRY_ADDR(entry) ((entry->mixed_addr) & 0x7fffffffffffffff)
//#define ENCODE_ENTRY_ADDR(entry, addr) entry->mixed_addr = ((addr) | 0x8000000000000000)

#define DECODE_ENTRY_ADDR(entry) ((entry->mixed_addr))
#define ENCODE_ENTRY_ADDR(entry, addr) entry->mixed_addr = ((addr))

#define ENTRY_RIGHT_BOUNDRY(x) (DECODE_ENTRY_ADDR(x)+x->vme_length)


typedef enum : int8_t {
    rb_tree_type_addr,  //以addr排序的rbtree
    rb_tree_type_size   //以size排序的rbtree
} rb_tree_type;

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
    struct file_map_links     links;            /* links to other entries */
#define vme_prev              links.prev
#define vme_next              links.next
#define vme_start             links.start
#define vme_length            links.length
    struct file_map_store     addr_store;
    struct file_map_store     size_store;
    uintptr_t                 mixed_addr;             /* virtual address */
    bool                      in_use;           /* in use */
};

//红黑树的根节点
struct file_map_header {
    struct rb_size_head  rb_size_head_store;    /* rbtree root for size */
    struct rb_addr_head  rb_addr_head_store;    /* rbtree root for address */
};

typedef struct file_map_entry     *file_map_entry_t;
typedef struct file_map_header    *file_map_header_t;
}

#endif /* file_fragment_header_h */
