//
//  HMDCPUUtilties.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/1/20.
//

#import "HMDCPUUtilties.h"
#include <sys/time.h>
#include <sys/sysctl.h>
#import <mach/port.h>
#import <mach/kern_return.h>
#import <mach/mach.h>
#import <dispatch/dispatch.h>

static double task_cpu_time = 0;
static double task_wall_time = 0;

unsigned int hmdCountOfCPUCores(void) {
    static unsigned int cpuCount = 1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t len = sizeof(cpuCount);
        sysctlbyname("hw.ncpu", &cpuCount, &len, NULL, 0);
    });
    return cpuCount;
}

long long hmdCPUTimestamp(void) {
    struct timeval time;
    gettimeofday(&time, NULL);
    long currentTime = (long) time.tv_sec * 1000 + (long) time.tv_usec / 1000;
    return currentTime;
}

double hmdCPUUsageFromClock(void) {

    double taskCpuTimeLast = ((double)clock())/(CLOCKS_PER_SEC * 1.0);

    struct timeval time;
    gettimeofday(&time,NULL);
    double taskWallTimeLast = (double)time.tv_sec + (double)time.tv_usec * .000001;
    double usage = 0;
    // 第一次调用的时候计算不出 CPU 使用率
    if (task_cpu_time == 0 || task_wall_time == 0 || taskWallTimeLast == task_wall_time) {
        usage = 0;
    } else {
        usage = ((taskCpuTimeLast - task_cpu_time) / (taskWallTimeLast - task_wall_time));
    }

    task_wall_time = taskWallTimeLast;
    task_cpu_time = taskCpuTimeLast;
    return usage;
}

double hmdCPUUsgeFromThread(void) {
    return hmdCPUUsageFromThread();
}


double hmdCPUUsageFromThread(void) {
    kern_return_t kr;

    thread_array_t threadList;
    mach_msg_type_number_t threadCount;

    thread_info_data_t thinfo;
    mach_msg_type_number_t threadInfoCount;

    thread_basic_info_t basicInfoTh;

    // get threads in the task
    kr = task_threads(mach_task_self(), &threadList, &threadCount);
    if (kr != KERN_SUCCESS) {
        return -1;
    }

    long totSec = 0;
    long totUsec = 0;
    float totCpu = 0;
    int j;

    for (j = 0; j < threadCount; j++) {
        threadInfoCount = THREAD_INFO_MAX;
        kr = thread_info(threadList[j], THREAD_BASIC_INFO,
                         (thread_info_t) thinfo, &threadInfoCount);
        if (kr != KERN_SUCCESS) {
            return -1;
        }

        basicInfoTh = (thread_basic_info_t) thinfo;

        if (!(basicInfoTh->flags & TH_FLAGS_IDLE)) {
            totSec = totSec + basicInfoTh->user_time.seconds + basicInfoTh->system_time.seconds;
            totUsec = totUsec + basicInfoTh->system_time.microseconds + basicInfoTh->system_time.microseconds;
            totCpu = totCpu + (((float)basicInfoTh->cpu_usage) / (float) TH_USAGE_SCALE * 100.0);
        }

    } // for each thread
    
    for(size_t index = 0; index < threadCount; index++)
        mach_port_deallocate(mach_task_self(), threadList[index]);

    kr = vm_deallocate(mach_task_self(), (vm_offset_t) threadList, threadCount * sizeof(thread_t));

    return totCpu;
}

double hmdCPUAverageUsageFromClock(void) {
    static int count = 0;
    if (count == 0) {
        count = hmdCountOfCPUCores();
    }
    double totoalUsage = hmdCPUUsageFromClock();
    if (count > 0) {
        return totoalUsage / ((double)count);
    }
    return totoalUsage;
}

double hmdCPUAverageUsageFromThread(void) {
    static int count = 0;
    if (count == 0) {
        count = hmdCountOfCPUCores();
    }
    double totoalUsage = hmdCPUUsageFromThread();
    if (count > 0) {
        return totoalUsage / ((double)count);
    }
    return totoalUsage;
}

double hmdCPUUsgeFromSingleThread(thread_t thread) {
    return hmdCPUUsageFromSingleThread(thread);
}

double hmdCPUUsageFromSingleThread(thread_t thread) {
    if(thread == THREAD_NULL) return -1;
    kern_return_t kr;
    thread_info_data_t thinfo;
    mach_msg_type_number_t threadInfoCount = THREAD_INFO_MAX;;
    thread_basic_info_t basicInfoTh;
    
    kr = thread_info(thread, THREAD_BASIC_INFO,(thread_info_t) thinfo, &threadInfoCount);
    if (kr != KERN_SUCCESS) {
        return -1;
    }

    basicInfoTh = (thread_basic_info_t) thinfo;
    float singleCpu = 0;
    if (!(basicInfoTh->flags & TH_FLAGS_IDLE))
        singleCpu = ((float)basicInfoTh->cpu_usage) / (float) TH_USAGE_SCALE * 100.0;
    
    return singleCpu;
}

int hmdHostCPUUsage(hmd_host_cpu_usage_info *cpu_usage) {
    int ret = -1;
    mach_msg_type_number_t  count = HOST_CPU_LOAD_INFO_COUNT;
    kern_return_t kr;
    static host_cpu_load_info_data_t pre_cpu_load_info;
    host_cpu_load_info_data_t cpu_load_info;

    mach_port_t host_port = mach_host_self();
    kr = host_statistics(host_port, HOST_CPU_LOAD_INFO, (host_info_t)&cpu_load_info, &count);
    mach_port_deallocate(mach_task_self(), host_port);
    if (kr != KERN_SUCCESS) {
        return ret;
    }

    if (cpu_usage && pre_cpu_load_info.cpu_ticks[CPU_STATE_USER] > 0) {
        int cpu_count = hmdCountOfCPUCores();
        natural_t user_cpu_differ = cpu_load_info.cpu_ticks[CPU_STATE_USER] - pre_cpu_load_info.cpu_ticks[CPU_STATE_USER];
        natural_t system_cpu_differ = cpu_load_info.cpu_ticks[CPU_STATE_SYSTEM] - pre_cpu_load_info.cpu_ticks[CPU_STATE_SYSTEM];
        natural_t idle_cpu_differ = cpu_load_info.cpu_ticks[CPU_STATE_IDLE] - pre_cpu_load_info.cpu_ticks[CPU_STATE_IDLE];
        natural_t nice_cpu_differ = cpu_load_info.cpu_ticks[CPU_STATE_NICE] - pre_cpu_load_info.cpu_ticks[CPU_STATE_NICE];
        
        natural_t total_cpu = user_cpu_differ + system_cpu_differ + idle_cpu_differ + nice_cpu_differ;

        double userUsage = 0;
        if (user_cpu_differ > 0 && total_cpu > 0) {
            userUsage = user_cpu_differ/(double)total_cpu;
        }
        double systemUsage = 0;
        if (system_cpu_differ > 0 && total_cpu > 0) {
            systemUsage = system_cpu_differ/(double)total_cpu;
        }
        double idle = 0;
        if (idle_cpu_differ > 0 && total_cpu > 0) {
            idle = idle_cpu_differ/(double)total_cpu;
        }
        double niceUsage = 0;
        if (nice_cpu_differ > 0 && total_cpu > 0) {
            niceUsage = nice_cpu_differ/(double)total_cpu;
        }
        cpu_usage->total = (userUsage + systemUsage + niceUsage) * cpu_count;
        cpu_usage->user = userUsage * cpu_count;
        cpu_usage->system = systemUsage * cpu_count;
        cpu_usage->idle = idle * cpu_count;
        cpu_usage->nice = niceUsage * cpu_count;
        ret = 1;
    }
    pre_cpu_load_info = cpu_load_info;
    return ret;
}

int hmdTaskCPUUsage(hmd_task_cpu_usage_info *cpu_usage) {
    int ret = -1;
    struct task_thread_times_info thread_info = {0};
    mach_msg_type_number_t count1 = TASK_THREAD_TIMES_INFO_COUNT;
    kern_return_t kret = task_info(current_task(), TASK_THREAD_TIMES_INFO, (task_info_t)&thread_info, &count1);
    if (kret != KERN_SUCCESS) {
        return ret;
    }
    
    struct task_basic_info base_info = {0};
    mach_msg_type_number_t count2 = TASK_BASIC_INFO_COUNT;
    kret = task_info(current_task(), TASK_BASIC_INFO, (task_info_t)&base_info, &count2);
    if (kret != KERN_SUCCESS) {
        return ret;
    }
    struct timeval time;
    gettimeofday(&time,NULL);
    static double task_total_time_last = 0;
    static double task_threads_user_time_last = 0;
    static double task_threads_system_time_last = 0;
    double task_total_time = (double)time.tv_sec + (double)time.tv_usec * .000001;
    double living_threads_system_time = (double)thread_info.system_time.seconds + (double)thread_info.system_time.microseconds * .000001;
    double terminated_threads_system_time = (double)base_info.system_time.seconds + (double)base_info.system_time.microseconds * .000001;
    double living_threads_user_time = (double)thread_info.user_time.seconds + (double)thread_info.user_time.microseconds * .000001;
    double terminated_threads_user_time = (double)base_info.user_time.seconds + (double)base_info.user_time.microseconds * .000001;
    double task_threads_user_time = terminated_threads_user_time + living_threads_user_time;
    double task_threads_system_time = terminated_threads_system_time + living_threads_system_time;
    if (cpu_usage && task_total_time > task_total_time_last && task_total_time_last != 0) {
        cpu_usage->user = (task_threads_user_time - task_threads_user_time_last) / (task_total_time - task_total_time_last);
        cpu_usage->system = (task_threads_system_time - task_threads_system_time_last) / (task_total_time - task_total_time_last);
        cpu_usage->total = cpu_usage->user + cpu_usage->system;
        ret = 1;
    }
    task_threads_user_time_last = task_threads_user_time;
    task_threads_system_time_last = task_threads_system_time;
    task_total_time_last = task_total_time;
    return ret;
}
