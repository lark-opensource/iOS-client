//
//  HMDAsyncImageList.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//

#ifndef HMD_ASYNC_IMAGE_LIST_H
#define HMD_ASYNC_IMAGE_LIST_H

#include <libkern/OSAtomic.h>
#include <stdbool.h>
#include <stdint.h>

#include "HMDAsyncMachOImage.h"

/*
 * NOTE: We keep this code C-compatible for backwards-compatibility purposes. If the entirity
 * of the codebase migrates to C/C++/Objective-C++, we can drop the C compatibility support
 * used here.
 */
#ifdef __cplusplus
#include "HMDAsyncSafeLinkedList.hpp"
#endif

#ifdef __cplusplus
extern "C" {
#endif
typedef struct hmd_async_image hmd_async_image_t;
typedef struct hmd_async_image_list hmd_async_image_list_t;

/**
 * @internal
 * @ingroup hmd_async_image
 *
 * Async-safe binary image list element.
 */
struct hmd_async_image {
    /** The binary image. */
    hmd_async_macho_t macho_image;

    /** A borrowed, circular reference to the backing list node. */
#ifdef __cplusplus
    hmd::async_safe::linked_list<hmd_async_image_t *>::node *_node;
#else
    void *_node;
#endif
};

/**
 * @internal
 * @ingroup hmd_async_image
 *
 * Async-safe binary image list. May be used to iterate over the binary images currently
 * available in-process.
 */
typedef struct hmd_async_image_list {
    /** The Mach task in which all Mach-O images can be found */
//    mach_port_t task;

    /** The backing list */
#ifdef __cplusplus
    hmd::async_safe::linked_list<hmd_async_image_t *> *_list;
#else
    void *_list;
#endif
} hmd_async_image_list;

void hmd_nasync_image_list_init(hmd_async_image_list_t *list);
void hmd_nasync_image_list_free(hmd_async_image_list_t *list);
//void hmd_nasync_image_list_append(hmd_async_image_list_t *list, hmd_vm_address_t header, const char *name);

//must reading
hmd_async_image_t * hmd_nasync_image_list_append_with_ret(hmd_async_image_list_t *list, hmd_vm_address_t header, const char *name);
    
void hmd_nasync_image_list_remove(hmd_async_image_list_t *list, hmd_vm_address_t header);
    
void hmd_async_image_list_set_reading(hmd_async_image_list_t *list, bool enable);

hmd_async_image_t *hmd_async_image_containing_address(hmd_async_image_list_t *list, hmd_vm_address_t address);

hmd_async_image_t *hmd_async_image_containing_name(hmd_async_image_list_t *list, const char *image_name);

//由于不确定block的copy时机，所以不能确定是否是async signal safe的函数

typedef void(^hmd_image_callback_block)(hmd_async_image_t *image,int index,bool *stop);

void hmd_enumerate_each_image_with_lock(hmd_async_image_list_t *list, hmd_image_callback_block block);

//async safe

typedef void (*hmd_image_callback_func)(hmd_async_image_t *image,int index,bool *stop,void *ctx);

void hmd_async_enumerate_each_image(hmd_async_image_list_t *list, hmd_image_callback_func callback, void *ctx);

#ifdef __cplusplus
}
#endif

#endif /* HMD_ASYNC_IMAGE_LIST_H */
