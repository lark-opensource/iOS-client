//
//  HMDAsyncImageList.cpp
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//

#include "HMDAsyncImageList.h"
#include "HMDAsyncSafeLinkedList.hpp"
#include "hmd_types.h"

#define HMDLogger_LocalLevel INFO
#include "hmd_logger.h"

#include <assert.h>
#include <stdlib.h>
#include <string.h>

using namespace hmd::async_safe;

static void free_image(hmd_async_image_t *image) {
    if (image) {
        hmd_nasync_macho_free(&image->macho_image);
        free(image);
    }
}

void hmd_nasync_image_list_init(hmd_async_image_list_t *list) {
    memset(list, 0, sizeof(*list));

    list->_list = new linked_list<hmd_async_image_t *>();
    list->_list->set_free_func(free_image);
}

void hmd_nasync_image_list_free(hmd_async_image_list_t *list) {
    /* Free the backing list */
    delete list->_list;
}

hmd_async_image_t * hmd_nasync_image_list_append_with_ret(hmd_async_image_list_t *list, hmd_vm_address_t header, const char *name) {
    hmd_error_t ret;

    /* Initialize the new entry. */
    hmd_async_image_t *new_entry = (hmd_async_image_t *)calloc(1, sizeof(hmd_async_image_t));
    if (new_entry == NULL) {
        return NULL;
    }
    
    if ((ret = hmd_nasync_macho_init(&new_entry->macho_image, name, header)) != HMD_ESUCCESS) {
        HMDLOG_ERROR("Unexpected failure initializing Mach-O structure for %s: %d", name, ret);
        free(new_entry);
        return NULL;
    }

    /* Append */
    list->_list->append(new_entry);
    
    return new_entry;
}

void hmd_nasync_image_list_remove(hmd_async_image_list_t *list, hmd_vm_address_t header) {
    list->_list->lock();
   
    linked_list<hmd_async_image_t *>::node *found = NULL;
    linked_list<hmd_async_image_t *>::node *next = NULL;
    while ((next = list->_list->next_while_lock(next)) != NULL) {
        if (next->value()->macho_image.header_addr == header) {
           found = next;
           break;
        }
    }
   
    if (found) {
        list->_list->remove_node_while_lock(found);
    }
      
    list->_list->unlock();
}

/**
 * Retain or release the list for reading. This method is async-safe.
 *
 * This must be issued prior to attempting to iterate the list, and must called again once reads have completed.
 *
 * @param list The list to be be retained or released for reading.
 * @param enable If true, the list will be retained. If false, released.
 */
void hmd_async_image_list_set_reading(hmd_async_image_list_t *list, bool enable) { list->_list->set_reading(enable); }

typedef struct image_enumerate_context {
    hmd_vm_address_t address;
    hmd_async_image_t *image;
    int index;
    char name[512];
}image_enumerate_context_t;

static void image_address_callback(hmd_async_image_t *image,int index,bool *stop,void *ctx) {
    image_enumerate_context_t *image_ctx = (image_enumerate_context_t *)ctx;
    if (hmd_async_macho_contains_address(&image->macho_image, image_ctx->address)) {
        image_ctx->image = image;
        image_ctx->index = index;
        *stop = true;
    }
}

hmd_async_image_t *hmd_async_image_containing_address(hmd_async_image_list_t *list, hmd_vm_address_t address) {
    image_enumerate_context_t ctx = {0};
    ctx.address = address;
    hmd_async_enumerate_each_image(list, image_address_callback, &ctx);
    return ctx.image;
}

static void image_name_callback(hmd_async_image_t *image,int index,bool *stop,void *ctx) {
    image_enumerate_context_t *image_ctx = (image_enumerate_context_t *)ctx;
    if (strlen(image->macho_image.name) >= strlen(image_ctx->name)){
        char *base_name = image->macho_image.name+strlen(image->macho_image.name)-strlen(image_ctx->name);
        if(strcmp(base_name, image_ctx->name) == 0) {
            image_ctx->image = image;
            image_ctx->index = index;
            *stop = true;
        }
    }
}

hmd_async_image_t *hmd_async_image_containing_name(hmd_async_image_list_t *list, const char *image_name) {
    image_enumerate_context_t ctx = {0};
    strncpy(ctx.name, image_name, sizeof(ctx.name)-1);
    hmd_async_enumerate_each_image(list, image_name_callback, &ctx);
    return ctx.image;
}

#pragma  mark - enumerate

void hmd_enumerate_each_image_with_lock(hmd_async_image_list_t *list, hmd_image_callback_block block) {
    if (list == NULL || block == NULL) {
        return;
    }
    list->_list->enumerate_node_with_lock(block);
}

void hmd_async_enumerate_each_image(hmd_async_image_list_t *list, hmd_image_callback_func callback, void *ctx) {
    if (list == NULL || callback == NULL) {
        return;
    }
    list->_list->async_enumerate_node(callback, ctx);
}


/**
 * @}
 */
