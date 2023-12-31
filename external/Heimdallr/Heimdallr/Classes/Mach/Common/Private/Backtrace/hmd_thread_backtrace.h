//
//  hmd_thread_backtrace.h
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#ifndef hmd_thread_backtrace_h
#define hmd_thread_backtrace_h
#include <mach/mach_types.h>
#include <stdio.h>
#import "HMDAsyncThread.h"
#define HMDBT_MAX_THREADS_COUNT 50
#define HMDBT_MAX_FRAMES_COUNT 100
#define HMDBT_MAX_NAME_LENGTH 256
extern hmd_thread hmdbt_main_thread;
extern pthread_t hmdbt_main_pthread;

typedef struct hmdbt_frame {
    unsigned long address;
    unsigned long stack_index;
} hmdbt_frame_t;

typedef struct hmdbt_backtrace {
    hmdbt_frame_t *frames;
    size_t frame_count;
    char *name;
    size_t thread_idx;
    thread_t thread_id;
    // register not implementation
    float                   thread_cpu_usage;
//    policy_t                policy;         /* scheduling policy in effect */
    integer_t               run_state;      /* run state (see below) */
    integer_t               flags;          /* various flags (see below) */
    int32_t                 pth_curpri;                     /* cur priority*/
//    int32_t                 pth_priority;           /*  priority*/
//    int32_t                 pth_maxpriority;        /* max priority*/
} hmdbt_backtrace_t;

#ifdef __cplusplus
extern "C" {
#endif

bool hmdbt_all_threads(thread_act_array_t *thread_list, mach_msg_type_number_t *count);

unsigned long hmdbt_top_app_backtrace_addr_of_main_thread(unsigned long skippedDepth, bool suspend);

// 获取并设置main函数地址
void hmdbt_init_app_main_addr(void);

// 如果返回地址为0，说明堆栈回溯错误或者主线程倒数第二帧不是main函数地址
unsigned long hmdbt_get_app_main_addr(void);

// fast = true:不获取线程名 & 不创建name相关内存
hmdbt_backtrace_t *hmdbt_origin_backtrace_of_main_thread(unsigned long skippedDepth, bool suspend, bool fast);

hmdbt_backtrace_t *hmdbt_origin_backtrace_of_thread(hmd_thread thread, unsigned long skippedDepth, bool suspend);

hmdbt_backtrace_t *hmdbt_origin_backtraces_of_all_threads(int *size, unsigned long skippedDepth, bool suspend, unsigned long max_thread_count);

hmdbt_backtrace_t* hmdbt_fast_backtrace_of_main_thread(int skippedDepth, bool suspend);

// 通过以上方法创建的hmdbt_backtrace_t *，必须调用hmdbt_dealloc_bactrace进行析构
void hmdbt_dealloc_bactrace(hmdbt_backtrace_t **backtrace, int size);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif /* hmd_thread_backtrace_h */
