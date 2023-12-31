//
//  HMDCPUUtilties.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/1/20.
//


#import <mach/mach_types.h>
#ifdef __cplusplus
extern "C" {
#endif
    typedef struct hmd_host_cpu_usage_info {
        double total;
        double user;
        double system;
        double idle;
        double nice;
    } hmd_host_cpu_usage_info;

    typedef struct hmd_task_cpu_usage_info {
        double total;
        double user;
        double system;
    } hmd_task_cpu_usage_info;

    unsigned int hmdCountOfCPUCores(void);
    double hmdCPUUsageFromClock(void);
    double hmdCPUUsgeFromThread(void) __attribute__((deprecated("please use hmdCPUUsageFromThread")));
    double hmdCPUUsageFromThread(void);
    double hmdCPUAverageUsageFromClock(void);
    double hmdCPUAverageUsageFromThread(void);
    double hmdCPUUsgeFromSingleThread(thread_t thread) __attribute__((deprecated("please use hmdCPUUsageFromSingleThread")));
    double hmdCPUUsageFromSingleThread(thread_t thread);
    long long hmdCPUTimestamp(void);

    //get CPU usage between this call and the last in system, the first call will always fail. range of CPU usage: [0, cpu_cpunt]
    int hmdHostCPUUsage(hmd_host_cpu_usage_info *cpu_usage);
    //get CPU usage between this call and the last in task, the first call will always fail. range of CPU usage: [0, cpu_cpunt]
    int hmdTaskCPUUsage(hmd_task_cpu_usage_info *cpu_usage);
#ifdef __cplusplus
}
#endif
