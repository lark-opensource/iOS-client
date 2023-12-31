//
//  HMDCrashDetectCPP.mm
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/12.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#include <dlfcn.h>
#include <cxxabi.h>
#include <atomic>
#include <exception>
#include <typeinfo>
#include <cstring>
#import <Foundation/Foundation.h>
#include "HMDCrashDetectCPP.h"
#include "HMDCrashSDKLog.h"
#include "hmd_stack_cursor.h"
#include "HMDCrashDetectShared.h"
#include "hmd_stack_cursor_self_thread.h"
#include "hmd_stack_cursor_backtrace.h"
#include "HMDTimeSepc.h"
#include "HMDCrashException.h"
#include "HMDCrashOnceCatch.h"
#include "HMDCrashMemoryBuffer.h"
#include "hmd_cpp_exception.hpp"
#include "HMDMacro.h"
#define CPP_REASON_SIZE 512


/*! @code cpp terminate handle
 
        调用链路如下
 
        std::terminate -> hmd_cpp_terminate_wrapped_handle -> hmd_cpp_terminate_process_handle
                                                           -> hmd_cpp_terminate_original_handle
 */

HMD_EXTERN void hmd_cpp_terminate_process_handle(void);
HMD_EXTERN void hmd_cpp_terminate_wrapped_handle(void);
HMD_EXTERN std::terminate_handler hmd_cpp_terminate_original_handle;

std::terminate_handler hmd_cpp_terminate_original_handle = NULL;

static void hmdcrash_record_exception(const char *name,hmd_stack_cursor *cursor,thread_t);
static void record_nsexception(NSException *exception,thread_t);
static void record_cppexception(const char *name,const char *desc,hmd_stack_cursor *cursor,thread_t);

void HMDCrashDetect_cpp_start(void) {
    if (std::get_terminate() == hmd_cpp_terminate_wrapped_handle) {
        SDKLog_warn("cpp terminate handle already setted");
        return;
    }
        
    hmd_cpp_terminate_original_handle = std::set_terminate(hmd_cpp_terminate_wrapped_handle);
    SDKLog("cpp detector launch complete");
}

void HMDCrashDetect_cpp_end(void) {
    if (hmd_cpp_terminate_original_handle) {
        std::set_terminate(hmd_cpp_terminate_original_handle);
        SDKLog("cpp detector shutdown complete");
    }else{
        SDKLog_error("original handler is NULL");
    }
}

void hmd_cpp_terminate_process_handle(void) {
    SDKLog("cpp terminate handler invoked!");
    
    if(once_catch()){
        SDKLog("handing exception");
        if(!open_exception()) {
            SDKLog_error("exception handler open exception failed");
        }
        std::type_info* tinfo = __cxxabiv1::__cxa_current_exception_type();
        bool has_active_exception = false;
        const char *name = NULL;
        if (tinfo != NULL) {
            has_active_exception = true;
            name = tinfo->name();
        }else{
            name = "no_active_exception";
            SDKLog_warn("no active exception");
        }
        
        hmd_cpp_exception_info exception_info = hmd_current_cpp_exception_info();
        
        bool exception_info_valid = false;
        if (exception_info.type_info == tinfo) {
            void *exception = hmd_current_cpp_exception();
            if (exception_info.exception == exception) {
                //good
                SDKLog("valid exception info");
                exception_info_valid = true;
            }
        }
        
        thread_t c_thread = mach_thread_self();
        hmd_stack_cursor cursor;
        
        if (exception_info_valid && exception_info.backtrace_len > 0) {
            const uintptr_t* backtrace = (const uintptr_t*)exception_info.backtrace;
            hmdsc_initWithBacktrace(&cursor, backtrace, exception_info.backtrace_len, exception_info.skip_count);
        } else {
            hmdsc_init_self_thread_backtrace(&cursor, 2);
        }
        
        if (has_active_exception) {
            hmdcrash_record_exception(name, &cursor, c_thread);
        }else{
            record_cppexception(name, NULL, &cursor, c_thread);
        }
    } else {
        wait_catch();
    }
    
    if (hmd_cpp_terminate_original_handle != hmd_cpp_terminate_wrapped_handle) {
        SDKLog("cpp invoke original handle");
        return; // return to wrapper handler
    } else {
        SDKLog_error("origin handler is dangerous, may cause death loop, exiting");
        exit(EXIT_FAILURE);
    }
}

#pragma mark - handle CPPException

static void hmdcrash_record_exception(const char *name,hmd_stack_cursor *cursor,thread_t c_thread)
{
    char description_buff[512];
    const char* description = description_buff;
    description_buff[0] = 0;
    
    try
    {
        @try{
            __cxxabiv1::__cxa_rethrow();//可能是cpp exception 或者 NSException，去掉之前通过name判断的逻辑
        }@catch(NSException *e){
            record_nsexception(e,c_thread);
            return;
        }
    }
    catch(std::exception& exc)
    {
        strncpy(description_buff, exc.what(), sizeof(description_buff));
    }
#define CATCH_STR(TYPE) \
catch(TYPE value)\
{ \
if (value) {\
    strncpy(description_buff, value, sizeof(description_buff));\
}\
}
    CATCH_STR(char *)

#define CATCH_SIGNED_VALUE(TYPE) \
catch(TYPE value)\
{ \
hmd_memory_write_int64(description_buff, sizeof(description_buff), (int64_t)value);\
}
    CATCH_SIGNED_VALUE(char)
    CATCH_SIGNED_VALUE(short)
    CATCH_SIGNED_VALUE(int)
    CATCH_SIGNED_VALUE(long)
    CATCH_SIGNED_VALUE(long long)
    CATCH_SIGNED_VALUE(float)
    CATCH_SIGNED_VALUE(double)
    CATCH_SIGNED_VALUE(long double)
        
#define CATCH_UNSIGNED_VALUE(TYPE) \
catch(TYPE value)\
{ \
hmd_memory_write_uint64(description_buff, sizeof(description_buff), (uint64_t)value);\
}
    CATCH_UNSIGNED_VALUE(unsigned char)
    CATCH_UNSIGNED_VALUE(unsigned short)
    CATCH_UNSIGNED_VALUE(unsigned int)
    CATCH_UNSIGNED_VALUE(unsigned long)
    CATCH_UNSIGNED_VALUE(unsigned long long)

    catch(...)
    {
        description = NULL;
    }
    
    record_cppexception(name, description, cursor, c_thread);
}

static void record_cppexception(const char *name,const char *desc,hmd_stack_cursor *cursor,thread_t c_thread)
{
    SDKLog("handling CPP Exception");
    
    hmdcrash_detector_context_t crash_context;
    memset(&crash_context, 0, sizeof(crash_context));
    
    crash_context.crash_time = HMD_XNUSystemCall_timeSince1970();
    crash_context.crash_type = HMDCrashTypeCPlusPlus;
    crash_context.cpp_exception.name = name;
    crash_context.cpp_exception.description = desc;
    
    basic_info(&crash_context);

    //crash thread
    KSMC_NEW_CONTEXT(machineContext);
    machineContext->working_thread = c_thread;
    hmdmc_get_state_with_thread(c_thread, machineContext, true);
    machineContext->cursor = cursor;
    
    //env info
    KSMC_NEW_ENV_CONTEXT(envContextPointer);
    envContextPointer->crash_machine_ctx = machineContext;

    hmd_crash_handler(envContextPointer, &crash_context);
}

#pragma mark - handle NSException

static void record_nsexception(NSException *exception,thread_t c_thread)
{
    SDKLog("handling NSException");
    
    hmdcrash_detector_context_t crash_context;
    memset(&crash_context, 0, sizeof(crash_context));
    
    crash_context.crash_time = HMD_XNUSystemCall_timeSince1970();
    crash_context.crash_type = HMDCrashTypeNSException;
    crash_context.ns_exception.name = exception.name.UTF8String;
    crash_context.ns_exception.reason = exception.reason.UTF8String;
    crash_context.ns_exception.user_info = exception.userInfo.description.UTF8String;
    basic_info(&crash_context);
    
    NSArray<NSNumber *> *addresses = exception.callStackReturnAddresses;
    NSUInteger frames_count = addresses.count;
    uintptr_t callstack[frames_count]; //改为动态栈内存分配
    memset(callstack, 0, sizeof(callstack));
    for(NSUInteger i = 0; i < frames_count; i++)
        callstack[i] = (uintptr_t)addresses[i].unsignedLongLongValue;
    
    //crash thread
    KSMC_NEW_CONTEXT(machineContext);
    machineContext->working_thread = c_thread;
    hmdmc_get_state_with_thread(c_thread, machineContext, true);
    hmd_stack_cursor cursor;
    hmdsc_initWithBacktrace(&cursor, callstack, (int)frames_count, 0);
    machineContext->cursor = &cursor;
    
    //env info
    KSMC_NEW_ENV_CONTEXT(envContextPointer);
    envContextPointer->crash_machine_ctx = machineContext;

    hmd_crash_handler(envContextPointer, &crash_context);
}

bool HMDCrashDetect_cpp_check(void)
{
    std::terminate_handler handler = std::get_terminate();
    if (handler != hmd_cpp_terminate_wrapped_handle) {
        SDKLog_error("terminate handler is invalid");
        return false;
    }
    
    SDKLog("terminate handler is valid");
    
    return true;
}
