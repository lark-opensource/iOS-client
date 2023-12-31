//
//  hmd_cpp_exception.cpp
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/29.
//

#include "HMDMacro.h"
#include "hmd_cpp_exception.hpp"
#include <dlfcn.h>
#include <cxxabi.h>
#include <atomic>
#include <exception>
#include <typeinfo>
#include <cstring>
#include <execinfo.h>
#include <mach-o/dyld.h>
#include <BDFishhook/BDFishhook.h>
#include <dispatch/dispatch.h>
static volatile std::atomic<hmd_cpp_exception_info> g_cpp_exception_info;

static std::atomic_bool enable;
static dispatch_queue_t cpp_exception_queue;

extern "C" {
// EXPORTED handler
hmd_exception_recover_function_t hmd_exception_recover_handle;
}

extern "C"
{
    static void (*ori_cxa_throw)(void* thrown_exception, std::type_info* tinfo, void (*dest)(void*));
    static void hmd_cxa_throw(void* thrown_exception, std::type_info* tinfo, void (*dest)(void*)) {
        
        // Exception handler preprocess
        hmd_exception_recover_function_t exception_handler = __atomic_load_n(&hmd_exception_recover_handle, __ATOMIC_ACQUIRE);
        if(exception_handler != NULL) exception_handler(thrown_exception, tinfo, dest);
        
        if (std::atomic_load_explicit(&enable, std::memory_order_acquire)) {
            bool isNSException = false;
            if (tinfo) {
                const char *name = tinfo->name();
                if (name) {
                    isNSException = strcmp("NSException", name) == 0;
                }
            }
            if (!isNSException) {//排除NSException，因为NSException有系统记录的Last Exception Backtrace
                /*
                 类似于 NSException 的 Last Backtrace。
                 主线程或其他线程在入口处有一个try catch，会把uncaught exception捕获，并进行rethrow，这样会导致下面的问题
                 try {
                    thread_start() -> __cxa_throw() //此时的backtrace是准确的，可直接回溯到触发点
                 } catch {
                    rethrow() -> std::terminate() -> handler() //此时的backtrace已经变化
                 }
                 在__cxa_throw把backtrace记录下来，并在handler()回溯的时候使用。
                 因为只有一个全局变量g_cpp_exception_info，在多个线程同时发生c++异常时，可能会出现backtrace被覆盖的情况，
                 在回溯时会去校验当前的backtrace是否属于这个exception。
                 */
                hmd_cpp_exception_info exception_info;
                memset(&exception_info, 0, sizeof(exception_info));
                exception_info.exception = thrown_exception;
                exception_info.type_info = tinfo;
                exception_info.dest = (void *)dest;
                int len = backtrace((void**)exception_info.backtrace, sizeof(exception_info.backtrace)/sizeof(void *));
                exception_info.backtrace_len = len;
                exception_info.skip_count = 1;
                std::atomic_store_explicit(&g_cpp_exception_info, exception_info, std::memory_order_release);
            }
        }
        if (ori_cxa_throw) {
            ori_cxa_throw(thrown_exception,tinfo,dest);
        }
        GCC_FORCE_NO_OPTIMIZATION
    }
}

static void image_add_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    dispatch_async(cpp_exception_queue, ^{
        struct bd_rebinding r[] = {
            {"__cxa_throw",(void *)hmd_cxa_throw,(void **)&ori_cxa_throw}
        };
        bd_rebind_symbols_image((void *)mh, vmaddr_slide, r, sizeof(r)/sizeof(struct bd_rebinding));
    });
}

void hmd_enable_cpp_exception_backtrace() {
    std::atomic_store_explicit(&enable, true, std::memory_order_release);
    static std::atomic_flag once;
    if (std::atomic_flag_test_and_set_explicit(&once, std::memory_order_release)) {
        return;
    }
#if !__has_feature(address_sanitizer)
    //asan 会映射__cxa_throw到自己的wrap__cxa_throw，导致递归
    if (!cpp_exception_queue) {
        cpp_exception_queue = dispatch_queue_create("com.hmd.cppexception", DISPATCH_QUEUE_SERIAL);
    }
    _dyld_register_func_for_add_image(image_add_callback);
#endif
}

void hmd_disable_cpp_exception_backtrace() {
    std::atomic_store_explicit(&enable, false, std::memory_order_release);
}

hmd_cpp_exception_info hmd_current_cpp_exception_info() {
    return std::atomic_load_explicit(&g_cpp_exception_info, std::memory_order_acquire);
}

void *hmd_current_cpp_exception() {
    void *e = __cxxabiv1::__cxa_current_primary_exception();
    return e;
}
