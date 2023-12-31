//
//  HMDCrashException.c
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/12.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#include <stdio.h>
#include <stdint.h>
#include <stdatomic.h>
#include "HMDCrashDirectory_LowLevel.h"
#include "HMDCrashException.h"
#include "HMDCrashFileBuffer.h"
#include "HMDCrashSDKLog.h"
#include "HMDCrashHeader.h"
#include "HMDCrashOnceCatch.h"
#include <sys/mount.h>
#include "HMDCrashImagesState.h"
#include <errno.h>
#include "HMDCrashAddressAnalyze.h"
#include "HMDObjcRuntime.h"
#include "hmd_memory.h"
#include <mach/vm_statistics.h>
#include "HMDCrashDynamicData.h"
#include "HMDCompactUnwind.hpp"
#include "HMDCrashRegionFile.h"
#include "HMDMemoryUsage.h"
#include "HMDCrashContentAnalyze.h"
#include "HMDCrashKitSwitch.h"
#include "HMDCrashExtraDynamicData.h"
#include "HMDCrashDetect_Private.h"

static FileBuffer buffer = FileBufferInvalid;

static atomic_bool tmp_finished = false;

void tmpExceptionFinish(void)
{
    atomic_store_explicit(&tmp_finished,true,memory_order_release);
    atomic_thread_fence(memory_order_release);
}

bool tmpExceptionIsFinished(void)
{
    return atomic_load_explicit(&tmp_finished,memory_order_acquire);
}


static bool allocate_file(int fd,ssize_t length) {
    fstore_t store = {F_ALLOCATECONTIG, F_PEOFPOSMODE, 0, length};
    // Try to get a continous chunk of disk space
    int ret = fcntl(fd, F_PREALLOCATE, &store);
    if (-1 == ret) {
        // OK, perhaps we are too fragmented, allocate non-continuous
        store.fst_flags = F_ALLOCATEALL;
        ret = fcntl(fd, F_PREALLOCATE, &store);
        if (-1 == ret) return false;
    }
    
    return 0 == ftruncate(fd, length);
}

static bool do_truncate_size(int fd,ssize_t size) {
    if (allocate_file(fd, size)) {
        SDKLog("truncate success %dKB",size/1024);
        return true;
    }
    
    SDKLog("truncate error errno=%d",errno);
    return false;
}

static void do_truncate(int fd) {
    if (do_truncate_size(fd, needDiskSpace)) {
        return;
    }
    if (do_truncate_size(fd, needDiskSpace/2)) {
        return;
    }
    if (do_truncate_size(fd, needDiskSpace/4)) {
        return;
    }
}

int create_exception(void) {
    if (buffer!=FileBufferInvalid) {
        close(buffer);
        buffer = FileBufferInvalid;
    }
    const char *tmp_path = HMDCrashDirectory_exception_tmp_path();
    FileBuffer fd = FileBufferInvalid;
    if((fd = hmd_file_open_buffer(tmp_path)) != FileBufferInvalid) {
        do_truncate(fd);
        int retValue = errno;
        if (retValue!=ENOSPC && buffer == FileBufferInvalid) {
            buffer = fd;
            tmpExceptionFinish();
        }
        else {
            close(fd);
        }
        return retValue;
    }
    SDKLog_error("failed to create exception file for path %s", tmp_path);
    return errno;
}

bool fd_is_valid(int fd)
{
    return fcntl(fd, F_GETFD) != -1 || errno != EBADF;
}

bool open_exception(void) {
    int i = 0;
    while (!tmpExceptionIsFinished() && i<1000) {
        i++;
        usleep(1000); // 1ms
    }
    
    const char *file_path = HMDCrashDirectory_exceptionPath();
    const char *tmp_path = HMDCrashDirectory_exception_tmp_path();
    
    if (i < 1000 || tmpExceptionIsFinished()) {
        if (rename(tmp_path, file_path) == 0) {
            SDKLog("rename file from truncate");
        }
    }
    else {
        SDKLog("tmp exception file not exist");
    }
    
    if (buffer!= FileBufferInvalid) {
        if ((access(file_path, F_OK) != 0) ||  (!fd_is_valid(buffer))) buffer = FileBufferInvalid;
    }
    
    if((buffer!= FileBufferInvalid) || ((buffer = hmd_file_open_buffer(file_path)) != FileBufferInvalid)) {
        if (!hmd_crash_switch_state(HMDCrashSwitchWriteImageOnCrash)) {
            long long wait_time = HMDCrashWaitForImagesSetupFinish(1000);
            if (wait_time > 0) {
                SDKLog_warn("wait binary images setup for %dms",wait_time);
            } else if (wait_time < 0) {
                SDKLog_warn("wait binary images setup time out");
            }
        }
        return true;
    }
    SDKLog_error("failed to open exception file for url %s", file_path);
    return false;
}

void basic_info(hmdcrash_detector_context_t *ctx) {
    uint64_t crash_time = (uint64_t)(ctx->crash_time * 1000);
    hmd_file_begin_json_object(buffer);
    
    hmd_file_write_key(buffer, "exception");
    hmd_file_write_string(buffer, ":");
    
    hmd_file_begin_json_object(buffer);
    hmd_file_write_key_and_uint64(buffer, "crash_time", crash_time);
    hmd_file_write_string(buffer, ",");
    hmd_file_write_key_and_uint64(buffer, "fault_address", (uint64_t)ctx->fault_address);

    
    switch (ctx->crash_type) {
        case HMDCrashTypeMachException: {
            hmd_file_write_string(buffer, ",");
            hmd_file_write_key_and_string(buffer, "type", "MACH_Exception");
            hmd_file_write_string(buffer, ",");
            hmd_file_write_key_and_uint64(buffer, "mach_type", ctx->mach.type);
            hmd_file_write_string(buffer, ",");
            hmd_file_write_key_and_uint64(buffer, "mach_code", ctx->mach.code);
            hmd_file_write_string(buffer, ",");
            hmd_file_write_key_and_uint64(buffer, "mach_subcode", ctx->mach.subcode);
        }
            break;
        case HMDCrashTypeNSException: {
            const char *name = ctx->ns_exception.name;
            const char *reason = ctx->ns_exception.reason;
            
            hmd_file_write_string(buffer, ",");
            hmd_file_write_key_and_string(buffer, "type", "NSException");
            hmd_file_write_string(buffer, ",");
            hmd_file_write_key_and_hex(buffer, "name", name);
            hmd_file_write_string(buffer, ",");
            hmd_file_write_key_and_hex(buffer, "reason", reason);
            
        }
            break;
        case HMDCrashTypeCPlusPlus: {
            const char *name = ctx->cpp_exception.name;
            const char *description = ctx->cpp_exception.description;

            hmd_file_write_string(buffer, ",");
            hmd_file_write_key_and_string(buffer, "type", "CPP_Exception");
            hmd_file_write_string(buffer, ",");
            hmd_file_write_key_and_hex(buffer, "name", name);
            hmd_file_write_string(buffer, ",");
            hmd_file_write_key_and_hex(buffer, "reason", description);
        }
            break;
        case HMDCrashTypeFatalSignal: {
            hmd_file_write_string(buffer, ",");
            hmd_file_write_key_and_string(buffer, "type", "FATAL_SIGNAL");
            hmd_file_write_string(buffer, ",");
            hmd_file_write_key_and_int64(buffer, "signum", ctx->signal.signum);
            hmd_file_write_string(buffer, ",");
            hmd_file_write_key_and_int64(buffer, "sigcode", ctx->signal.sigcode);
        }
            break;
        default:
            SDKLog_error("unkown exception type %d", (int)ctx->crash_type);
            break;
    }

    hmd_file_end_json_object(buffer);
    hmd_file_end_json_object(buffer);
    hmd_file_write_string(buffer, "\n");
}

void begin_threads(void) {
    hmd_file_begin_json_object(buffer);
    hmd_file_write_key(buffer, "threads");
    hmd_file_write_string(buffer, ":");
    hmd_file_begin_json_array(buffer);
}

void begin_thread(bool is_crashed, bool first_entry) {
    if (!first_entry) {
        hmd_file_write_string(buffer, ",");
    }
    
    hmd_file_begin_json_object(buffer);
    if (is_crashed) {
        hmd_file_write_key_and_bool(buffer, "crashed", true);
        hmd_file_write_string(buffer, ",");
    }
}

void begin_register(void) {
    hmd_file_write_key(buffer, "registers");
    hmd_file_write_string(buffer, ":");
    hmd_file_begin_json_object(buffer);
}

void register_info(const char *name, uintptr_t value, bool first_entry) {
    if(name == NULL) {
        name = "INVALID";
    }
    if(!first_entry) {
        hmd_file_write_string(buffer, ",");
    }
    hmd_file_write_key_and_uint64(buffer, name, value);
}

void end_register(void) {
    hmd_file_end_json_object(buffer);
}

void begin_backtrace(void) {
    hmd_file_write_string(buffer, ",");
    hmd_file_write_key(buffer, "stacktrace");
    hmd_file_write_string(buffer, ":");
    hmd_file_begin_json_array(buffer);
}

void backtrace_address(uintptr_t address,bool first_entry) {
    if (!first_entry) {
        hmd_file_write_string(buffer, ",");
    }
    hmd_file_write_uint64(buffer, address);
}

void backtrace_batch(uintptr_t *addr_array, size_t count) {
    for(size_t index = 0; index < count; index++) backtrace_address(addr_array[index],index==0);
}

void end_backtrace(void) {
    hmd_file_end_json_array(buffer);
}

void end_thread(void) {
    hmd_file_end_json_object(buffer);
}

void end_threads(void) {
    hmd_file_end_json_array(buffer);
    hmd_file_end_json_object(buffer);
    hmd_file_write_string(buffer, "\n");
}

void hmd_crash_begin_stack_record(void) {
    hmd_file_begin_json_object(buffer);
    hmd_file_write_key(buffer, "stack_record");
    hmd_file_write_string(buffer, ":");
    hmd_file_begin_json_object(buffer);
}

void hmd_crash_stack_record_thread_name(char *str) {
    hmd_file_write_key_and_string(buffer, "thread_name", str);
}

void hmd_crash_stack_record_backtrace(uintptr_t *backtraces,size_t length) {
    begin_backtrace();
    backtrace_batch(backtraces,length);
    end_backtrace();
}

void hmd_crash_end_stack_record(void) {
    hmd_file_end_json_object(buffer);
    hmd_file_end_json_object(buffer);
    hmd_file_write_string(buffer, "\n");
}

void begin_runtime_info(void) {
    hmd_file_begin_json_object(buffer);
    hmd_file_write_key(buffer, "runtime_info");
    hmd_file_write_string(buffer, ":");
    hmd_file_begin_json_object(buffer);
}

void write_runtime_sel(const char *sel) {
    hmd_file_write_key_and_string(buffer, "sel", sel);
    hmd_file_write_string(buffer, ",");
}

void begin_crash_infos(void) {
    hmd_file_write_key(buffer, "crash_infos");
    hmd_file_write_string(buffer, ":");
    hmd_file_begin_json_array(buffer);
}

void write_crash_info(const char *crash_info, bool first_entry) {
    if (!first_entry) {
        hmd_file_write_string(buffer, ",");
    }
    hmd_file_write_hex_string_value(buffer, crash_info);
}

void end_crash_infos(void) {
    hmd_file_end_json_array(buffer);
}

void end_runtime_info(void) {
    hmd_file_end_json_object(buffer);
    hmd_file_end_json_object(buffer);
    hmd_file_write_string(buffer, "\n");
}

void begin_dispatch_name(void) {
    hmd_file_begin_json_object(buffer);
    hmd_file_write_key(buffer, "dispatch_name");
    hmd_file_write_string(buffer, ":");
    hmd_file_begin_json_array(buffer);
}

void write_dispatch_name(const char *name, bool first_entry) {
    if (!first_entry) {
        hmd_file_write_string(buffer, ",");
    }
    hmd_file_write_string_value(buffer, name);
}

void end_dispatch_name(void) {
    hmd_file_end_json_array(buffer);
    hmd_file_end_json_object(buffer);
    hmd_file_write_string(buffer, "\n");
}

void begin_pthread_name(void) {
    hmd_file_begin_json_object(buffer);
    hmd_file_write_key(buffer, "pthread_name");
    hmd_file_write_string(buffer, ":");
    hmd_file_begin_json_array(buffer);
}

void write_pthread_name(const char *name, bool first_entry) {
    if (!first_entry) {
        hmd_file_write_string(buffer, ",");
    }
    hmd_file_write_string_value(buffer, name);
}

void end_pthread_name(void) {
    hmd_file_end_json_array(buffer);
    hmd_file_end_json_object(buffer);
    hmd_file_write_string(buffer, "\n");
}

void process_stats(void) {
    hmd_MemoryBytesExtend extend_memory = hmd_getMemoryBytesExtend();
    hmd_file_begin_json_object(buffer);
    hmd_file_write_key(buffer, "process_stats");
    hmd_file_write_string(buffer, ":");
    hmd_file_begin_json_object(buffer);
    hmd_file_write_key_and_uint64(buffer, "free_bytes", extend_memory.memoryBytes.availabelMemory);
    hmd_file_write_string(buffer, ",");
    hmd_file_write_key_and_uint64(buffer, "app_used_bytes", extend_memory.memoryBytes.appMemory);
    hmd_file_write_string(buffer, ",");
    hmd_file_write_key_and_uint64(buffer, "total_bytes", extend_memory.memoryBytes.totalMemory);
    hmd_file_write_string(buffer, ",");
    hmd_file_write_key_and_uint64(buffer, "used_bytes", extend_memory.memoryBytes.usedMemory);
    hmd_file_write_string(buffer, ",");
    hmd_file_write_key_and_uint64(buffer, "total_virtual_memory", extend_memory.totalVirtualMemory);
    hmd_file_write_string(buffer, ",");
    hmd_file_write_key_and_uint64(buffer, "used_virtual_memory", extend_memory.virtualMemory);
    hmd_file_end_json_object(buffer);
    hmd_file_end_json_object(buffer);
    hmd_file_write_string(buffer, "\n");
}

void write_storage(void) {
    struct statfs s;
    const char *path = HMDCrashDirectory_homePath();
    int ret = statfs(path, &s);
    if (ret == 0) {
        unsigned long long total = s.f_blocks * s.f_bsize;
        unsigned long long free = s.f_bavail * s.f_bsize;
        hmd_file_begin_json_object(buffer);
        hmd_file_write_key(buffer, "storage");
        hmd_file_write_string(buffer, ":");
        hmd_file_begin_json_object(buffer);
        hmd_file_write_key_and_uint64(buffer, "free", free);
        hmd_file_write_string(buffer, ",");
        hmd_file_write_key_and_uint64(buffer, "total", total);
        hmd_file_end_json_object(buffer);
        hmd_file_end_json_object(buffer);
        hmd_file_write_string(buffer, "\n");
    }
}

static void dynamic_data_enumerate_callback(hmd_async_dict_entry entry,int index,bool *stop,void *ctx) {
    bool *is_first_entry = ctx;
    bool write_dot = true;
    if (is_first_entry) {
        if (*is_first_entry) {
            write_dot = false;
        }
        *is_first_entry = false;
    }
    if (write_dot) {
        hmd_file_write_string(buffer, ",");
    }
    hmd_file_write_key_and_hex(buffer, entry.key, entry.value);
}

static void extra_dynamic_data_enumerate_callback(const char *key, const char *value, void *ctx) {
    bool *is_first_entry = ctx;
    bool write_dot = true;
    if (is_first_entry) {
        if (*is_first_entry) {
            write_dot = false;
        }
        *is_first_entry = false;
    }
    if (write_dot) {
        hmd_file_write_string(buffer, ",");
    }
    hmd_file_write_key_and_hex(buffer, key, value);
}

void HMDCrashWriteDynamicData(void) {
    hmd_file_begin_json_object(buffer);
    hmd_file_write_key(buffer, "dynamic");
    hmd_file_write_string(buffer, ":");
    hmd_file_begin_json_object(buffer);
    
    bool first_entry = true;
    hmd_crash_async_enumerate_entries(dynamic_data_enumerate_callback, &first_entry);

    hmd_file_end_json_object(buffer);
    hmd_file_end_json_object(buffer);
    hmd_file_write_string(buffer, "\n");
}

void HMDCrashWriteExtraDynamicData(uint64_t crash_time, uint64_t fault_address, thread_t current_thread, thread_t crash_thread) {
    hmd_file_begin_json_object(buffer);
    hmd_file_write_key(buffer, "extra_dynamic");
    hmd_file_write_string(buffer, ":");
    hmd_file_begin_json_object(buffer);
    
    bool first_entry = true;
    hmd_crash_async_enumerate_extra_dynamic_data(crash_time, fault_address, current_thread, crash_thread,  extra_dynamic_data_enumerate_callback, &first_entry);

    hmd_file_end_json_object(buffer);
    hmd_file_end_json_object(buffer);
    hmd_file_write_string(buffer, "\n");
}

void HMDCrashWriteGWPASanInfo(const char *asanStr, uintptr_t *allocateTrace, int allocateTraceLen, uintptr_t *deallocateTrace, int deallocateTraceLen) {
    int fd = hmd_file_open_buffer(HMDCrashDirectory_gwpasan_info_path());
    if (fd < 0) {
        return;
    }
    hmd_file_begin_json_object(fd);
    hmd_file_write_key(fd, "gwpasan");
    hmd_file_write_string(fd, ":");
    hmd_file_write_string(fd, asanStr);
    if (allocateTraceLen > 0) {
        hmd_file_write_string(fd, ",");
        hmd_file_write_key(fd, "allocate");
        hmd_file_write_string(fd, ":");
        hmd_file_begin_json_object(fd);
        hmd_file_write_key_and_string(fd, "threadName", "memory_allocate_backtrace");
        hmd_file_write_string(fd, ",");
        hmd_file_write_key(fd, "backtrace");
        hmd_file_write_string(fd, ":");
        hmd_file_begin_json_array(fd);
        for (size_t index = 0; index < allocateTraceLen; index++) {
            if (index != 0) {
                hmd_file_write_string(fd, ",");
            }
            hmd_file_write_uint64(fd, allocateTrace[index]);
        }
        hmd_file_end_json_array(fd);
        hmd_file_end_json_object(fd);
    }
    if (deallocateTraceLen > 0) {
        hmd_file_write_string(fd, ",");
        hmd_file_write_key(fd, "deallocate");
        hmd_file_write_string(fd, ":");
        hmd_file_begin_json_object(fd);
        hmd_file_write_key_and_string(fd, "threadName", "memory_deallocate_backtrace");
        hmd_file_write_string(fd, ",");
        hmd_file_write_key(fd, "backtrace");
        hmd_file_write_string(fd, ":");
        hmd_file_begin_json_array(fd);
        for (size_t index = 0; index < deallocateTraceLen; index++) {
            if (index != 0) {
                hmd_file_write_string(fd, ",");
            }
            hmd_file_write_uint64(fd, deallocateTrace[index]);
        }
        hmd_file_end_json_array(fd);
        hmd_file_end_json_object(fd);
    }
    hmd_file_end_json_object(fd);
    close(fd);
}

bool hmd_file_write_content(int fd, HMDCrashObjectInfo *info) {
    hmd_file_write_key(fd, "content");
    hmd_file_write_string(fd, ":");
    return HMDCrashWriteClassInfo(fd, info);
}

static void write_objc_info(int fd, HMDCrashObjectInfo *info) {
    if (!info) {
        return;
    }
    
    hmd_file_write_key(fd, "objc");
    hmd_file_write_string(fd, ":");
    hmd_file_begin_json_object(fd);
    hmd_file_write_key_and_bool(fd, "is_tagpointer", info->is_tagpointer);
    hmd_file_write_string(fd, ",");
    hmd_file_write_key_and_bool(fd, "is_aligned", info->is_aligned);
    hmd_file_write_string(fd, ",");
    hmd_file_write_key_and_bool(fd, "is_object", info->is_object);
    hmd_file_write_string(fd, ",");
    hmd_file_write_key_and_bool(fd, "is_class", info->is_class);
    hmd_file_write_string(fd, ",");
    hmd_file_write_key_and_uint64(fd, "isa", info->isa);
    hmd_file_write_string(fd, ",");
    hmd_file_write_key_and_uint64(fd, "cf_typeID", info->cf_typeID);
    hmd_file_write_string(fd, ",");
    hmd_file_write_key_and_string(fd, "class_name", info->class_name);
    
    if (hmd_crash_switch_state(HMDCrashSwitchContentAnalysis)) {
        bool needAnalyze = HMDFetchAnalyzeTypes() & HMDFetchObjectClassType(info);
        if (needAnalyze) {
            hmd_file_write_string(fd, ",");
            hmd_file_write_content(fd, info);
        }
    }
    
    hmd_file_end_json_object(fd);
}

static void write_string_info(int fd, HMDCrashStringInfo *info) {
    if (!info) {
        return;
    }
    hmd_file_write_key_and_hex(fd, "str_value", info->buffer);
}

void HMDCrashWriteAddressAnalyze(int fd, const char *name, uintptr_t value) {
    hmd_file_begin_json_object(fd);
    hmd_file_write_key_and_string(fd, "name", name);
    hmd_file_write_string(fd, ",");
    hmd_file_write_key_and_uint64(fd, "value", value);

    {
        HMDCrashObjectInfo objcInfo = {0};
        if (HMDCrashGetObjectInfo((void *)value, &objcInfo)) {
            hmd_file_write_string(fd, ",");
            write_objc_info(fd, &objcInfo);
        }
    }
    
    {
        HMDCrashStringInfo stringInfo = {0};
        if (HMDCrashGetStringInfo((void *)value, &stringInfo)) {
            hmd_file_write_string(fd, ",");
            write_string_info(fd, &stringInfo);
        }
    }
    hmd_file_end_json_object(fd);
    hmd_file_write_string(fd, "\n");
}

static void write_stack_address_analyze(int fd, uintptr_t stack_address, uintptr_t value) {
    hmd_file_begin_json_object(fd);
    hmd_file_write_key_and_uint64(fd, "address", stack_address);
    hmd_file_write_string(fd, ",");
    hmd_file_write_key_and_uint64(fd, "value", value);

    {
        HMDCrashObjectInfo objcInfo = {0};
        if (HMDCrashGetObjectInfo((void *)value, &objcInfo)) {
            hmd_file_write_string(fd, ",");
            write_objc_info(fd, &objcInfo);
        }
    }
    
    {
        HMDCrashStringInfo stringInfo = {0};
        if (HMDCrashGetStringInfo((void *)value, &stringInfo)) {
            hmd_file_write_string(fd, ",");
            write_string_info(fd, &stringInfo);
        }
    }
    
    hmd_file_end_json_object(fd);
    hmd_file_write_string(fd, "\n");
}


void HMDCrashStackAnalyze(int fd, uintptr_t sp, uint32_t max_count) {
    uintptr_t stack_address = sp;
    void *value = NULL;
    int count = 0;
    while (hmd_async_read_memory(stack_address, &value, sizeof(void *)) == HMD_ESUCCESS) {
        write_stack_address_analyze(fd, stack_address, (uintptr_t)value);
        stack_address += sizeof(void *);
        count++;
        if (count >= max_count) {
            break;
        }
    }
    SDKLog("stack address count %d",count);
}

void HMDCrashWriteVMMap(int max_vmmap) {
    int fd = hmd_file_open_buffer(HMDCrashDirectory_vmmap_path());
    if (fd < 0) {
        return;
    }
    kern_return_t kret;
#ifdef __LP64__
    struct vm_region_submap_info_64 info;
#else
    struct vm_region_submap_info info;
#endif
    vm_address_t addr = 0;
    vm_size_t size = 0;
    mach_msg_type_number_t count = 0;
    natural_t depth = 0;

    int region_count = 0;
    for (;;) {
        while (1) {
#ifdef __LP64__
            count = VM_REGION_SUBMAP_INFO_COUNT_64;
            kret = vm_region_recurse_64(current_task(), &addr, &size, &depth, (vm_region_recurse_info_t)&info, &count);
#else
            count = VM_REGION_SUBMAP_INFO_COUNT;
            kret = vm_region_recurse(current_task(), &addr, &size, &depth, (vm_region_recurse_info_t)&info, &count);
#endif
            if (KERN_SUCCESS != kret)
                break;
            if (addr + size > VM_MAX_ADDRESS)
                break;
            if (info.is_submap) {
                depth++;
            } else {
                break;
            }
        }
        if (KERN_SUCCESS != kret) break;

        hmd_file_begin_json_object(fd);
        hmd_file_write_key_and_uint64(fd, "user_tag", info.user_tag);
        hmd_file_write_string(fd, ",");
        hmd_file_write_key_and_uint64(fd, "base", addr);
        hmd_file_write_string(fd, ",");
        hmd_file_write_key_and_uint64(fd, "size", size);
        hmd_file_write_string(fd, ",");
        hmd_file_write_key_and_uint64(fd, "resident_size", info.pages_resident*vm_kernel_page_size);
        hmd_file_write_string(fd, ",");
        hmd_file_write_key_and_uint64(fd, "dirty_size", info.pages_dirtied*vm_kernel_page_size);
        hmd_file_write_string(fd, ",");
        hmd_file_write_key_and_uint64(fd, "swapped_size", info.pages_swapped_out*vm_kernel_page_size);
        hmd_file_write_string(fd, ",");
        hmd_file_write_key_and_uint64(fd, "protection", info.protection);
        hmd_file_write_string(fd, ",");
        hmd_file_write_key_and_uint64(fd, "max_protection", info.max_protection);
        hmd_file_write_string(fd, ",");
        hmd_file_write_key_and_uint64(fd, "share_mode", info.share_mode);
        hmd_file_write_string(fd, ",");
        hmd_file_write_key_and_uint64(fd, "external_pager", info.external_pager);

        if (info.external_pager) {
            char filename[MAXPATHLEN] = {0};
            int ret = hmdcrash_filename(addr, filename, sizeof(filename));
            if (ret != 0) {
                hmd_file_write_string(fd, ",");
                hmd_file_write_key_and_string(fd, "file", filename);
            }
        }
        
        hmd_file_end_json_object(fd);
        
        hmd_file_write_string(fd, "\n");
        addr += size;
        
        region_count++;
        if ((max_vmmap > 0) && (region_count >= max_vmmap)) {
            break;
        }
    }
    if (fd >= 0) {
        close(fd);
    }
    SDKLog("region count : %d",region_count);
}

void close_exception(void) {
    hmd_file_close_buffer(buffer);
    catch_finish();
}

void HMDCrashWriteScriptStack(char *crash_data){
    hmd_file_begin_json_object(buffer);
    hmd_file_write_key_and_hex(buffer, "game_script_stack", crash_data);
    hmd_file_end_json_object(buffer);
    
    hmd_file_write_string(buffer, "\n");
}

#pragma mark - extra crash_info

static FileBuffer crash_info_buffer;

bool HMDCrashOpenExtraCrashInfoFile(void) {
    const char *file_path = HMDCrashDirectory_crash_info_path();
    if ((crash_info_buffer = hmd_file_open_buffer(file_path)) != FileBufferInvalid) {
        SDKLog_warn("open extra crash info file");
        return true;
    }
    SDKLog_error("failed to open extra crash info file for url %s", file_path);
    return false;
}

void HMDCrashBeginExtraCrashInfo(void) {
    hmd_file_begin_json_object(crash_info_buffer);
    hmd_file_write_key(crash_info_buffer, "crash_infos");
    hmd_file_write_string(crash_info_buffer, ":");
    hmd_file_begin_json_array(crash_info_buffer);
}

void HMDCrashWriteExtraCrashInfo(const char *crash_info, bool first_entry) {
    if (!first_entry) {
        hmd_file_write_string(crash_info_buffer, ",");
    }
    hmd_file_write_hex_string_value(crash_info_buffer, crash_info);
}

void HMDCrashEndExtraCrashInfo(void) {
    hmd_file_end_json_array(crash_info_buffer);
    hmd_file_end_json_object(crash_info_buffer);
    hmd_file_write_string(buffer, "\n");
}

void HMDCrashCloseExtraCrashInfoFile(void) {
    hmd_file_close_buffer(crash_info_buffer);
}
