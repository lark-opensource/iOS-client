//
//  HMDCrashPrevent.m
//  Heimdallr
//
//  Created by sunrunwang on 2021/12/21.
//

#define HMD_USE_DEBUG_ONCE

#include <dlfcn.h>
#include <atomic>
#include <inttypes.h>
#import <FrameRecover/HMDFrameRecoverManager.h>

#include "HMDMacro.h"
#import "HMDExceptionTracker.h"
#include "hmd_cpp_exception.hpp"
#include "HMDAsyncMachOImage.h"
#include "HMDCompactUnwind.hpp"
#import "HMDCrashPrevent.h"
#import "HMDInjectedInfo.h"
#import "HMDProtector+Private.h"
#import "HMDProtect_Private.h"
#import "HMDThreadBacktrace.h"
#import "HMDAppleBacktracesLog.h"
#import "HMDProtect_Private.h"
#import "hmd_try_catch_detector.h"
#import "HMDCrashDetectMach.h"
#import "HMDCrashPreventMachException.h"
#import "hmd_mach_exception_protection_tool.h"
#include "HMDCrashPreventMachRestartable.h"

// import name space std
using namespace std;

static bool query_image_begin(uintptr_t address, void * _Nullable * _Nonnull image_identifier, hmdfc_image_info * _Nonnull macho_image_info);

static void  query_enumerate_section(void * _Nonnull image_identifier,
                                           HMDFC_section_callback _Nonnull callback,
                                           void * _Nonnull context);

static void query_image_finish(void * _Nonnull image_identifier);

static void query_enum_image(HMDFC_image_enum_callback _Nonnull callback, void * _Nullable context);

static bool is_binary_image_list_finished(void);

static void image_list_finish_callback(void);

static void HMDCrashPrevent_exception_catch(void *, std::type_info *, void (*)(void*));

static void setup_mach_handle_connection(void);
static void setup_mach_handle_connection_once(void);

@implementation HMDCrashPrevent

#pragma mark - Public interface

/// 当前的 CrashPrevent 启动数据, 需要原子读写 ( __atomic_store_n 和 __atomic_load_n )
static HMDCrashPreventOption internal_option = HMDCrashPreventOptionNone;

+ (void)switchOptionON:(HMDCrashPreventOption)option {
    
    // 初始化要提前
    // mach Exception 防护是否开启只取决于 internal_option & HMDCrashPreventOptionMachException
    // 在这之前需要提前开启 setup 相关操作
    
    if(option & HMDCrashPreventOptionNSException) {
        [HMDCrashPrevent setupNSExceptionHandleConnectionIfNeed];
        [HMDInjectedInfo.defaultInfo setCustomFilterValue:@(YES) forKey:@"enable_crash_prevent_NSException"];
    }
    if(option & HMDCrashPreventOptionMachException) {
        [HMDCrashPrevent setupMachExceptionHandleConnectionIfNeed];
        [HMDInjectedInfo.defaultInfo setCustomFilterValue:@(YES) forKey:@"enable_crash_prevent_machException"];
    }
    
    HMDCrashPreventOption desired;
    HMDCrashPreventOption current = __atomic_load_n(&internal_option, __ATOMIC_ACQUIRE);
    
    do desired = (HMDCrashPreventOption)(current | option);
    while(!__atomic_compare_exchange_n(&internal_option, &current, desired, false, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE));
    
    // 这里存在可能线程不同步的情况, 但是我们并不考虑
    if(option & HMDCrashPreventOptionMachException) HMDFrameRecoverManager.machExceptionEnable = YES;
}

+ (void)switchOptionOFF:(HMDCrashPreventOption)option {
    HMDCrashPreventOption desired;
    HMDCrashPreventOption current = __atomic_load_n(&internal_option, __ATOMIC_ACQUIRE);
    
    do desired = (HMDCrashPreventOption)(current & ~option);
    while(!__atomic_compare_exchange_n(&internal_option, &current, desired, false, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE));
    
    // 这里存在可能线程不同步的情况, 但是我们并不考虑
    if(option & HMDCrashPreventOptionMachException) HMDFrameRecoverManager.machExceptionEnable = NO;
    
    if(option & HMDCrashPreventOptionNSException)
        [HMDInjectedInfo.defaultInfo setCustomFilterValue:@(NO) forKey:@"enable_crash_prevent_NSException"];
    
    if(option & HMDCrashPreventOptionMachException)
        [HMDInjectedInfo.defaultInfo setCustomFilterValue:@(NO) forKey:@"enable_crash_prevent_machException"];
}

+ (void)switchNSExceptionOption:(BOOL)shouldOpen {
    if(shouldOpen) [HMDCrashPrevent switchOptionON:HMDCrashPreventOptionNSException];
    else [HMDCrashPrevent switchOptionOFF:HMDCrashPreventOptionNSException];
}

+ (void)switchMachExceptionOption:(BOOL)shouldOpen {
    if(shouldOpen) [HMDCrashPrevent switchOptionON:HMDCrashPreventOptionMachException];
    else [HMDCrashPrevent switchOptionOFF:HMDCrashPreventOptionMachException];
}

static unsigned int suspendCount = 0u;

+ (void)suspendProtection {
    __atomic_add_fetch(&suspendCount, 1u, __ATOMIC_RELEASE);
}

+ (void)resumeProtection {
    unsigned int desired;
    unsigned int count = __atomic_load_n(&suspendCount, __ATOMIC_ACQUIRE);
    do {
        DEBUG_ASSERT(count != 0); if(count == 0) return;
        desired = count - 1u;
    } while(!__atomic_compare_exchange_n(&suspendCount, &count, desired, false, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE));
}

static BOOL HMDCrashPrevent_shouldProtectForOption(HMDCrashPreventOption option) {
    HMDCrashPreventOption current_option = __atomic_load_n(&internal_option, __ATOMIC_ACQUIRE);
    if(current_option & option) {
        unsigned int count = __atomic_load_n(&suspendCount, __ATOMIC_ACQUIRE);
        return count == 0u;
    }
    return NO;
}

#pragma mark - Private Method

+ (void)setupFrameRecoverIfNeeded {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) return;
    
    // 初始化 shared binary image list
    hmd_setup_shared_image_list_if_need();
    
    // 设置 HMDFrameRecoverManager 查询 binary image 的数据的代理方法 (节约内存空间)
    [HMDFrameRecoverManager setQueryBegin:query_image_begin
                              enumeration:query_enumerate_section
                                   finish:query_image_finish];
    
    [HMDFrameRecoverManager setEnumImage:query_enum_image];
    
    hmd_shared_binary_image_register_finish_callback(image_list_finish_callback);
    [HMDFrameRecoverManager setQueryListStatus:is_binary_image_list_finished];
    
    // 开启 HMDFrameRecoverManager 的准备工作 (闭源库, 负责栈恢复的核心逻辑)
    [HMDFrameRecoverManager setup];
}

/// 用于安全气垫的去重能力使用 ( 逻辑见 protector 那里 )
static NSMutableSet<NSString *>* crashKeySet = nil;

/** @method setupNSExceptionHandleConnectionIfNeed
    @discussion NSException 处理的逻辑如下
 
    HMDCrashKit.cppException 会拦截所有的 C++ Exception 异常抛出，我们向其注册一个拦截函数前的拦截函数
        @p hmd_exception_recover_handle 设置成 @p HMDCrashPrevent_exception_catch
 
    @p HMDCrashPrevent_exception_catch 就会接收到所有的 C++ Exception 异常抛出，我们在这里判断
        1. 当前 crashPrevent 是否开启 NSException 防护
        2. 当前 crashPrevent 是否暂时终止 NSException 防护
        3. 当前 crashPrevent 是否可以检测到上层存在 try-catch 可以捕获当前异常
 
    如果这些检测都通过，我们是可以处理这个函数的，那么我们将 @p HMDCrashPrevent_exception_catch
    收到的 C++ Exception 信息交给 HMDFrameRecoverManager.exceptionHandler 进行处理
 
    exceptionHandler 内部处理逻辑不对外暴露，它会决定当前的 Exception 是否可以恢复
        1. 如果不可恢复，那么函数返回，我们也继续原来的调用返回
        2. 如果可以恢复，该处函数不会返回，但是在它进行处理的前一瞬间，会给我们一个回调
 
    这个处理回掉来自我们在 [HMDFrameRecoverManager objcExceptionCallback:] 注册的处理回调
    其中会包含当前的崩溃基础信息，例如发生了什么 NSException 以及处理结果如何
 
    这时刻我们需要向安全气垫进行上报当前崩溃信息 */
+ (void)setupNSExceptionHandleConnectionIfNeed {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) return;
    
    // 初始化 FrameRecover
    [HMDCrashPrevent setupFrameRecoverIfNeeded];
    
    // 初始化 cxa_throw hook
    hmd_enable_cpp_exception_backtrace();

    // 初始化 crashKeySet 用于去除重复
    crashKeySet = [NSMutableSet set];
    
    // 设置 HMDFrameRecoverManager OBJC Exception 处理回调方案
    [HMDFrameRecoverManager objcExceptionCallback:^(HMDFrameRecoverExceptionData * _Nonnull exceptionData) {
        [HMDCrashPrevent objcExceptionCallback:exceptionData];
        // 该处设置 GCC_FORCE_NO_OPTIMIZATION 防止栈丢失
        GCC_FORCE_NO_OPTIMIZATION
    }];
    
    // 如果后续需要处理 非 OBJC 的 C++ 异常，应该在这里注册 C++ 处理回调
    
    // 对 HMDCrashKit.cppException 设置我们的处理函数
    __atomic_store_n(&hmd_exception_recover_handle, HMDCrashPrevent_exception_catch,  __ATOMIC_RELEASE);
}

+ (void)objcExceptionCallback:(HMDFrameRecoverExceptionData *)exceptionData {
    if(exceptionData != nil) {
#ifdef DEBUG
        HMDThreadBacktrace *debugBT = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread] symbolicate:YES skippedDepth:6 suspend:NO];
        NSString *debugStr = [HMDAppleBacktracesLog logWithBacktraces:@[debugBT] type:HMDLogExceptionProtect exception:exceptionData.exception.name reason:exceptionData.exception.reason];
        fprintf(stdout, "%s\n", debugStr.UTF8String);
        Dl_info dynamic_info;
        if(dladdr((void *)exceptionData.pc, &dynamic_info) == 0) dynamic_info.dli_sname = NULL;
        fprintf(stdout, "[CrashPrevent] will recover program continue executing at function(%p) %s\n", (void *)exceptionData.pc, dynamic_info.dli_sname);
        fflush(stdout);
        
        /* 您的应用发生了 NSException 崩溃, 该崩溃可以被 [安全气垫][通用NSException防护功能] 防护
           但是由于目前是 DEBUG 状态, 所以我们挂起了线程以便于您排查问题，可在 Release 模式下测试防护效果
           如果继续执行位置不符合预期, 请向 Heimdallr 开发人员反馈
         */
        HMDProtectBreakpoint();
#endif
        
        NSException * _Nullable exception = exceptionData.exception;
        
        HMDThreadBacktrace *bt = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread] symbolicate:NO skippedDepth:6 suspend:NO];
        
        NSString *crashKey = nil;
        if(bt.stackFrames.count >= 2)   // stack index 1 is where throw exception
            crashKey = @(bt.stackFrames[1].address).stringValue;
        
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:3];
        if(bt) [info setValue:@[bt] forKey:@"backtraces"];
        if(crashKey) [info setValue:crashKey forKey:@"crashKey"];
        [info setValue:crashKeySet forKey:@"crashKeySet"];
        [info setValue:@(NO) forKey:@"filterWithTopStack"];
        
        NSString *programCounterString = [NSString stringWithFormat:@"%#" PRIx64, (uint64_t)exceptionData.pc];
        DEBUG_ASSERT(programCounterString != nil);
        
        if(programCounterString != nil) {
            NSDictionary *customDictionary = @{ @"frame_recover_pc": programCounterString };
            [info setValue:customDictionary forKey:@"custom"];
        }
        
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"crashPrevent NSException protected %@, %@", exception.name, exception.reason);
        
        [HMDProtector.sharedProtector respondToNSExceptionPrevent:exceptionData.exception info:info];
        
        [HMDInjectedInfo.defaultInfo setCustomFilterValue:@(YES) forKey:@"crash_prevent_nsexception_protected"];
    } DEBUG_ELSE
}

#pragma mark - Mach Exception

+ (void)setupMachExceptionHandleConnectionIfNeed {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) return;
    
    // 初始化 FrameRecover
    [HMDCrashPrevent setupFrameRecoverIfNeeded];
    
    // 设置 Mach handle
    setup_mach_handle_connection();
    
    HMDCrashPreventMachExceptionProtect_internal_register(HMDCrashPreventMachExceptionProtect);
}

static void setup_mach_handle_connection(void) {
    static pthread_once_t onceToken = PTHREAD_ONCE_INIT;
    pthread_once(&onceToken, setup_mach_handle_connection_once);
}

static HMD_NO_OPT_ATTRIBUTE void setup_mach_handle_connection_once(void) {
    DEBUG_ONCE
    
    HMDExceptionTracker_connectWithProtector_if_need();
    
    // 设置 HMDFrameRecoverManager Mach Exception 处理回调方案
    [HMDFrameRecoverManager machExceptionCallback:^(HMDFrameRecoverMachData * _Nullable data) {
        [HMDCrashPrevent machExceptionCallback:data];
        GCC_FORCE_NO_OPTIMIZATION
    }];
    
    hmd_mach_recover_function_t _Nullable recover_function = (hmd_mach_recover_function_t _Nullable)[HMDFrameRecoverManager machHandler];
    
    // 对 HMDCrashKit.machException 设置我们的处理函数
    if(recover_function != NULL)
        __atomic_store_n(&hmd_mach_recover_handle, recover_function, __ATOMIC_RELEASE);
}

#pragma mark scope

+ (void)scopePrefix:(NSString * _Nonnull)prefix {
    DEBUG_ASSERT(prefix != nil);
    
    [HMDFrameRecoverManager scopePrefix:prefix.UTF8String];
}

+ (void)scopeWhiteList:(NSArray<NSString *> * _Nonnull)whiteList {
    DEBUG_ASSERT(whiteList != nil);
    
    for(NSString *eachString in whiteList)
        [HMDFrameRecoverManager scopeWhiteList:eachString.UTF8String];
}

+ (void)scopeBlackList:(NSArray<NSString *> * _Nonnull)blackList {
    DEBUG_ASSERT(blackList != nil);
    
    for(NSString *eachString in blackList)
        [HMDFrameRecoverManager scopeBlackList:eachString.UTF8String];
}

#pragma mark mach cloud setting

+ (void)updateMachExceptionCloudControl:(NSArray<NSString *> * _Nonnull)cloudControl {
    DEBUG_ASSERT(cloudControl != nil);
    
    [HMDCrashPrevent setupFrameRecoverIfNeeded];
    [HMDFrameRecoverManager updateMachExceptionCloudControl:cloudControl];
}

#pragma mark mach exception callback

+ (void)machExceptionCallback:(HMDFrameRecoverMachData * _Nullable)data {
    NSString * _Nullable scope = data.scope;
    NSPointerArray * _Nullable pointerArray = data.backtraces;
    
    HMDThreadBacktrace *backtrace;
    if(pointerArray != nil) {
        backtrace = [HMDThreadBacktrace backtraceWithPointerArray:pointerArray];
    } else {
        backtrace = [HMDThreadBacktrace backtraceOfThread:HMDThreadBacktrace.currentThread
                                              symbolicate:NO
                                             skippedDepth:4
                                                  suspend:NO];
    }
    
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:1];
    if(backtrace != nil) [info setValue:@[backtrace] forKey:@"backtraces"];
    if(scope != nil)     [info setValue:scope        forKey:@"scope"];
    
    HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"crashPrevent MachException protected %@", data.scope);
    
    [HMDProtector.sharedProtector respondToMachExceptionWithInfo:info];
    
    [HMDInjectedInfo.defaultInfo setCustomFilterValue:@(YES) forKey:@"crash_prevent_mach_exception_protected"];
    GCC_FORCE_NO_OPTIMIZATION
}

#pragma mark mach try catch

HMD_EXTERN bool HMDCrashPreventMachExceptionProtect(const char * _Nonnull scope,
                                                    HMDMachRecoverOption option,
                                                    HMDMachRecoverContextRef _Nullable context,
                                                    void(^ _Nonnull block)(void)) {
    DEBUG_ASSERT(block != nil);
    
    // machException protection enabled
    if(likely(HMDCrashPrevent_shouldProtectForOption(HMDCrashPreventOptionMachException))) {
        
        bool crashed = HMDFrameRecoverManager_protectMachException(scope, option, context, block);
        GCC_FORCE_NO_OPTIMIZATION return crashed;
    }
    
    // currently machException protection disabled
    if(block != nil) block();
    
    GCC_FORCE_NO_OPTIMIZATION return false;
}

#pragma mark mach restartable

HMD_EXTERN void HMDCrashPreventMachRestartable_toggleStatus(bool enableOpen, uint64_t option, void * _Nullable context) {
    DEBUG_ASSERT(option == UINT64_C(0) && context == NULL);
    if(enableOpen) setup_mach_handle_connection();
    
    HMDFrameRecoverManager.machRestartableEnable = enableOpen;
}

HMD_EXTERN bool HMDCrashPreventMachRestartable_range_register(HMDMachRestartable_range_ref _Nonnull range) {
    return HMDFrameRecoverManager_machRestartable_range_register(range);
}

HMD_EXTERN bool HMDCrashPreventMachRestartable_range_unregister(HMDMachRestartable_range_ref _Nonnull range) {
    return HMDFrameRecoverManager_machRestartable_range_unregister(range);
}

#pragma mark - Deprecated

+ (void)switchNSExcptionOption:(BOOL)shouldOpen {
    [self switchNSExceptionOption:shouldOpen];
}

#pragma mark - Enforce FrameRecoverVersion

HMD_EXTERN NSUInteger HMDFrameRecoverManager_version_12200_enforce_placeholder(void);

+ (NSUInteger)frameRecoverVersion {
    return HMDFrameRecoverManager_version_12200_enforce_placeholder();
}

@end

static HMD_NO_OPT_ATTRIBUTE void HMDCrashPrevent_exception_catch(void* thrown_exception, std::type_info* tinfo, void (*dest)(void*)) {
    if(likely(HMDCrashPrevent_shouldProtectForOption(HMDCrashPreventOptionNSException))) {
        void * _Nullable exception_handler = [HMDFrameRecoverManager exceptionHandler];
        if(exception_handler != NULL) {
            // try-catch embedded in FrameRecover since version 1.22.0
            ((hmd_exception_recover_function_t)exception_handler)(thrown_exception, tinfo, dest);
        }
    }
    GCC_FORCE_NO_OPTIMIZATION
}

#pragma mark - Binary Image Callback 查询逻辑 (address => image)

static bool query_image_begin(uintptr_t address, void * _Nullable * _Nonnull image_identifier, hmdfc_image_info * _Nonnull macho_image_info) {
    if(address == UINT64_C(0x0) || image_identifier == NULL || macho_image_info == NULL) DEBUG_RETURN(false);
    
    hmd_async_image_list_set_reading(&shared_image_list, true);
    hmd_async_image_t * image;
    if((image = hmd_async_image_containing_address(&shared_image_list, (hmd_vm_address_t)address)) != NULL) {
        hmd_async_macho_t * _Nonnull image_macho = &image->macho_image;

        struct symtab_command * _Nullable symbol_table_command = (struct symtab_command *)hmd_async_macho_find_command(image_macho, LC_SYMTAB);
        if(symbol_table_command != NULL) {
            
            hmd_async_macho_segment_t linkedit_segment;
            if(hmd_async_macho_find_segment(image_macho, SEG_LINKEDIT, &linkedit_segment) == HMD_ESUCCESS) {
                
                macho_image_info->symbolication.linkedit.vmaddr_slided = linkedit_segment.obj.addr;
                macho_image_info->symbolication.linkedit.vmsize = linkedit_segment.obj.size;
                macho_image_info->symbolication.linkedit.fileoff = linkedit_segment.fileoff;
                macho_image_info->symbolication.symbol_table = symbol_table_command[0];
                
                macho_image_info->header_addr    = image_macho->header_addr;
                macho_image_info->image_from_app = image_macho->is_app_image;
                macho_image_info->slide          = image_macho->vmaddr_slide;
                
                macho_image_info->unwind_info.addr = image_macho->unwind_info.addr;
                macho_image_info->unwind_info.size = image_macho->unwind_info.size;
                
                image_identifier[0] = image_macho;
                
                return true; // don't unlock reading
                
            } DEBUG_ELSE
        } DEBUG_ELSE
    } DEBUG_ELSE
    
    CLANG_DIAGNOSTIC_PUSH
    CLANG_DIAGNOSTIC_IGNORE_UNREACHABLE
    hmd_async_image_list_set_reading(&shared_image_list, false);
    CLANG_DIAGNOSTIC_POP
    
    return false;
}

static void query_enumerate_section(void * _Nonnull async_macho_identifier,
                                    HMDFC_section_callback _Nonnull callback,
                                    void * _Nonnull context) {
    hmd_async_macho_t * _Nonnull image_macho = (hmd_async_macho_t *)async_macho_identifier;
    if(image_macho != NULL && callback != NULL && context != NULL) {
        
        if(image_macho->interested_sections_count > 0) {
            
            for(int index = 0; index < image_macho->interested_sections_count; index++) {
                hmdfc_section_info section_info;
                section_info.segment_name = image_macho->interested_sections[index].seg_name;
                section_info.section_name = image_macho->interested_sections[index].sec_name;
                section_info.addr         = image_macho->interested_sections[index].range.addr;
                section_info.size         = image_macho->interested_sections[index].range.size;
                
                callback(&section_info, context);
            }
        }
        
    } DEBUG_ELSE
}

static void query_image_finish(void * _Nonnull image_identifier) {
    DEBUG_ASSERT((hmd_async_macho_t *)image_identifier != NULL);
    hmd_async_image_list_set_reading(&shared_image_list, false);
}

typedef struct async_image_list_callback_context {
    HMDFC_image_enum_callback _Nonnull frame_recover_callback;
    void * _Nullable frame_recover_context;
} async_image_list_callback_context;

static void async_image_list_callback(hmd_async_image_t * _Nonnull image,
                                      int index,
                                      bool * _Nonnull stop,
                                      void * _Nonnull ctx);

static void query_enum_image(HMDFC_image_enum_callback _Nonnull callback, void * _Nullable context) {
    if(callback != NULL) {
        hmd_async_image_list_set_reading(&shared_image_list, true);
        
        async_image_list_callback_context async_image_context = {
            . frame_recover_callback = callback,
            .frame_recover_context = context,
        };
        
        hmd_async_enumerate_image_list(async_image_list_callback, &async_image_context);
        hmd_async_image_list_set_reading(&shared_image_list, false);
    } DEBUG_ELSE
}

static void async_image_list_callback(hmd_async_image_t *image,
                                      int index,
                                      bool *stop,
                                      void *ctx) {
    async_image_list_callback_context * _Nonnull async_image_context
        = (async_image_list_callback_context *)ctx;
    
    if(async_image_context != NULL && stop != NULL && async_image_context->frame_recover_callback != NULL) {
        
        hmd_async_macho_t * _Nonnull image_macho = &image->macho_image;
        
        struct symtab_command * _Nullable symbol_table_command = (struct symtab_command *)hmd_async_macho_find_command(image_macho, LC_SYMTAB);
        
        if(symbol_table_command != NULL) {
            
            hmd_async_macho_segment_t linkedit_segment;
            if(hmd_async_macho_find_segment(image_macho, SEG_LINKEDIT, &linkedit_segment) == HMD_ESUCCESS) {
                
                hmdfc_image_info macho_image_info = {
                    .header_addr = image_macho->header_addr,
                    .image_from_app = image_macho->is_app_image,
                    .slide = image_macho->vmaddr_slide,
                    .unwind_info = {
                        .addr = image_macho->unwind_info.addr,
                        .size = image_macho->unwind_info.size,
                    },
                    .symbolication = {
                        .linkedit = {
                            .vmaddr_slided = linkedit_segment.obj.addr,
                            .vmsize = linkedit_segment.obj.size,
                            .fileoff = linkedit_segment.fileoff,
                        },
                        .symbol_table = symbol_table_command[0],
                    },
                };
                
                hmdfc_image_identify_info macho_image_identify_info;
                bzero(&macho_image_identify_info, sizeof(macho_image_identify_info));
                macho_image_identify_info.path = image_macho->name;
                
                COMPILE_ASSERT(sizeof(macho_image_identify_info.UUID) == sizeof(image_macho->raw_uuid));
                COMPILE_ASSERT(sizeof(macho_image_identify_info.UUID) == sizeof(uuid_t));
                memcpy(macho_image_identify_info.UUID, image_macho->raw_uuid, sizeof(uuid_t));
                
                async_image_context->frame_recover_callback(&macho_image_info,
                                                            &macho_image_identify_info,
                                                            image_macho,
                                                            async_image_context->frame_recover_context,
                                                            stop);
                
            } DEBUG_ELSE
        } DEBUG_ELSE
    } else {
        if(stop != NULL) stop[0] = true;
        DEBUG_POINT;
    }
}

static bool is_binary_image_list_finished(void) {
    return hmd_async_share_image_list_finished_setup();
}

static void image_list_finish_callback(void) {
    [HMDFrameRecoverManager markImageListFinished];
}
