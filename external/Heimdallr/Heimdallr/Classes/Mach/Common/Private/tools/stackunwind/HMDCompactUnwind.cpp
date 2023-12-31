//
//  HMDCompactUnwind.cpp
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/21.
//

#include <atomic>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <CoreFoundation/CoreFoundation.h>

#include "HMDMacro.h"
#include "HMDAsyncImageList.h"
#include "HMDCompactUnwind.hpp"

using namespace std;

hmd_async_image_list_t shared_image_list;
hmd_async_image_list_t shared_app_image_list;

static void mark_async_share_image_list_has_setup(void);
static void mark_async_share_image_list_finished_setup(void);

static void image_add_callback (const struct mach_header *mh, intptr_t vmaddr_slide);
static void image_remove_callback (const struct mach_header *mh, intptr_t vmaddr_slide);
static void image_add_usr_lib_dyld(void);
static void image_finish_setup_callback(void);

static void register_image_with_address_and_path(const struct mach_header *mh, const char *path);

static volatile atomic_bool flag_async_share_image_list_has_setup;
static volatile atomic_bool flag_async_share_image_list_finished_setup;
static atomic_uintptr_t finish_callback;
static volatile atomic_uint image_list_version;

#pragma mark - Export Function

#pragma mark setup lists

static dispatch_queue_t image_process_queue;

void hmd_setup_shared_image_list(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hmd_nasync_image_list_init(&shared_image_list);
        hmd_nasync_image_list_init(&shared_app_image_list);
        image_process_queue = dispatch_queue_create("com.hmd.image.common", DISPATCH_QUEUE_SERIAL);
        
        _dyld_register_func_for_add_image(image_add_callback);
        _dyld_register_func_for_remove_image(image_remove_callback);
        image_add_usr_lib_dyld();
        mark_async_share_image_list_has_setup();
        image_finish_setup_callback();
    });
}

void hmd_setup_shared_image_list_if_need(void) {
    if(hmd_async_share_image_list_has_setup()) return;
    hmd_setup_shared_image_list();
}

bool hmd_async_share_image_list_has_setup(void) {
    return atomic_load_explicit(&flag_async_share_image_list_has_setup, memory_order_acquire);
}

bool hmd_async_share_image_list_finished_setup(void) {
    return atomic_load_explicit(&flag_async_share_image_list_finished_setup, memory_order_acquire);
}

int hmd_async_share_image_list_version(void) {
    return image_list_version;
}

#pragma mark Image list enumerate

void hmd_enumerate_image_list_using_block(hmd_image_callback_block block) {
    hmd_setup_shared_image_list_if_need();
    hmd_enumerate_each_image_with_lock(&shared_image_list, block);
}

void hmd_enumerate_app_image_list_using_block(hmd_image_callback_block block) {
    hmd_setup_shared_image_list_if_need();
    hmd_enumerate_each_image_with_lock(&shared_app_image_list, block);
}

void hmd_async_enumerate_image_list(hmd_image_callback_func callback, void * _Nullable context) {
    hmd_setup_shared_image_list_if_need();
    hmd_async_enumerate_each_image(&shared_image_list, callback, context);
}

#pragma mark image queue

dispatch_queue_t hmd_shared_binary_image_queue(void) {
    hmd_setup_shared_image_list_if_need();
    return image_process_queue;
}

#pragma mark callback

void hmd_shared_binary_image_register_finish_callback(hmd_image_finish_callback _Nonnull callback) {
    atomic_store_explicit(&finish_callback, (uintptr_t)callback, memory_order_release);
}

#pragma mark - add and remove (on image_process_queue)

static void image_add_callback (const struct mach_header *header, intptr_t vmaddr_slide) {
    dispatch_async(image_process_queue, ^{
        Dl_info info;
        
        /* Look up the image info */
        if(dladdr(header, &info) == 0) {
            DEBUG_LOG("dladdr failed for mach-o header address %p", header);
            return;
        }
        
        register_image_with_address_and_path(header, info.dli_fname);

        image_list_version += 1;
    });
}

static void image_remove_callback(const struct mach_header *header, intptr_t vmaddr_slide) {
    dispatch_async(image_process_queue, ^{
        hmd_nasync_image_list_remove(&shared_image_list, (uintptr_t)header);
        hmd_nasync_image_list_remove(&shared_app_image_list, (uintptr_t)header);
    });
}

static void image_add_usr_lib_dyld(void) {
    
    task_dyld_info dyld_info;
    
    task_flavor_t flavor = TASK_DYLD_INFO;
    mach_msg_type_number_t task_info_out_count = TASK_DYLD_INFO_COUNT;
    kern_return_t kr = task_info(mach_task_self(), flavor, (task_info_t)&dyld_info, &task_info_out_count);
    if(kr != KERN_SUCCESS) DEBUG_RETURN_NONE;
    
    struct dyld_all_image_infos *allImageInfos = (struct dyld_all_image_infos *)dyld_info.all_image_info_addr;
    const struct mach_header *dyld_header = allImageInfos->dyldImageLoadAddress;
    
    const char *dyldPath = "/usr/lib/dyld";
    if(kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_9_x_Max) {
        dyldPath = allImageInfos->dyldPath;
    }
    
    dispatch_async(image_process_queue, ^{
        register_image_with_address_and_path(dyld_header, dyldPath);
    });
}

static void image_finish_setup_callback(void) {
    dispatch_async(image_process_queue, ^{
        mark_async_share_image_list_finished_setup();
        
        uintptr_t raw_callback = atomic_load_explicit(&finish_callback, memory_order_acquire);
        hmd_image_finish_callback _Nullable finish_callback = reinterpret_cast<hmd_image_finish_callback>(raw_callback);
        
        if(finish_callback == nullptr) return;
        if(!VM_ADDRESS_CONTAIN(finish_callback)) DEBUG_RETURN_NONE;    // force check
        
        finish_callback();
    });
}

#pragma mark - For each image

static void register_image_with_address_and_path(const struct mach_header *header, const char *path){
    
    hmd_async_image_t *image = hmd_nasync_image_list_append_with_ret(&shared_image_list, (hmd_vm_address_t) header, path);
    
    if (image && image->macho_image.is_app_image) {
        hmd_async_image_t *copy = (hmd_async_image_t *)calloc(1, sizeof(hmd_async_image_t));
        if (copy) {
            memcpy(copy, image, sizeof(hmd_async_image_t));
            shared_app_image_list._list->append(copy);
        }
    }
}

#pragma mark - Mark status

static void mark_async_share_image_list_has_setup(void) {
    atomic_store_explicit(&flag_async_share_image_list_has_setup, true, memory_order_release);
}

static void mark_async_share_image_list_finished_setup(void) {
    atomic_store_explicit(&flag_async_share_image_list_finished_setup, true, memory_order_release);
}

