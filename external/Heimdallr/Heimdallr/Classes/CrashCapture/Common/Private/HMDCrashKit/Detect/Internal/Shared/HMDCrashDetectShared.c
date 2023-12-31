//
//  HMDCrashDetectShared.c
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/11.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#include "HMDCrashDetectShared.h"
#include "hmd_machine_context.h"
#include "hmd_stack_cursor.h"
#include "hmd_stack_cursor_machine_context.h"
#include "HMDCrashException.h"
#include "HMDCrashSDKLog.h"
#include "HMDAsyncImageList.h"
#include "hmd_stack_cursor_self_thread.h"
#include "HMDCompactUnwind.hpp"
#include <objc/message.h>
#include "hmd_crash_async_stack_trace.h"
#include "HMDCrashMemoryBuffer.h"
#include "HMDCrashKitSwitch.h"
#include "HMDCrashFileBuffer.h"
#include "HMDCrashDirectory_LowLevel.h"
#include "HMDAsyncRegister.h"
#include "HMDCrashExtraDynamicData.h"
#include "HMDCrashHeader.h"
#include "HMDCrashException_fileDescriptor.h"
#include "HMDCrashException_dynamicData.h"
#include "HMDCrashDirectory_LowLevel.h"
#include "HMDCrashEnvironmentBinaryImages.h"
#include "HMDCrashAppExitReasonMark.h"

#define QUERY_THREAD_NAME_SIZE 256

#define HMD_MAX_FRAME_COUNT 100000

static void write_thread_backtrace(hmd_stack_cursor *stackCursor);
static void write_thread_register(const hmd_machine_context *machine_context);
static void write_thread_status(const hmd_machine_context *machine_context, int index);
static bool hmdcr_get_stack_cursor(const hmd_machine_context* const machineContext,
                                   hmd_stack_cursor *cursor);
static void hmd_crash_write_GWPAsan(struct hmdcrash_detector_context *crash_detector_context);
static void hmd_crash_write_fd_info(void);
static void hmd_crash_write_dynamic_data(struct hmdcrash_detector_context *crash_detector_context,
                                         struct hmd_crash_env_context *envContextPointer,
                                         thread_t crash_thread);
static void hmd_crash_write_vmmap(void);

void WEAK_FUNC hmd_handle_coredump(struct hmdcrash_detector_context *crash_detector_context, 
                                   struct hmd_crash_env_context *envContextPointer,
                                   bool force) {
    DEBUG_LOG("weak function %s called", __func__);
}

bool WEAK_FUNC detect_gwp_asan(uintptr_t fault_address, char *str, int strLen, uintptr_t *allocateTrace, 
                               int *allocateTraceLen, uintptr_t *deallocateTrace, int *deallocateTraceLen) {
    DEBUG_LOG("weak function %s called", __func__);
    return false;
}

static void write_runtime_objc_selector(struct hmd_machine_context *crash_context) {
#if defined(__arm__) || defined(__arm64__)
    uintptr_t pc = hmdmc_get_pc(crash_context);
    void *addr = objc_msgSend;
    if (pc >= (hmd_greg_t)addr && pc - (hmd_greg_t)addr <= 66) {
        uintptr_t x1 = hmdmc_register_value(crash_context,1);
        char temp[256];
        hmd_error_t err = hmd_async_read_string((hmd_vm_address_t)x1, temp, sizeof(temp));
        if (err == HMD_ESUCCESS) {
            write_runtime_sel(temp);
        } else {
            SDKLog("read objc selector error");
        }
    }
#endif
}

#define CRASH_ALIGN __attribute__((aligned(8)))
typedef struct {
    unsigned    version   CRASH_ALIGN;
    const char *message   CRASH_ALIGN;
    const char *signature CRASH_ALIGN;
    const char *backtrace CRASH_ALIGN;
    const char *message2  CRASH_ALIGN;
    void       *reserved  CRASH_ALIGN;
    void       *reserved2 CRASH_ALIGN;
} crash_info_t;

static void crash_info_callback(hmd_async_image_t *image, int index, bool *stop, void *ctx)
{
    hmd_async_mem_range crash_info = image->macho_image.crash_info;
    if (crash_info.size >= sizeof(crash_info_t)) {
        crash_info_t *info = (crash_info_t *)crash_info.addr;
        uintptr_t addr[4];
        addr[0] = (uintptr_t)info->message;
        addr[1] = (uintptr_t)info->signature;
        addr[2] = (uintptr_t)info->backtrace;
        addr[3] = (uintptr_t)info->message2;
        
        char buffer[256];
        for (int i = 0; i<sizeof(addr)/sizeof(uintptr_t); i++) {
            hmd_error_t err = hmd_async_read_string(addr[i], buffer, sizeof(buffer));
            if (err == HMD_ESUCCESS) {
                if (strlen(buffer) > 0) {
                    bool *is_first_crash_info = ctx;
                    if (is_first_crash_info) {
                        write_crash_info(buffer,*is_first_crash_info);
                        *is_first_crash_info = false;
                    }
                }
            }
        }
    }
}

static void write_runtime_info(struct hmd_machine_context *crash_context)
{
    SDKLog("start write runtime info");
    
    begin_runtime_info();
    
    write_runtime_objc_selector(crash_context);
    
    begin_crash_infos();
    
    // shared may not be setup during load launch
    if(hmd_async_share_image_list_has_setup()) {
        bool is_first_crash_info = true;
        hmd_async_enumerate_image_list(crash_info_callback,&is_first_crash_info);
    }
    
    end_crash_infos();
    
    end_runtime_info();
    
    SDKLog("finish write runtime info");
}

static void write_async_stack_record(struct hmd_machine_context *crash_context)
{
    SDKLog("start write stack record");
    
    thread_t crash_thread = THREAD_NULL;
    if (crash_context) {
        crash_thread = crash_context->thread;
    }
    if (crash_thread == THREAD_NULL) {
        crash_thread = mach_thread_self();
    }
    
    hmd_async_stack_reading(true);
    hmd_async_stack_record_t *record = hmd_async_stack_trace_mach_thread(crash_thread);
    hmd_async_stack_record_t safe_record;
    if (hmd_async_read_memory((hmd_vm_address_t)record, &safe_record, sizeof(safe_record)) == HMD_ESUCCESS) {
        if (safe_record.thread == crash_thread && safe_record.valid) {
            hmd_crash_begin_stack_record();
            hmd_crash_stack_record_thread_name(safe_record.thread_name);
            hmd_crash_stack_record_backtrace((uintptr_t*)&safe_record.backtrace[safe_record.skip_length], safe_record.length - safe_record.skip_length);
            hmd_crash_end_stack_record();
        }
    }
    
    hmd_async_stack_reading(false);
    SDKLog("finish write stack record");
}

static void hmd_crash_write_address_analyze(struct hmd_machine_context *crash_context) {
    if (crash_context == NULL || crash_context->isCurrentThread) {
        return;
    }
    
    int fd = -1;
    if (hmd_crash_switch_state(HMDCrashSwitchRegisterAnalysis)) {
        if (fd < 0) {
            fd = hmd_file_open_buffer(HMDCrashDirectory_memory_analyze_path());
        }
        if (fd < 0) {
            return;
        }
        SDKLog("start register analyze");
        int common_num = hmdmc_num_registers();
        for(int index = 0; index < common_num; index++) {
            const char *name = hmdmc_register_name(index);
            uintptr_t value = (uintptr_t)hmdmc_register_value(crash_context, index);
            HMDCrashWriteAddressAnalyze(fd, name, value);
        }
        int exception_num = hmdmc_num_exception_registers();
        for(int index = 0; index < exception_num; index++) {
            const char *name = hmdmc_exception_register_name(index);
            uintptr_t value = (uintptr_t)hmdmc_exception_register_value(crash_context, index);
            HMDCrashWriteAddressAnalyze(fd, name, value);
        }
        SDKLog("finish register analyze");
    }
    
    if (hmd_crash_switch_state(HMDCrashSwitchStackAnalysis)) {
        if (fd < 0) {
            fd = hmd_file_open_buffer(HMDCrashDirectory_memory_analyze_path());
        }
        if (fd < 0) {
            return;
        }
        SDKLog("start stack analyze");
        uintptr_t sp = hmdmc_get_sp(crash_context);
        uint32_t max_count = hmd_crash_stack_trace_count();
        HMDCrashStackAnalyze(fd, sp, max_count);
        SDKLog("finish stack analyze");
    }
    
    if (fd >= 0) {
        close(fd);
    }
}

static void hmd_crash_write_core_dump(struct hmdcrash_detector_context *crash_detector_context, struct hmd_crash_env_context *envContextPointer) {
    
    bool force_coredump = false;
    if(crash_detector_context->asan_detected && hmd_crash_switch_state(HMDCrashSwitchCoreDumpIfAsan)) {
         force_coredump = true;
    }
    
    hmd_handle_coredump(crash_detector_context, envContextPointer, force_coredump);
}

void hmd_crash_handler(struct hmd_crash_env_context *envContextPointer, struct hmdcrash_detector_context *crash_detector_context)
{
    SDKLog("crash written begin");
    struct hmd_machine_context *crash_machine_context = envContextPointer->crash_machine_ctx;
    thread_t crash_thread = THREAD_NULL;
    if (crash_machine_context) {
        envContextPointer->current_thread = crash_machine_context->working_thread;
        crash_thread = crash_machine_context->thread;
    }
    if (envContextPointer->current_thread == THREAD_NULL) {
        envContextPointer->current_thread = mach_thread_self();
    }
    if (crash_thread == THREAD_NULL) {
        crash_thread = envContextPointer->current_thread;
    }

    if (crash_detector_context->crash_type == HMDCrashTypeCPlusPlus || crash_detector_context->crash_type == HMDCrashTypeNSException) {
        hmdmc_suspendEnvironment(envContextPointer);
    }
    
    thread_act_t backup_thread_list[2];
    if (envContextPointer->thread_count == 0) {
        
        backup_thread_list[0] = crash_thread;
        backup_thread_list[1] = envContextPointer->current_thread;

        envContextPointer->thread_list = backup_thread_list;
        if (crash_thread == envContextPointer->current_thread) {
            envContextPointer->thread_count = 1;
        }else{
            envContextPointer->thread_count = 2;
        }
    }
    
    SDKLog("begin threads");
    begin_threads();
    
    KSMC_NEW_CONTEXT(machine_ctx);
    machine_ctx->working_thread = envContextPointer->current_thread;
    for(int index = 0; index < envContextPointer->thread_count; index++) {
        hmd_thread thread = envContextPointer->thread_list[index];
        bool crashed = thread == crash_thread;
        if(crashed) {
            if (crash_machine_context) {
                write_thread_status(crash_machine_context, index);
            }else{
                hmdmc_get_state_with_thread(thread, machine_ctx, true);
                write_thread_status(machine_ctx, index);
            }
        } else {
            hmdmc_get_state_with_thread(thread, machine_ctx, false);
            write_thread_status(machine_ctx, index);           // machineContext
        }
    }
    
    end_threads();
    
    if(!HMDCrashEnvironmentBinaryImages_is_mainFile_mostly_finished()) {
        SDKLog("write realtime binary images");
        HMDCrashEnvironmentBinaryImages_save_sync_nonBlocked_realTimeFile();
    }
    
    write_async_stack_record(crash_machine_context);
    
    if(crash_machine_context) {
        write_runtime_info(crash_machine_context);
    }
    
    char thread_name_buffer[QUERY_THREAD_NAME_SIZE];
    
    SDKLog("begin dispatch name");
    begin_dispatch_name();
    for(int index = 0; index < envContextPointer->thread_count; index++) {
        hmd_thread thread = envContextPointer->thread_list[index];
        bool rt = hmdthread_getQueueName(thread, thread_name_buffer, sizeof(thread_name_buffer));
        if(rt) write_dispatch_name(thread_name_buffer,index == 0);
        else write_dispatch_name("",index == 0);
    }
    end_dispatch_name();
    
    SDKLog("begin pthread name");
    begin_pthread_name();
    for(int index = 0; index < envContextPointer->thread_count; index++) {
        hmd_thread thread = envContextPointer->thread_list[index];
        bool rt = hmdthread_getThreadName(thread, thread_name_buffer, sizeof(thread_name_buffer));
        if(rt) write_pthread_name(thread_name_buffer,index == 0);
        else write_pthread_name("",index == 0);
    }
    end_pthread_name();
    
    SDKLog("begin process status");
    process_stats();
    
    SDKLog("begin write storage");
    write_storage();
    
    close_exception();
    SDKLog("all exceptions shutdown complete :>");
    
    hmd_crash_write_GWPAsan(crash_detector_context);
    
    hmd_crash_write_dynamic_data(crash_detector_context, envContextPointer, crash_thread);
    
    hmd_crash_write_vmmap();
    
    hmd_crash_write_address_analyze(crash_machine_context);
    
    hmd_crash_write_core_dump(crash_detector_context, envContextPointer);
    
    hmdmc_resumeEnvironment(envContextPointer);
    
    HMDCrashKit_markAppExitReasonCrash();
    
    hmd_crash_write_fd_info();
    
    envContextPointer->thread_list = NULL;
    envContextPointer->thread_count = 0;
    
    SDKLog("crash written end");
    
    HMDCrashStopDetect();
}

static void hmd_crash_write_vmmap(void) {
    if (hmd_crash_switch_state(HMDCrashSwitchVMMap)) {
        SDKLog("write vmmap");
        HMDCrashWriteVMMap(hmd_crash_max_vmmap());
    }
}

static void hmd_crash_write_fd_info(void) {
    if (hmd_crash_switch_state(HMDCrashSwitchExtendFD)) {
        if(hmd_exception_create_FD_info_file())
           hmd_exception_write_FD_info();
    }
}

static void hmd_crash_write_dynamic_data(struct hmdcrash_detector_context *crash_detector_context,
                                         struct hmd_crash_env_context *envContextPointer,
                                         thread_t crash_thread) {
    
    if(hmd_exception_dynamic_create_file()) {
        SDKLog("write dynamic data");
        
        hmd_exception_dynamic_write_dynamic_info();
        
        uint64_t crash_time = crash_detector_context->crash_time * 1000;
        uint64_t fault_address = crash_detector_context->fault_address;
        thread_t current_thread = envContextPointer->current_thread;
        
        hmd_exception_dynamic_write_extra_dynamic_info(crash_time, fault_address, current_thread, crash_thread);
        
        hmd_exception_dynamic_write_vid(crash_time, fault_address, current_thread, crash_thread);
        
        hmd_exception_dynamic_write_save_files();
        
        hmd_exception_dynamic_write_game_script_stack(crash_detector_context->crash_time * 1000,
                                                      fault_address, current_thread, crash_thread);
    }
}

static void hmd_crash_write_GWPAsan(struct hmdcrash_detector_context *crash_detector_context) {
    
    HMDCrashType crash_type = crash_detector_context->crash_type;
    if(crash_type != HMDCrashTypeMachException &&
       crash_type != HMDCrashTypeFatalSignal)
        return;
    
    #define HMD_ASAN_REASON_STRING_LENGTH 1024
    #define HMD_ASAN_MAX_BACKTRACE_COUNT  64
    
    char reasonString[HMD_ASAN_REASON_STRING_LENGTH + 1];
    
    uintptr_t fault_address = crash_detector_context->fault_address;
    
    uintptr_t allocateTrace[HMD_ASAN_MAX_BACKTRACE_COUNT];
    int       allocateLength = HMD_ASAN_MAX_BACKTRACE_COUNT;
    
    uintptr_t deallocateTrace[HMD_ASAN_MAX_BACKTRACE_COUNT];
    int       deallocateLength = HMD_ASAN_MAX_BACKTRACE_COUNT;
    
    bool detected_asan = detect_gwp_asan(fault_address,
                                         reasonString, HMD_ASAN_REASON_STRING_LENGTH,
                                         allocateTrace,   &allocateLength,
                                         deallocateTrace, &deallocateLength);
    
    if (!detected_asan) return;
    
    crash_detector_context->asan_detected = true;
    
    SDKLog("begin write GWPAsan");
    HMDCrashWriteGWPASanInfo(reasonString,
                             allocateTrace, allocateLength,
                             deallocateTrace, deallocateLength);
}

#pragma mark - backtrace

static void write_thread_status(const hmd_machine_context *machine_context, int index) {
    begin_thread(machine_context->isCrashedContext,index == 0);
    hmd_stack_cursor stackCursor;
    bool hasBacktrace = hmdcr_get_stack_cursor(machine_context, &stackCursor);
    if(hasBacktrace) {
        write_thread_register(machine_context);
        write_thread_backtrace(&stackCursor);
    }
    end_thread();
}

static void write_thread_register(const hmd_machine_context *machine_context) {
    begin_register();
    if (machine_context->isCrashedContext) {
        bool first_entry = true;
        int exception_num = hmdmc_num_exception_registers();
        for(int index = 0; index < exception_num; index++) {
            const char *name = hmdmc_exception_register_name(index);
            uintptr_t value = hmdmc_exception_register_value(machine_context, index);
            register_info(name, (uintptr_t)value, first_entry);
            first_entry = false;
        }
        int common_num = hmdmc_num_registers();
        for(int index = 0; index < common_num; index++) {
            const char *name = hmdmc_register_name(index);
            uintptr_t value = hmdmc_register_value(machine_context, index);
            register_info(name, (uintptr_t)value, first_entry);
            first_entry = false;
        }
    }
    end_register();
}

#define STACK_OVERFLOW_COUNT 200
#define STACK_SAVE_COUNT 50
#define MAX_FRAME_COUNT 100000

static void write_thread_backtrace(hmd_stack_cursor *stackCursor) {
    begin_backtrace();
    
    size_t backtrace_count = 0;
    
    while(stackCursor->advanceCursor(stackCursor))
    {
        uintptr_t address = stackCursor->stackEntry.address;
        backtrace_address(address,backtrace_count==0);
        
        // resolve stack-overflow
        if((backtrace_count += 1) >= STACK_OVERFLOW_COUNT) {
            
            SDKLog("most likely stack overflow happened!");

            uintptr_t last_backtrace[STACK_SAVE_COUNT];
            memset(last_backtrace, 0, sizeof(last_backtrace));
            int bt_index = 0;
            while(stackCursor->advanceCursor(stackCursor))
            {
                last_backtrace[bt_index] = stackCursor->stackEntry.address;
                bt_index = (bt_index + 1)%STACK_SAVE_COUNT;
                
                if (stackCursor->state.currentDepth-1 >= MAX_FRAME_COUNT) {
                    SDKLog_error("backtrace exceed max_frame_count, most likely in a infinate loop.");
                    break;
                }
            }
            
            int valid_addr_count = STACK_SAVE_COUNT;
            for (int i = 0; i < STACK_SAVE_COUNT; i++) {
                uintptr_t addr = last_backtrace[bt_index];
                if (addr > 0) {
                    stackCursor->stackEntry.address = addr;
                }
                valid_addr_count--;
                bt_index = (bt_index + 1)%STACK_SAVE_COUNT;
                backtrace_address(stackCursor->stackEntry.address,backtrace_count == 0);
            }
            
            SDKLog("total depth : %d",stackCursor->state.currentDepth-1);

            break;
        }
    }   //  break exit here
    
    end_backtrace();
}

static bool hmdcr_get_stack_cursor(const hmd_machine_context* const machine_context,
                                   hmd_stack_cursor *cursor) {
    if (machine_context->cursor != NULL) {
        *cursor = *(machine_context->cursor);
        return true;
    }
    
    if (machine_context->isCurrentThread) {
        hmdsc_init_self_thread_backtrace(cursor, 1);
        return true;
    }
    
    hmdsc_initWithMachineContext(cursor, machine_context);
    return true;
}
