//
//  HMDAsyncStackTraceDebug.h
//  Pods
//
//  Created by yuanzhangjing on 2019/11/11.
//

#import <Foundation/Foundation.h>

#define enable_time_profile 0

#if enable_time_profile

#include <os/lock.h>
#include <pthread.h>

#define mark_start \
CFTimeInterval __start = CACurrentMediaTime();
#define mark_end \
CFTimeInterval __end = CACurrentMediaTime(); \
CFTimeInterval __time_cost = (__end - __start)*1000; \
printf("%s %.3fms\n",__func__,__time_cost);

static double runloop_begin;
static double runloop_end;

struct _statistics_t {
    int record_times;
    double record_cost;

    int insert_times;
    double insert_cost;

    int remove_times;
    double remove_cost;
};
typedef struct _statistics_t _statistics_t;

struct _statistics_result_t {
    double avg_cost;
    double max_cost;
    double duration;
    uint64_t sample_count;
};
typedef struct _statistics_result_t _statistics_result_t;

static _statistics_result_t statistics_record_main;
static _statistics_result_t statistics_insert_main;
static _statistics_result_t statistics_remove_main;

static _statistics_result_t statistics_record;
static _statistics_result_t statistics_insert;
static _statistics_result_t statistics_remove;
static os_unfair_lock unfair_lock = OS_UNFAIR_LOCK_INIT;


static _statistics_t statistics_main_thread;
static _statistics_result_t statistics_result_main_thread;

void hmd_async_stack_update_statistics_result_t(_statistics_result_t *s,double time_cost);

void hmd_async_stack_print_statistics_result_t(const char *tag, _statistics_result_t *s,double time_cost);

void hmd_async_stack_addRunLoopObserver(void);

#else
#define mark_start
#define mark_end
#endif
