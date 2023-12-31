//
//  thread_cpu_usage.cpp
//  ByteView
//
//  Created by liujianlong on 2021/7/5.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

#include "thread_cpu_usage.hpp"
#include "thread_biz_scope.h"

#include <atomic>
#include <cstring>
#include <functional>
#include <dispatch/dispatch.h>
#include <inttypes.h>
#include <mach/mach.h>
#include <mutex>
#include <pthread.h>

namespace {

kern_return_t task_memcpy(mach_port_t task, void *dest, const void *src, size_t len) {
    vm_size_t out_size = len;
    return vm_read_overwrite(task, (vm_address_t)src, len, (vm_address_t)dest, &out_size);
}

kern_return_t task_read_string(char *dest, const char *src, size_t len) {
    if (dest == 0L || src == 0L || len == 0) {
        return KERN_INVALID_ADDRESS;
    }
    char c = 0;
    int offset = 0;
    kern_return_t kr = KERN_SUCCESS;
    while (offset + 1 < len) {
        kr = task_memcpy(mach_task_self(), &c, src + offset, 1);
        if (kr != KERN_SUCCESS || c == 0) {
            break;
        }
        dest[offset++] = c;
    }
    dest[offset] = 0;
    return kr;
}

int get_queue_name_offset() {
    static std::once_flag once;
    static int offset;
    std::call_once(once, [] {
        dispatch_queue_t queue = dispatch_get_main_queue();
        const char *queue_name = dispatch_queue_get_label(queue);
        bool valid = false;
        for (int i = 0; i <= 20 * sizeof(void *); i += 2) { // 20个指针大小范围内遍历
            const char *queue_name_ptr = NULL;
            kern_return_t kr = task_memcpy(mach_task_self(), &queue_name_ptr, (char *)queue + i, sizeof(queue_name_ptr));
            if (kr != KERN_SUCCESS) continue;
            if (queue_name_ptr == queue_name) {
                offset = i;
                valid = true;
            }
        }
        if (!valid) {
            offset = -1;
        }
    });
    return offset;
}

bool get_queue_name(thread_t th, char *name, int len) {
    int name_offset = get_queue_name_offset();
    if (name_offset < 0) {
        return false;
    }

    integer_t thinfo_data[THREAD_IDENTIFIER_INFO_COUNT];
    thread_info_t thinfo = thinfo_data;
    mach_msg_type_number_t thidinfo_size = THREAD_IDENTIFIER_INFO_COUNT;
    kern_return_t kr =
    thread_info(th, THREAD_IDENTIFIER_INFO, thinfo, &thidinfo_size);
    if (kr != KERN_SUCCESS) {
        return false;
    }
    thread_identifier_info_t data = (thread_identifier_info_t)thinfo;
    dispatch_queue_t *dispatch_queue_ptr = (dispatch_queue_t *)data->dispatch_qaddr;
    if (dispatch_queue_ptr == NULL || data->thread_handle == 0) {
        return false;
    }

    dispatch_queue_t queue;
    if (task_memcpy(mach_task_self(), &queue, dispatch_queue_ptr, sizeof(queue)) != KERN_SUCCESS || queue == NULL) {
        return false;
    }

    char *queue_name = 0L;
    if (task_memcpy(mach_task_self(), &queue_name, (char *)queue + name_offset, sizeof(queue_name)) != KERN_SUCCESS) {
        return false;
    }
    if (queue_name == 0L) {
        return false;
    }
    kr = task_read_string(name, queue_name, len);
    if (kr != KERN_SUCCESS) {
        return false;
    }
    return true;
}

bool get_thread_name(thread_t th, char *name, int len) {
    if (len <= 0) {
        return false;
    }
    integer_t info_data[THREAD_EXTENDED_INFO_COUNT] = {0};
    mach_msg_type_number_t out_size = THREAD_EXTENDED_INFO_COUNT;
    kern_return_t kr;

    kr = thread_info(th, THREAD_EXTENDED_INFO, (thread_info_t)info_data, &out_size);
    if (kr != KERN_SUCCESS) {
        return false;
    }

    thread_extended_info_t data = (thread_extended_info_t)info_data;
    strncpy(name, data->pth_name, len-1);
    name[len - 1] = 0;
    return true;
}

bool foreach_thread(std::function<void(int idx, thread_t basic_thinfo)>callback) {
    thread_array_t thread_list;
    mach_msg_type_number_t thread_count;
    kern_return_t kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return false;
    }
    for (int idx = 0; idx < (int)thread_count; idx++) {
        callback(idx, thread_list[idx]);
    }

    for (size_t index = 0; index < thread_count; index++) {
        mach_port_deallocate(mach_task_self(), thread_list[index]);
    }
    vm_deallocate(mach_task_self(), (vm_offset_t)thread_list,
                  thread_count * sizeof(thread_t));

    return true;
}

bool foreach_thread_basicinfo(std::function<void(int idx, thread_basic_info_t basic_thinfo)>callback) {
    thread_info_data_t thinfo;
    mach_msg_type_number_t thinfo_count;
    return foreach_thread([&](int idx, thread_t t) {
        thinfo_count = THREAD_INFO_MAX;
        auto kr = thread_info(t, THREAD_BASIC_INFO, thinfo, &thinfo_count);
        if (kr != KERN_SUCCESS) {
            return;
        }
        thread_basic_info_t basic_thinfo = (thread_basic_info_t)thinfo;
        callback(idx, basic_thinfo);
    });
}

} // namespace

namespace byteview {


float ThreadCPUUsage::GetAppCPU() {
    uint64_t scaled_usage = 0;
    foreach_thread_basicinfo([&](int idx, thread_basic_info_t info) {
        if (info->flags & TH_FLAGS_IDLE) {
            return;
        }
        scaled_usage += info->cpu_usage;
    });
    return scaled_usage / (float)TH_USAGE_SCALE;
}

std::tuple<std::vector<ThreadCPUUsage>, float, float> ThreadCPUUsage::GetThreadUsages(int topN) {
    std::vector<ThreadCPUUsage> usages;
    float appCPUUsage = 0.0f;
    float rtcCPUUsage = 0.0f;
    char name_storage[256];

    thread_info_data_t thinfo;
    mach_msg_type_number_t thinfo_count;
    foreach_thread([&](int idx, thread_t th) {
        thinfo_count = THREAD_INFO_MAX;
        auto kr = thread_info(th, THREAD_BASIC_INFO, thinfo, &thinfo_count);
        if (kr != KERN_SUCCESS) {
            return;
        }
        thread_basic_info_t basic_thinfo = (thread_basic_info_t)thinfo;
        if (basic_thinfo->flags & TH_FLAGS_IDLE) {
            return;
        }
        usages.emplace_back();
        auto& usage = usages.back();
        usage.index = idx;

        usage.cpu_usage = basic_thinfo->cpu_usage / (float)TH_USAGE_SCALE;
        appCPUUsage += usage.cpu_usage;
        pthread_t pth = pthread_from_mach_thread_np(th);
        if (pth) {
            uint64_t thread_id = 0;
            pthread_threadid_np(pth, &thread_id);
            usage.thread_id = thread_id;
            usage.biz_scope = byteview_get_thread_scope(thread_id);
            if (byteview_get_thread_scope(thread_id) == ByteViewThreadBizScope_RTC) {
                rtcCPUUsage += usage.cpu_usage;
            }
        }

        if (idx == 0) {
            usage.thread_name = "main";
        } else if (get_thread_name(th, name_storage, sizeof(name_storage))) {
            usage.thread_name = name_storage;
        }

        if (usage.biz_scope == ByteViewThreadBizScope_Unknown && usage.thread_name == "AURemoteIO::IOThread") {
            // 音频编码线程开销分配给 RTC
            usage.biz_scope = ByteViewThreadBizScope_RTC;
            rtcCPUUsage += usage.cpu_usage;
        }

        if (get_queue_name(th, name_storage, sizeof(name_storage)))
            usage.queue_name = name_storage;

    });
    std::sort(usages.begin(), usages.end(), [](const ThreadCPUUsage& lhs, const ThreadCPUUsage& rhs) -> bool {
        return lhs.cpu_usage > rhs.cpu_usage;
    });

    if (usages.size() > topN) {
        usages.resize(topN);
    }

    return std::make_tuple(std::move(usages), appCPUUsage, rtcCPUUsage);
}

} // namespace byteview
