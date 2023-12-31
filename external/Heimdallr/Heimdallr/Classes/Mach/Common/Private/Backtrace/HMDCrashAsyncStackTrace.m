//
//  HMDCrashAsyncStackTrace.c
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/10/20.
//

#import <Foundation/Foundation.h>
#include "HMDCrashAsyncStackTrace.h"
#include <dispatch/dispatch.h>
#include <Block.h>
#include <dlfcn.h>
#include <pthread.h>
#include "hmd_crash_safe_tool.h"
#include <stdlib.h>
#include <string.h>
#include <mach/mach_init.h>
#include <mach/mach_port.h>
#include "HMDCrashAsyncStackRecordList.h"
#include <stdatomic.h>
#include "HMDAsyncThread.h"
#include "HMDMacro.h"
#include <BDFishhook/BDFishhook.h>
#include <mach-o/dyld.h>
#import "HMDSwizzle.h"
#include <execinfo.h>
#include <os/lock.h>
#import "HMDAsyncStackTraceDebug.h"
#import "HMDFishhookQueue.h"
#import "HeimdallrUtilities.h"
#include "HMDAsyncThreadRecordPool.h"
// Utility
#import "HMDMacroManager.h"

#pragma mark -

static dispatch_queue_t async_trace_queue;

static void hook_objc_selectors(void);
static atomic_bool enable_async_stack_trace;
static atomic_bool enable_multiple_async_stack_trace;
static bool hmd_async_stack_trace_enabled(void);

static pthread_key_t hmd_async_stack_key;

static hmd_async_stack_record_list record_list;
static atomic_bool shared_list_initialized;
static hmd_async_stack_record_list * shared_stack_record_list(void){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hmd_nasync_stack_record_list_init(&record_list);
        atomic_store_explicit(&shared_list_initialized,true,memory_order_release);
    });
    return &record_list;
}

static hmd_async_stack_record_list * async_shared_stack_record_list(void){
    if (atomic_load_explicit(&shared_list_initialized,memory_order_acquire)) {
        return &record_list;
    }
    return NULL;
}

bool hmd_async_stack_trace_open(void) {
    if (!atomic_load_explicit(&enable_async_stack_trace,memory_order_acquire)) {
        return false;
    }
    return true;
}

hmd_async_stack_record_t *hmd_async_stack_trace_current_thread(void) {
    if (!atomic_load_explicit(&enable_async_stack_trace,memory_order_acquire)) {
        return NULL;
    }
    hmd_async_stack_record_t *pre_record = pthread_getspecific(hmd_async_stack_key);
    if (pre_record && pre_record->valid && pre_record->length <= HMD_MAX_ASYNC_STACK_LENGTH) {
        return pre_record;
    }
    return NULL;
}

hmd_async_stack_record_t *hmd_async_stack_trace_pthread(pthread_t thread) {
    if (!atomic_load_explicit(&enable_async_stack_trace,memory_order_acquire)) {
        return NULL;
    }
    return hmd_get_async_stack_pool_record_pthread(thread);
}

hmd_async_stack_record_t *hmd_async_stack_trace_mach_thread(thread_t thread) {
    if (!atomic_load_explicit(&enable_async_stack_trace,memory_order_acquire)) {
        return NULL;
    }
    return hmd_get_async_stack_pool_record_mach_thread(thread);
}

void hmd_async_stack_reading(bool reading) {
    hmd_async_stack_record_list_set_reading(async_shared_stack_record_list(), reading);
}

static hmd_async_stack_record_t *record_current_stack(void) {
    
    mark_start
    
    thread_t thread = mach_thread_self();
    mach_port_deallocate(current_task(), thread);
    hmd_async_stack_record_t *record = hmd_allocate_async_stack_pool_record(thread);
    if (record == NULL) {
        GCC_FORCE_NO_OPTIMIZATION return NULL;
    }
    record->pre_pthread = pthread_self();
    record->pre_thread = thread;
    record->length = backtrace(record->backtrace, HMD_MAX_ASYNC_STACK_LENGTH);
    record->skip_length=1;
    record->async_times=1;
    const char *queue_name = dispatch_queue_get_label(NULL);
    if (queue_name) {
        snprintf(record->thread_name, sizeof(record->thread_name), "%s",queue_name);
        record->thread_name[sizeof(record->thread_name)-1] = 0;
    } else {
        if (pthread_getname_np(pthread_self(), record->thread_name, sizeof(record->thread_name)) != 0) {
            snprintf(record->thread_name, sizeof(record->thread_name), "null(%u)", record->pre_thread);
            record->thread_name[sizeof(record->thread_name)-1] = 0;
        }
    }
    snprintf(record->pre_thread_ids, sizeof(record->pre_thread_ids), "%u", thread);
    record->pre_thread_ids[sizeof(record->pre_thread_ids)-1] = 0;
    
    if (atomic_load_explicit(&enable_multiple_async_stack_trace,memory_order_acquire)) {
        hmd_async_stack_record_t *pre_record = pthread_getspecific(hmd_async_stack_key);
        if (pre_record && pre_record->valid) {
            for (size_t i = pre_record->skip_length; i < pre_record->length; i++) {
                if (record->length >= HMD_MAX_ASYNC_STACK_LENGTH || i >= HMD_MAX_ASYNC_STACK_LENGTH) {
                    break;
                }
                record->backtrace[record->length] = pre_record->backtrace[i];
                record->length++;
            }
            record->async_times += pre_record->async_times;
            size_t thread_name_len = strlen(record->thread_name);
            size_t pre_thread_name_len = strlen(pre_record->thread_name);
            if (thread_name_len && pre_thread_name_len){
                snprintf(record->thread_name,  sizeof(record->thread_name), "%s <= %s",record->thread_name, pre_record->thread_name);
                record->thread_name[sizeof(record->thread_name)-1] = 0;
            }
            size_t pre_thread_ids_len = strlen(pre_record->pre_thread_ids);
            if (pre_thread_ids_len) {
                snprintf(record->pre_thread_ids, sizeof(record->pre_thread_ids), "%u <= %s", record->pre_thread, pre_record->pre_thread_ids);
                record->pre_thread_ids[sizeof(record->pre_thread_ids)-1] = 0;
            }
        }
    }
    
    mark_end;
    GCC_FORCE_NO_OPTIMIZATION return record;
}

static void insert_stack_record(hmd_async_stack_record_t *record){
    if (record == NULL) {
        return;
    }
    
    mark_start
    
    record->pthread = pthread_self();
    thread_t thread = mach_thread_self();
    mach_port_deallocate(current_task(), thread);
    record->thread = thread;
    record->valid = true;
//    void *node = hmd_nasync_stack_record_append(shared_stack_record_list(), record);
    int ret = pthread_setspecific(hmd_async_stack_key, record);
    if (ret != 0) {
        DEBUG_LOG("set pthread specific value err, %d", ret);
    }
    mark_end

    return;
}

static void remove_stack_record(hmd_async_stack_record_t *record){
    if (record == NULL) {
        return;
    }

    mark_start

    record->valid = false;
//    hmd_nasync_stack_record_remove(shared_stack_record_list(), record);
    hmd_free_async_stack_pool_record(record);
    int ret = pthread_setspecific(hmd_async_stack_key, NULL);

    if (ret != 0) {
        DEBUG_LOG("remove pthread specific value err, %d", ret);
    }

    mark_end
}

CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_UNUSED_FUNCTION
static void remove_stack_record_node(void *node){
    if (node == NULL) {
        return;
    }

    mark_start
    
    hmd_nasync_stack_record_remove_node(shared_stack_record_list(), node);
    if (atomic_load_explicit(&enable_multiple_async_stack_trace,memory_order_acquire)) {
        int ret = pthread_setspecific(hmd_async_stack_key, NULL);

        if (ret != 0) {
            DEBUG_LOG("remove pthread specific value err, %d", ret);
        }
    }
    mark_end
}
CLANG_DIAGNOSTIC_POP

static dispatch_block_t DISPATCH_IS_CALLING(dispatch_block_t block){
    if (!hmd_async_stack_trace_enabled()) {
        return block;
    }
    if (block == NULL) {
        return NULL;
    }
    hmd_async_stack_record_t *record = record_current_stack();
    if (record == NULL) {
        return block;
    }
    record->skip_length++;
    dispatch_block_t new_block = ^{
        insert_stack_record(record);
        block();
        record->valid = false;
        remove_stack_record(record);
    };
    GCC_FORCE_NO_OPTIMIZATION;
    return [new_block copy];
}

#pragma mark - hook macros

#define HMD(x) __DISPATCH_IS_CALLING_##x
#define ORI(func) ori_##func
#define REBINDING(func) \
    {#func, HMD(func), (void *)&ORI(func)}

#define HOOK(ret_type,func,...) \
static ret_type (*ORI(func))(__VA_ARGS__);\
static ret_type (HMD(func))(__VA_ARGS__)

#pragma mark - dispatch_xxx

HOOK(void, dispatch_async, dispatch_queue_t queue, dispatch_block_t block) {
    if (ori_dispatch_async) {
        @autoreleasepool {
            ori_dispatch_async(queue,DISPATCH_IS_CALLING(block));
        }
    }
}

HOOK(void, dispatch_group_async, dispatch_group_t group, dispatch_queue_t queue, dispatch_block_t block) {
    if (ori_dispatch_group_async) {
        @autoreleasepool {
            ori_dispatch_group_async(group,queue,DISPATCH_IS_CALLING(block));
        }
    }
}

HOOK(void, dispatch_barrier_async, dispatch_queue_t queue, dispatch_block_t block) {
    if (ori_dispatch_barrier_async) {
        @autoreleasepool {
            ori_dispatch_barrier_async(queue,DISPATCH_IS_CALLING(block));
        }
    }
}

HOOK(void, dispatch_after, dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t block) {
    if (ori_dispatch_after) {
        @autoreleasepool {
            ori_dispatch_after(when,queue,DISPATCH_IS_CALLING(block));
        }
    }
}

#pragma mark - dispatch_xxx_f

typedef struct {
    void *context;
    dispatch_function_t work;
    hmd_async_stack_record_t *record;
}hmd_async_stack_record_context;

static hmd_async_stack_record_context *async_stack_record_context(void *context, dispatch_function_t work){
    hmd_async_stack_record_context *c = calloc(1, sizeof(hmd_async_stack_record_context));
    if (c == NULL) {
        return NULL;
    }
    c->context = context;
    c->work = work;
    if (hmd_async_stack_trace_enabled()) {
        hmd_async_stack_record_t *record = record_current_stack();
        if (record) {
            record->skip_length++;
        }
        c->record = record;
    }
    GCC_FORCE_NO_OPTIMIZATION;
    return c;
}

static void __DISPATCH_IS_CALLING_work_invoke(hmd_async_stack_record_context *context) {
    if (context) {
        if (context->work) {
            insert_stack_record(context->record);
            context->work(context->context);
            if (context->record) {
                context->record->valid = false;
            }
            remove_stack_record(context->record);
        }
        free(context);
    }
}

HOOK(void, dispatch_async_f, dispatch_queue_t queue, void * context, dispatch_function_t work) {
    if (ori_dispatch_async_f) {
        @autoreleasepool {
            ori_dispatch_async_f(queue, async_stack_record_context(context, work), (dispatch_function_t)__DISPATCH_IS_CALLING_work_invoke);
        }
    }
}

HOOK(void, dispatch_group_async_f, dispatch_group_t group, dispatch_queue_t queue, void * context, dispatch_function_t work) {
    if (ori_dispatch_group_async_f) {
        @autoreleasepool {
            ori_dispatch_group_async_f(group, queue, async_stack_record_context(context, work), (dispatch_function_t)__DISPATCH_IS_CALLING_work_invoke);
        }
    }
}

HOOK(void, dispatch_barrier_async_f, dispatch_queue_t queue, void * context, dispatch_function_t work) {
    if (ori_dispatch_barrier_async_f) {
        @autoreleasepool {
            ori_dispatch_barrier_async_f(queue, async_stack_record_context(context, work), (dispatch_function_t)__DISPATCH_IS_CALLING_work_invoke);
        }
    }
}

HOOK(void, dispatch_after_f, dispatch_time_t when, dispatch_queue_t queue, void * context, dispatch_function_t work) {
    if (ori_dispatch_after_f) {
        @autoreleasepool {
            ori_dispatch_after_f(when, queue, async_stack_record_context(context, work), (dispatch_function_t)__DISPATCH_IS_CALLING_work_invoke);
        }
    }
}

#pragma mark - hook

static void image_add_callback (const struct mach_header *mh, intptr_t vmaddr_slide) {
    dispatch_async(async_trace_queue, ^{
        Dl_info info;
        
        /* Look up the image info */
        if (dladdr(mh, &info) == 0) {
            HMDPrint("%s: dladdr(%p, ...) failed", __FUNCTION__, mh);
            return;
        }
        
        if (strlen(hmd_main_bundle_path) == 0) {
#ifdef DEBUG
            assert(0);
#endif
            return;
        }

        if (hmd_reliable_has_suffix(info.dli_fname, ".dylib")) {
            return;
        }
        
        if (mh->filetype != MH_EXECUTE) {
            if (!hmd_is_in_app_bundle(info.dli_fname)) {
                return;
            }
        }

        struct bd_rebinding r[] = {
            REBINDING(dispatch_async),
            REBINDING(dispatch_group_async),
            REBINDING(dispatch_barrier_async),
            REBINDING(dispatch_after),
            REBINDING(dispatch_async_f),
            REBINDING(dispatch_group_async_f),
            REBINDING(dispatch_barrier_async_f),
            REBINDING(dispatch_after_f)
        };
        bd_rebind_symbols_image((void *)mh, vmaddr_slide, r, sizeof(r)/sizeof(struct bd_rebinding));
    });
}

void hmd_enable_async_stack_trace(void) {
    atomic_store_explicit(&enable_async_stack_trace,true,memory_order_release);
    static atomic_flag token;
    if (atomic_flag_test_and_set_explicit(&token, memory_order_release)) {
        return;
    }

    if (!HMD_IS_ADDRESS_SANITIZER && !HMD_IS_THREAD_SANITIZER) {
        mark_start
        if (!async_trace_queue) {
            async_trace_queue = hmd_fishhook_queue();
        }

        int ret = pthread_key_create(&hmd_async_stack_key, NULL);

        if (ret == 0) {
            if(hmd_init_async_stack_pool(100)){
                
                dispatch_async(async_trace_queue, ^{
                    _dyld_register_func_for_add_image(image_add_callback);
                    hook_objc_selectors();
//                    struct bd_rebinding r[] = {
//                        REBINDING(dispatch_async),
//                        REBINDING(dispatch_group_async),
//                        REBINDING(dispatch_barrier_async),
//                        REBINDING(dispatch_after),
//                        REBINDING(dispatch_async_f),
//                        REBINDING(dispatch_group_async_f),
//                        REBINDING(dispatch_barrier_async_f),
//                        REBINDING(dispatch_after_f)
//                    };
//                    bd_rebind_symbols_patch(r, sizeof(r)/sizeof(struct bd_rebinding));
                });
            }ELSE_DEBUG_LOG("init async stack pool err");
        }ELSE_DEBUG_LOG("creat pthread key err, %d", ret);
        mark_end
    }
}

void hmd_disable_async_stack_trace(void) {
    atomic_store_explicit(&enable_async_stack_trace,false,memory_order_release);
}

static bool hmd_async_stack_trace_enabled(void) {
    return atomic_load_explicit(&enable_async_stack_trace,memory_order_acquire);
}

void hmd_enable_multiple_async_stack_trace(void) {
    atomic_store_explicit(&enable_multiple_async_stack_trace,true,memory_order_release);
}

void hmd_disable_multiple_async_stack_trace(void) {
    atomic_store_explicit(&enable_multiple_async_stack_trace,false,memory_order_release);
}


#pragma mark - hook objc sel

@interface HMDAsyncTraceWrapperObject : NSObject
@property (nonatomic,assign) SEL sel;
@property (nonatomic,strong) id arg;
@property (nonatomic,assign) hmd_async_stack_record_t *record;
@end

@implementation HMDAsyncTraceWrapperObject
@end

static IMP ori_perform_selector_imp;
static IMP ori_perform_background_imp;

static HMDAsyncTraceWrapperObject *async_stack_record_object(SEL sel, id arg){
    HMDAsyncTraceWrapperObject *object = [[HMDAsyncTraceWrapperObject alloc] init];
    object.sel = sel;
    object.arg = arg;
    if (hmd_async_stack_trace_enabled()) {
        hmd_async_stack_record_t *record = record_current_stack();
        if (record) {
            record->skip_length++;
        }
        object.record = record;
    }
    GCC_FORCE_NO_OPTIMIZATION;
    return object;
}

@interface NSObject(HMDAsyncTrace)
- (void)hmd_async_trace_performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(nullable id)arg waitUntilDone:(BOOL)wait modes:(nullable NSArray<NSString *> *)array;
@end

@implementation NSObject(HMDAsyncTrace)
- (void)hmd_async_trace_performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(nullable id)arg waitUntilDone:(BOOL)wait modes:(nullable NSArray<NSString *> *)array {
    typedef void(*hmd_async_trace_sel_imp)(id self, SEL sel, SEL aSelector, NSThread *thr, id arg, BOOL wait, NSArray *array);
    hmd_async_trace_sel_imp ori_imp = (hmd_async_trace_sel_imp)ori_perform_selector_imp;
    if(ori_imp == NULL) {
        NSAssert(NO, @"");
        return;
    }
    SEL cmd = @selector(performSelector:onThread:withObject:waitUntilDone:modes:);
    if(wait){
        ori_imp(self,cmd,aSelector,thr,arg,wait,array);
    } else {
        SEL wrapperSEL = @selector(hmd_async_trace_performWithWrapperObject:);
        @autoreleasepool {
            ori_imp(self,cmd,wrapperSEL,thr,async_stack_record_object(aSelector, arg),wait,array);
        }
    }
}

- (void)hmd_async_trace_performSelectorInBackground:(SEL)aSelector withObject:(id)arg {
    typedef void(*hmd_async_trace_background_sel_imp)(id self, SEL sel, SEL aSelector, id arg);
    hmd_async_trace_background_sel_imp ori_imp = (hmd_async_trace_background_sel_imp)ori_perform_background_imp;
    if(ori_imp == NULL) {
        NSAssert(NO, @"");
        return;
    }
    SEL cmd = @selector(performSelector:onThread:withObject:waitUntilDone:modes:);
    SEL wrapperSEL = @selector(hmd_async_trace_performWithWrapperObject:);
    @autoreleasepool {
        ori_imp(self,cmd,wrapperSEL,async_stack_record_object(aSelector, arg));
    }
}

- (void)hmd_async_trace_performWithWrapperObject:(HMDAsyncTraceWrapperObject *)object {
    if(object) {
        hmd_async_stack_record_t *record = object.record;
        insert_stack_record(record);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:object.sel withObject:object.arg];
#pragma clang diagnostic pop
        if (record) {
            record->valid = false;
        }
        remove_stack_record(record);
    }
}

@end


static void hook_objc_selectors(void) {
    SEL oriSel = @selector(performSelector:onThread:withObject:waitUntilDone:modes:);
    SEL targetSel = @selector(hmd_async_trace_performSelector:onThread:withObject:waitUntilDone:modes:);
    ori_perform_selector_imp = class_getMethodImplementation(NSObject.class,oriSel);
    
    SEL ori_background_Sel = @selector(performSelectorInBackground:withObject:);
    SEL ori_target_background_Sel = @selector(hmd_async_trace_performSelectorInBackground:withObject:);
    ori_perform_background_imp = class_getMethodImplementation(NSObject.class, ori_background_Sel);
    
    atomic_thread_fence(memory_order_release);
    
    hmd_swizzle_instance_method(NSObject.class, oriSel, targetSel);
    hmd_swizzle_instance_method(NSObject.class, ori_background_Sel, ori_target_background_Sel);
}
