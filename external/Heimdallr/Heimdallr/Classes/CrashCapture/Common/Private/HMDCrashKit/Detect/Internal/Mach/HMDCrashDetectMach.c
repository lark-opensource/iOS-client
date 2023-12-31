//
//  HMDCrashDetectMach.c
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/11.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#include <stdbool.h>
#include <stdatomic.h>
#include "HMDCrashDetectMach.h"
#include "HMDCrashDetect_Private.h"
#include "HMDCrashSDKLog.h"
#include "pthread_extended.h"
#include "hmd_machine_context.h"
#include "HMDCrashDetectShared.h"
#include "hmd_stack_cursor.h"
#include "hmd_stack_cursor_machine_context.h"
#include "hmd_mach.h"
#include "HMDTimeSepc.h"
#include "hmd_signal_info.h"
#include "HMDMachExceptionUtility.h"
#include "HMDCrashException.h"
#include "HMDCrashOnceCatch.h"
#include "hmd_stack_cursor.h"
#include "HMDCompactUnwind.hpp"
#include "hmd_crash_safe_tool.h"
#include "hmd_machine_context.h"

#if __LP64__
    #define MACH_ERROR_CODE_MASK 0xFFFFFFFFFFFFFFFF
#else
    #define MACH_ERROR_CODE_MASK 0xFFFFFFFF
#endif

#pragma mark - Static Information

static hmd_exception_ports old_ports;

hmd_mach_recover_function_t hmd_mach_recover_handle = NULL;

static mach_port_t exception_port = MACH_PORT_NULL;

static void *hmd_mach_server(void * const context);

static void record(hmd_exc_msg *request, struct hmd_crash_env_context *envContextPointer)
{
    hmdcrash_detector_context_t crash_context;
    memset(&crash_context, 0, sizeof(crash_context));
    crash_context.crash_time = HMD_XNUSystemCall_timeSince1970();
    crash_context.crash_type = HMDCrashTypeMachException;
    crash_context.mach.type = request->exception;
    crash_context.mach.code = request->code[0]&MACH_ERROR_CODE_MASK;
    crash_context.mach.subcode = request->code[1]&MACH_ERROR_CODE_MASK;
    
    //crash thread
    KSMC_NEW_CONTEXT(machineContext);
    machineContext->working_thread = envContextPointer->current_thread;
    hmdmc_get_state_with_thread(request->thread.name, machineContext, true);
    
    if (request->exception == EXC_BAD_ACCESS) {
        crash_context.fault_address = hmdmc_get_fault_address(machineContext);
    } else {
        crash_context.fault_address = hmdmc_get_pc(machineContext);
    }
    
    SDKLog("writing basic info");
    basic_info(&crash_context);
    
    hmd_stack_cursor cursor;
    hmdsc_initWithMachineContext(&cursor, machineContext);
    machineContext->cursor = &cursor;
    machineContext->fault_addr = crash_context.fault_address;
    
    envContextPointer->crash_machine_ctx = machineContext;

    SDKLog("calling crash handler");
    hmd_crash_handler(envContextPointer, &crash_context);
    SDKLog("crash handle finish");
}

static void unset(void)
{
    if(old_ports.count == 0)
    {
        return;
    }
    const task_t this_task = mach_task_self();
    kern_return_t kr;
    
    for(mach_msg_type_number_t i = 0; i < old_ports.count; i++)
    {
        kr = task_set_exception_ports(this_task,
                                      old_ports.masks[i],
                                      old_ports.ports[i],
                                      old_ports.behaviors[i],
                                      old_ports.flavors[i]);
        if (kr != KERN_SUCCESS) {
            SDKLog_error("restore exception ports error %d", kr);
        }
    }
    old_ports.count = 0;
}

static pthread_t setup_handler_thread(bool isbackup)
{
    bool attributes_created = false;
    pthread_attr_t attr;
    
    pthread_attr_init(&attr);
    attributes_created = true;
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    pthread_t thread;
    int error = pthread_create(&thread,
                               &attr,
                               &hmd_mach_server,
                               (void *)isbackup);
    
    if (error != 0) {
        if(attributes_created)
        {
            pthread_attr_destroy(&attr);
        }
    }
    if (error == 0) {
        return thread;
    }
    return NULL;
}


static bool setup(void)
{
    kern_return_t kr;
    
    const task_t this_task = mach_task_self();
    if(exception_port == MACH_PORT_NULL)
    {
        kr = mach_port_allocate(this_task,
                                MACH_PORT_RIGHT_RECEIVE,
                                &exception_port);
        if(kr != KERN_SUCCESS)
        {
            goto failed;
        }
        
        kr = mach_port_insert_right(this_task,
                                    exception_port,
                                    exception_port,
                                    MACH_MSG_TYPE_MAKE_SEND);
        if(kr != KERN_SUCCESS)
        {
            goto failed;
        }
    }
    
    exception_mask_t mask = EXC_MASK_BAD_ACCESS | EXC_MASK_BAD_INSTRUCTION | EXC_MASK_ARITHMETIC | EXC_MASK_SOFTWARE | EXC_MASK_BREAKPOINT | EXC_MASK_GUARD;

    kr = task_swap_exception_ports(this_task,
                                   mask,
                                   exception_port,
                                   EXCEPTION_DEFAULT|MACH_EXCEPTION_CODES,
                                   THREAD_STATE_NONE,
                                   old_ports.masks,
                                   &old_ports.count,
                                   old_ports.ports,
                                   old_ports.behaviors,
                                   old_ports.flavors
                                   );
    if(kr != KERN_SUCCESS)
    {
        goto failed;
    }

    pthread_t posix_thread = setup_handler_thread(false);
    if (posix_thread == NULL) {
        goto failed;
    }

    return true;
    
failed:

    unset();
    return false;
}

//#ifdef DEBUG
#include <sys/sysctl.h>
#include <unistd.h>
#include "hmd_debug.h"
//#endif
void HMDCrashDetect_mach_start(void) {
//#ifdef DEBUG
    bool is_trace = hmddebug_isBeingTraced();
    if(is_trace) {
        SDKLog_warn("being traced, stop detect mach exception");
        return;
    }
//#endif
    if (setup()) {
        SDKLog("mach detector launch complete");
    }else{
        SDKLog_error("mach detector launch failed with error");
    }
}

void HMDCrashDetect_mach_end(void) {
    unset();
    SDKLog("mach detector shutdown complete");
}


static void *hmd_mach_server(void * const is_backup) {
    
    pthread_setname_np("com.hmd.mach_server");
    
    hmd_exc_msg msg;
    hmd_exc_msg *request = &msg;
    memset(request, 0, sizeof(hmd_exc_msg)); //stack memory
    
    mach_msg_size_t request_size = sizeof(hmd_exc_msg);
    
    while (true) {
        // Wait for a message.
        mach_msg_return_t mr = mach_msg(&request->Head,
                                        MACH_RCV_MSG,
                                        0,
                                        request_size,
                                        exception_port,
                                        MACH_MSG_TIMEOUT_NONE,
                                        MACH_PORT_NULL);
        
        if(mr != MACH_MSG_SUCCESS) //break后会由signal handler捕获
        {
            SDKLog_error("receive msg error [request:%d][response:%d][ret:%d(%s)]",request_size,request->Head.msgh_size,mr,mach_error_string(mr));
            break;
        }
        
        SDKLog("receive mach msg [thread:%u][type:%p(%s)]",request->thread.name,request->exception,hmdmach_exceptionName(request->exception));
        
        hmd_mach_recover_function_t mach_handle = __atomic_load_n(&hmd_mach_recover_handle, __ATOMIC_ACQUIRE);
        if(mach_handle != NULL) {
            
            SDKLog_warn("mach recover handle obtained, will try to recover exception");
            bool process_result = mach_handle(request->task.name,
                                              request->thread.name,
                                              request->NDR,
                                              request->exception,
                                              request->codeCnt);
            
            if(process_result) {
                SDKLog_warn("mach recover process success, will reply message and continue process");
                goto mach_recover_jump_location;
            }
            SDKLog_warn("mach recover process failed, will begin to capture crash");
        }
        
        if (request->task.name != mach_task_self()) {
            //mis match task
            SDKLog_warn("miss match task, sending reply");
        }else{
            if (once_catch()) {
                //env info
                KSMC_NEW_ENV_CONTEXT(envContextPointer);
                envContextPointer->current_thread = mach_thread_self();
                hmdmc_suspendEnvironment(envContextPointer);
                SDKLog("handling mach exception");
                
                if (!open_exception()) {
                    SDKLog_error("mach server open exception failed");
                }
                
                // 这里面在 HMDCrashStopDetect 会 unset 然后调回系统实现
                record(request, envContextPointer);
                
            } else {
                thread_t thread = catch_thread();
                if (thread > 0 && thread == request->thread.name) {
                    SDKLog_error("catch thread crashed");
                } else {
                    SDKLog_error("crashed again");
                }
                wait_catch();
            }
            
            exception_type_t exception_type = request->exception;
            int state = hmdcrash_check_port_safe(exception_port,exception_type);
            if (state == 0) {
                SDKLog("port is safe");
            }else{
                SDKLog_error("port state:%d not safe, may cause death loop, exit.",state);
                exit(EXIT_FAILURE);
            }
        }
        
mach_recover_jump_location:
        
        SDKLog("reply msg sending...");
        hmd_reply_msg reply;
        /* Initialize the reply */
        memset(&reply, 0, sizeof(reply));
        reply.Head.msgh_bits = MACH_MSGH_BITS(MACH_MSGH_BITS_REMOTE(request->Head.msgh_bits), 0);
        reply.Head.msgh_local_port = MACH_PORT_NULL;
        reply.Head.msgh_remote_port = request->Head.msgh_remote_port;
        reply.Head.msgh_size = sizeof(reply);
        reply.NDR = request->NDR;
        reply.RetCode = KERN_SUCCESS;
        
        /*
         * Mach uses reply id offsets of 100. This is rather arbitrary, and in theory could be changed
         * in a future iOS release (although, it has stayed constant for nearly 24 years, so it seems unlikely
         * to change now). See the top-level file warning regarding use on iOS.
         *
         * On Mac OS X, the reply_id offset may be considered implicitly defined due to mach_exc.defs and
         * exc.defs being public.
         */
        reply.Head.msgh_id = request->Head.msgh_id + 100;
        mr = mach_msg(&reply.Head,
                      MACH_SEND_MSG,
                      reply.Head.msgh_size,
                      0,
                      MACH_PORT_NULL,
                      MACH_MSG_TIMEOUT_NONE,
                      MACH_PORT_NULL);
        
        SDKLog("reply mach msg [code:%p][reason:%s]",mr,mach_error_string(mr));
        
        if (mr != MACH_MSG_SUCCESS) {
            SDKLog("reply msg error, break.");
            break;
        }
        SDKLog("reply msg success"); //
    }
    
    SDKLog_warn("mach exception server thread exiting");
    return 0;
}

bool HMDCrashDetect_mach_check(void)
{
    const task_t this_task = mach_task_self();
    hmd_exception_ports ports;
    exception_mask_t mask = EXC_MASK_BAD_ACCESS | EXC_MASK_BAD_INSTRUCTION | EXC_MASK_ARITHMETIC | EXC_MASK_SOFTWARE | EXC_MASK_BREAKPOINT | EXC_MASK_GUARD;
    kern_return_t kr = task_get_exception_ports(this_task,
                                                mask,
                                                ports.masks,
                                                &ports.count,
                                                ports.ports,
                                                ports.behaviors,
                                                ports.flavors);
    if (kr == KERN_SUCCESS) {
        for(mach_msg_type_number_t i = 0; i < ports.count; i++)
        {
            exception_handler_t port = ports.ports[i];
            if (port != exception_port) {
                SDKLog_error("mach exception port is invalid");
                return false;
            }
        }
    } else {
        SDKLog_error("mach exception port check error kr = %d",kr);
        return true;
    }
    SDKLog("mach exception port is valid");
    return true;

}
