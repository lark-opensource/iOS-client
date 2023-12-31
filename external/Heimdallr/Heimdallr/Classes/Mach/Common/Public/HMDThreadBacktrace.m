//
//  HMDThreadBacktrace.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/25.
//

#import "HMDThreadBacktrace.h"
#import "HMDAsyncThread.h"
#import "hmd_mach.h"
#import "hmd_thread_backtrace.h"
#import "HMDMacro.h"
#import "hmd_symbolicator.h"
#import "HMDCompactUnwind.hpp"
#import "HMDThreadBacktraceFrame.h"
#import "hmd_crash_async_stack_trace.h"

extern hmd_thread hmdbt_main_thread;

typedef void(malloc_logger_t)(uint32_t type, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t result,
                              uint32_t num_hot_frames_to_skip);
extern malloc_logger_t *malloc_logger;

static HMDThreadBacktrace *construct_with_hmd_thread_backtrace(hmdbt_backtrace_t *bt) {
    HMDThreadBacktrace *backtrace = [[HMDThreadBacktrace alloc] init];
    NSMutableArray<HMDThreadBacktraceFrame *> *stackFrames = [[NSMutableArray alloc] init];
    if (bt->frames != NULL) {
        for (int i = 0; i < bt->frame_count; i++) {
            HMDThreadBacktraceFrame *frame = [[HMDThreadBacktraceFrame alloc] init];
            hmdbt_frame_t *originFrame = &(bt->frames[i]);
            frame.stackIndex = originFrame->stack_index;
            frame.address = originFrame->address;
            [stackFrames addObject:frame];
        }
    }
    
    hmd_async_stack_reading(true);
    hmd_async_stack_record_t *pre_bt = hmd_async_stack_trace_mach_thread(bt->thread_id);
    bool has_pre_stack = false;
    size_t async_times = 0;
    int pre_stack_index = (int)bt->frame_count;
    if (pre_bt != NULL) {
        if (pre_bt->valid) {
            has_pre_stack = true;
            async_times = pre_bt->async_times;
            for (size_t i=pre_bt->skip_length; i < pre_bt->length; i++){
                HMDThreadBacktraceFrame *frame = [[HMDThreadBacktraceFrame alloc] init];
                frame.address = (uintptr_t)(pre_bt->backtrace[i]);
                frame.stackIndex = pre_stack_index;
                [stackFrames addObject:frame];
                pre_stack_index++;
            }
        }
    }
    hmd_async_stack_reading(false);
    
    if(bt->name != NULL) {
        NSString *name = [NSString stringWithUTF8String:bt->name];
        if (has_pre_stack && strlen(pre_bt->thread_name) > 0) {
            name = [NSString stringWithFormat:@"%@ <= %@", name, [NSString stringWithUTF8String:pre_bt->thread_name]];
        }
        backtrace.name = name;
    }
    
    backtrace.threadID = bt->thread_id;
    backtrace.threadIndex = bt->thread_idx;
    backtrace.stackFrames = [stackFrames copy];
    backtrace.threadCpuUsage = bt->thread_cpu_usage;
    backtrace.async_times = (int)async_times;
    return backtrace;
}

int hmd_async_stack_trace_base_info_current_thread(hmd_async_stack_record_base_info_t * _Nonnull info) {
    hmd_async_stack_record_t *pre_bt = hmd_async_stack_trace_current_thread();
    if (pre_bt && pre_bt->valid && info) {
        info->pre_pthread = pre_bt->pre_pthread;
        info->pre_thread = pre_bt->pre_thread;
        info->thread = pre_bt->thread;
        info->pthread = pre_bt->pthread;
        
        strncpy(info->pre_thread_ids, pre_bt->pre_thread_ids, sizeof(info->pre_thread_ids));
        strncpy(info->thread_name, pre_bt->thread_name, sizeof(info->thread_name));
        memcpy(info->backtrace, pre_bt->backtrace, sizeof(info->backtrace));
        
        info->length = pre_bt->length;
        info->async_times = pre_bt->async_times;
        return 1;
    }
    return -1;
}

#pragma mark - HMDThreadBacktrace

@implementation HMDThreadBacktrace

+ (void)load {
    if (pthread_main_np() == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            hmdbt_main_thread = hmdthread_self();
            hmdbt_main_pthread = pthread_self();
        });
    }
    else {
        hmdbt_main_thread = hmdthread_self();
        hmdbt_main_pthread = pthread_self();
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _threadID = 0;
        _threadIndex = 0;
        _threadCpuUsage = 0;
        _crashed = NO;
        _isSymbol = NO;
    }
    
    return self;
}

#pragma mark - Public

+ (thread_t)mainThread {
    return (thread_t)hmdbt_main_thread;
}

+ (thread_t)currentThread {
    return (thread_t)hmdthread_self();
}

+ (vm_address_t)getImageHeaderAddressWithName:(NSString *)name {
    __block vm_address_t header_adress = 0;
    hmd_enumerate_image_list_using_block(^(hmd_async_image_t *image, int index, bool *stop) {
        NSString *imageName = [[NSString stringWithUTF8String:image->macho_image.name] lastPathComponent];
        if ([name isEqualToString:imageName]) {
            header_adress = image->macho_image.header_addr;
            *stop = true;
        }
    });
    return header_adress;
}

+ (vm_address_t)getAppImageHeaderAddressWithName:(NSString *)name {
    __block vm_address_t header_adress = 0;
    hmd_enumerate_app_image_list_using_block(^(hmd_async_image_t *image, int index, bool *stop) {
        NSString *imageName = [[NSString stringWithUTF8String:image->macho_image.name] lastPathComponent];
        if ([name isEqualToString:imageName]) {
            header_adress = image->macho_image.header_addr;
            *stop = true;
        }
    });
    return header_adress;
}

+ (NSArray<HMDThreadBacktrace *> *)backtraceOfAllThreadsWithParameter:(HMDThreadBacktraceParameter *)parameter {
    // get origin backtrance
    int size = 0;
    hmdbt_backtrace_t *backtraces = hmdbt_origin_backtraces_of_all_threads(&size, parameter.skippedDepth+1, parameter.suspend, parameter.maxThreadCount);
    NSArray<HMDThreadBacktrace *>* backtraceList = [self createBacktraceList:backtraces
                                                                        size:size
                                                                   keyThread:parameter.keyThread
                                                                 symbolicate:parameter.needDebugSymbol];
    hmdbt_dealloc_bactrace(&backtraces, size);
    GCC_FORCE_NO_OPTIMIZATION return backtraceList;
}

+ (HMDThreadBacktrace * _Nullable)backtraceOfThreadWithParameter:(HMDThreadBacktraceParameter *)parameter {
    hmdbt_backtrace_t *bt;
    if (parameter.isGetMainThread) {
        bt = hmdbt_origin_backtrace_of_main_thread(parameter.skippedDepth + 1, parameter.suspend, false);
    }else{
        bt = hmdbt_origin_backtrace_of_thread(parameter.keyThread, parameter.skippedDepth + 1, parameter.suspend);
    }
    if (bt == NULL) {
        GCC_FORCE_NO_OPTIMIZATION return nil;
    }
    HMDThreadBacktrace *backtrace = construct_with_hmd_thread_backtrace(bt);
    backtrace.crashed = YES;
    if (parameter.needDebugSymbol) {
        [backtrace symbolicate:true];
    }
    
    hmdbt_dealloc_bactrace(&bt, 1);
    GCC_FORCE_NO_OPTIMIZATION return backtrace;
    
}

+ (NSArray<HMDThreadBacktrace *> *)backtraceOfAllThreadsWithKeyThread:(thread_t)keyThread
                                                          symbolicate:(BOOL)symbolicate
                                                         skippedDepth:(NSUInteger)skippedDepth
                                                              suspend:(BOOL)suspend
                                                       maxThreadCount:(NSUInteger)maxThreadCount {
    // get origin backtrance
    int size = 0;
    hmdbt_backtrace_t *backtraces = hmdbt_origin_backtraces_of_all_threads(&size, skippedDepth+1, suspend, maxThreadCount);
    NSArray<HMDThreadBacktrace *>* backtraceList = [self createBacktraceList:backtraces
                                                                        size:size
                                                                   keyThread:keyThread
                                                                 symbolicate:symbolicate];
    hmdbt_dealloc_bactrace(&backtraces, size);
    GCC_FORCE_NO_OPTIMIZATION return backtraceList;
}

+ (HMDThreadBacktrace * _Nullable)backtraceOfMainThreadWithSymbolicate:(BOOL)symbolicate
                                                skippedDepth:(NSUInteger)skippedDepth
                                                     suspend:(BOOL)suspend {
    hmdbt_backtrace_t *bt = hmdbt_origin_backtrace_of_main_thread(skippedDepth + 1, suspend, false);
    if (bt == NULL) {
        GCC_FORCE_NO_OPTIMIZATION return nil;
    }
    
    HMDThreadBacktrace *backtrace = construct_with_hmd_thread_backtrace(bt);
    if (symbolicate) {
        [backtrace symbolicate:true];
    }
    
    backtrace.crashed = YES;
    hmdbt_dealloc_bactrace(&bt, 1);
    GCC_FORCE_NO_OPTIMIZATION return backtrace;
}

+ (HMDThreadBacktrace * _Nullable)backtraceOfThread:(thread_t)thread
                              symbolicate:(BOOL)symbolicate
                             skippedDepth:(NSUInteger)skippedDepth
                                  suspend:(BOOL)suspend {
    hmdbt_backtrace_t *bt = hmdbt_origin_backtrace_of_thread(thread, skippedDepth + 1, suspend);
    if (bt == NULL) {
        GCC_FORCE_NO_OPTIMIZATION return nil;
    }
    
    HMDThreadBacktrace *backtrace = construct_with_hmd_thread_backtrace(bt);
    backtrace.crashed = YES;
    if (symbolicate) {
        [backtrace symbolicate:true];
    }
    
    hmdbt_dealloc_bactrace(&bt, 1);
    GCC_FORCE_NO_OPTIMIZATION return backtrace;
}

+ (NSArray <HMDThreadBacktrace *>*)createBacktraceList:(hmdbt_backtrace_t *)backtraces
                                                  size:(NSInteger)size
                                             keyThread:(thread_t)keyThread
                                           symbolicate:(BOOL)symbolicate {
    NSMutableArray<HMDThreadBacktrace *> *backtraceList = [[NSMutableArray alloc] initWithCapacity:size];
    for (int i = 0; i < size; i ++) {
        hmdbt_backtrace_t *bt = &(backtraces[i]);
        HMDThreadBacktrace *backtrace = construct_with_hmd_thread_backtrace(bt);
        if (symbolicate) {
            [backtrace symbolicate:true];
        }
        
        if (backtrace.threadID == keyThread) {
            backtrace.crashed = YES;
        }
        
        [backtraceList addObject:backtrace];
    }
    
    return [backtraceList copy];
}

+ (HMDThreadBacktraceFrame *)symbolicateForAddress:(uintptr_t)address{
    HMDThreadBacktraceFrame *frame = [[HMDThreadBacktraceFrame alloc] init];
    frame.address = address;
    [frame symbolicate:true];
    return frame;
}

- (void)symbolicate:(bool)needSymbolName {
    if (_isSymbol) {
        return;
    }
    
    _isSymbol = YES;
    hmd_setup_shared_image_list_if_need();
    for (HMDThreadBacktraceFrame *frame in self.stackFrames) {
        [frame symbolicate:needSymbolName];
    }
    
    return;
}

- (uintptr_t)topAppAddress {
    NSArray<HMDThreadBacktraceFrame*> *frames = _stackFrames;
    if (!(frames && frames.count > 0)) {
        return 0;
    }
    
    uintptr_t address = 0;
    hmd_setup_shared_image_list(); // 首次调用耗时
    hmd_async_image_list_set_reading(&shared_app_image_list, true);
    for (HMDThreadBacktraceFrame * _Nonnull frame in frames) {
        if (frame && frame.address > 0 && hmd_async_image_containing_address(&shared_app_image_list, frame.address)) {
            address = frame.address;
            break;
        }
    }
    
    hmd_async_image_list_set_reading(&shared_app_image_list, false);
    return address;
}

- (uintptr_t)bottomAppAddress {
    NSArray<HMDThreadBacktraceFrame*> *frames = _stackFrames;
    if (!(frames && frames.count > 0)) {
        return 0;
    }
    
    __block uintptr_t address = 0;
    hmd_setup_shared_image_list(); // 首次调用耗时
    hmd_async_image_list_set_reading(&shared_app_image_list, true);
    [frames enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(HMDThreadBacktraceFrame * _Nonnull frame, NSUInteger idx, BOOL * _Nonnull stop) {
        if (frame && frame.address > 0 && hmd_async_image_containing_address(&shared_app_image_list, frame.address)) {
            address = frame.address;
            *stop = YES;
        }
    }];
    
    hmd_async_image_list_set_reading(&shared_app_image_list, false);
    return address;
}

#pragma mark HMDJSONable
- (NSDictionary *)jsonObject {
    NSMutableDictionary *data = [NSMutableDictionary
        dictionaryWithObjectsAndKeys:@(_threadIndex), @"thread_index", @(_threadID), @"thread_id", @(_threadCpuUsage), @"thread_cpu_usage", nil];

    if (_name) {
        [data setObject:_name forKey:@"name"];
    }

    NSArray *frames = [self.stackFrames valueForKey:@"jsonObject"];

    if (frames) {
        [data setObject:frames forKey:@"frames"];
    }
    return data;
}

- (NSString *)description {
    NSMutableString *string =
        [NSMutableString stringWithFormat:@"Thread %lu(%lu) ", (unsigned long)_threadIndex, _threadID];

    if (self.name) {
        [string appendFormat:@" name:%@", _name];
    }

    [string appendFormat:@" (cpu_usage: %.2f%%)", _threadCpuUsage];
    for (HMDThreadBacktraceFrame *frame in self.stackFrames) {
        [string appendFormat:@"\n%@", frame];
    }

    [string appendString:@"\n"];
    return string;
}

+ (instancetype _Nullable)backtraceWithPointerArray:(NSPointerArray * _Nonnull)pointerArray {
    NSUInteger count = pointerArray.count;
    if(count == 0) DEBUG_RETURN(nil);
    
    HMDThreadBacktrace *backtrace = HMDThreadBacktrace.alloc.init;
    NSMutableArray<HMDThreadBacktraceFrame *> *stackFrames = [NSMutableArray arrayWithCapacity:count];
    
    for(NSUInteger index = 0; index < count; index++) {
        HMDThreadBacktraceFrame *frame = HMDThreadBacktraceFrame.alloc.init;
        frame.stackIndex = index;
        frame.address = (uintptr_t)[pointerArray pointerAtIndex:index];
        [stackFrames addObject:frame];
    }
    backtrace.name = @"null";
    backtrace.threadID = 0;
    backtrace.threadIndex = 0;
    backtrace.stackFrames = stackFrames;
    backtrace.crashed = YES;
    
    return backtrace;
}

@end
