//
//  HMDCompactUnwind.cpp
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/21.
//

#include "HMDCompactUnwind.hpp"
#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <dlfcn.h>
#include "HMDAsyncImageList.h"
#include <atomic>
#include <CoreFoundation/CoreFoundation.h>

#pragma mark - compact unwind setup
hmd_async_image_list_t shared_image_list;
hmd_async_image_list_t shared_app_image_list;

using namespace std;

static volatile atomic_bool hmdcrash_use_compact_unwind;
static dispatch_queue_t unwind_queue;

static void image_add_usr_lib_dyld ();

void hmd_async_enable_compact_unwind(void)
{
    atomic_store_explicit(&hmdcrash_use_compact_unwind, true, memory_order_release);
}

bool hmd_async_can_use_compact_unwind(void)
{
    return hmd_async_share_image_list_has_setup() && atomic_load_explicit(&hmdcrash_use_compact_unwind, memory_order_acquire);
}

static volatile atomic_bool hmd_async_shared_image_list_initialized;

bool hmd_async_share_image_list_has_setup(void)
{
    return atomic_load_explicit(&hmd_async_shared_image_list_initialized, memory_order_acquire);
}

/**
 * @internal
 * dyld image add notification callback.
 */
static void register_image_with_address_and_path(const struct mach_header *mh, const char *path){
    /* Register the image */
    hmd_async_image_t *image = hmd_nasync_image_list_append_with_ret(&shared_image_list, (hmd_vm_address_t) mh, path);
    
    if (image && image->macho_image.is_app_image) {
        hmd_async_image_t *copy = (hmd_async_image_t *)calloc(1, sizeof(hmd_async_image_t));
        if (copy) {
            memcpy(copy, image, sizeof(hmd_async_image_t));
            shared_app_image_list._list->append(copy);
        }
    }
}

static void image_add_callback (const struct mach_header *mh, intptr_t vmaddr_slide) {
    dispatch_async(unwind_queue, ^{
        Dl_info info;
        
        /* Look up the image info */
        if (dladdr(mh, &info) == 0) {
            HMDPrint("%s: dladdr(%p, ...) failed", __FUNCTION__, mh);
            return;
        }
        
        register_image_with_address_and_path(mh, info.dli_fname);
    });
}

/**
 * @internal
 * dyld image remove notification callback.
 */
static void image_remove_callback (const struct mach_header *mh, intptr_t vmaddr_slide) {
    dispatch_async(unwind_queue, ^{
        hmd_nasync_image_list_remove(&shared_image_list, (uintptr_t) mh);
        hmd_nasync_image_list_remove(&shared_app_image_list, (hmd_vm_address_t) mh);
    });
}

void hmd_setup_shared_image_list(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hmd_nasync_image_list_init(&shared_image_list);
        hmd_nasync_image_list_init(&shared_app_image_list);
        unwind_queue = dispatch_queue_create("com.hmd.unwind", DISPATCH_QUEUE_SERIAL);
        _dyld_register_func_for_add_image(image_add_callback);
        _dyld_register_func_for_remove_image(image_remove_callback);
        image_add_usr_lib_dyld ();
        atomic_thread_fence(memory_order_release);
        atomic_store_explicit(&hmd_async_shared_image_list_initialized, true, memory_order_release);
    });
}

void hmd_setup_shared_image_list_if_need(void)
{
    if (hmd_async_share_image_list_has_setup() == false) {
        hmd_setup_shared_image_list();
    }
}

static void image_add_usr_lib_dyld (){
    kern_return_t kr;
    task_flavor_t flavor = TASK_DYLD_INFO;
    task_dyld_info dyld_info;
    mach_msg_type_number_t task_info_outCnt = TASK_DYLD_INFO_COUNT;
    kr = task_info(mach_task_self(), flavor, (task_info_t) &dyld_info, &task_info_outCnt);
    if (kr != KERN_SUCCESS) {
        return;
    }
    
    struct dyld_all_image_infos *allImageInfos = (struct dyld_all_image_infos *) dyld_info.all_image_info_addr;
    
    if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_9_x_Max) {
        const char* dyldPath = "/usr/lib/dyld";
        register_image_with_address_and_path(allImageInfos->dyldImageLoadAddress, dyldPath);
    }
    else
    {
        register_image_with_address_and_path(allImageInfos->dyldImageLoadAddress, allImageInfos->dyldPath);
    }
}

#pragma mark - image list enumerate

void hmd_enumerate_image_list_using_block(hmd_image_callback_block block) {
    hmd_setup_shared_image_list_if_need();
    hmd_enumerate_each_image_with_lock(&shared_image_list, block);
}

void hmd_enumerate_app_image_list_using_block(hmd_image_callback_block block) {
    hmd_setup_shared_image_list_if_need();
    hmd_enumerate_each_image_with_lock(&shared_app_image_list, block);
}

void hmd_async_enumerate_image_list(hmd_image_callback_func callback,void *ctx) {
    if (hmd_async_share_image_list_has_setup() == false) {
        return;
    }
    hmd_async_enumerate_each_image(&shared_image_list, callback, ctx);
}

#pragma mark - image deal queue
dispatch_queue_t hmd_shared_image_unwind_queue(void) {
    hmd_setup_shared_image_list_if_need();
    return unwind_queue;
}

