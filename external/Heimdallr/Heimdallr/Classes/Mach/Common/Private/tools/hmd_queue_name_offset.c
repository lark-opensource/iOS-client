//
//  hmd_queue_name_offset.c
//  AFgzipRequestSerializer
//
//  Created by yuanzhangjing on 2019/9/28.
//

#include "hmd_queue_name_offset.h"
#include "hmd_memory.h"
#include <dispatch/dispatch.h>
#include <stdatomic.h>

#define queue_name_default_value -1
#define queue_name_invalid_value -2

static atomic_int queue_name_offset_val = queue_name_default_value;

static int queue_name_offset_value(void) {
    return atomic_load_explicit(&queue_name_offset_val,memory_order_acquire);
}

static void set_queue_name_offset_value(int value) {
    atomic_store_explicit(&queue_name_offset_val,value,memory_order_release);
}

int hmdthread_async_queue_name_offset(void) {
    int ret = queue_name_offset_value();
    return ret;
}

void hmdthread_test_queue_name_offset(void) {
    int offset = queue_name_offset_value();
    if (offset != queue_name_default_value) {
        return;
    }
    dispatch_queue_t queue = dispatch_get_main_queue();
    const char *queue_name = dispatch_queue_get_label(queue);
    bool valid = false;
    for (int i = 0; i <= 20 * sizeof(void *); i+=2) { //20个指针大小范围内遍历
        const char *queue_name_ptr = NULL;
        __unused hmd_error_t err = hmd_async_read_memory((hmd_vm_address_t)queue+i, &queue_name_ptr, sizeof(queue_name_ptr));
        if (queue_name_ptr == queue_name) {
            offset = i;
            valid = true;
        }
    }
    if (!valid) {
        offset = queue_name_invalid_value;
    }
    set_queue_name_offset_value(offset);
    return;
}
