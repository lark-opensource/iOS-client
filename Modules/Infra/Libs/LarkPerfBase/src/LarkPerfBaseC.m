//
//  LarkPerfBaseC.m
//  LarkPerfBase
//
//  Created by ByteDance on 2023/3/9.
//

#import "LarkPerfBaseC.h"

kern_return_t lark_powerlog_device_cpu_load(host_cpu_load_info_t cpu_load) {
    mach_msg_type_number_t  count = HOST_CPU_LOAD_INFO_COUNT;
    host_cpu_load_info_data_t cpu_load_info;
    mach_port_t host_port = mach_host_self();
    kern_return_t kr = host_statistics(host_port, HOST_CPU_LOAD_INFO, (host_info_t)&cpu_load_info, &count);
    mach_port_deallocate(mach_task_self(), host_port);
    
    if (kr == KERN_SUCCESS) {
        if (cpu_load) {
            *cpu_load = cpu_load_info;
        }
    }
    return kr;
}

host_cpu_load_info_data_t lark_perfbase_device_cpu(void) {
    host_cpu_load_info_data_t cpu_load_info;
    kern_return_t kr = lark_powerlog_device_cpu_load(&cpu_load_info);
    if (kr == KERN_SUCCESS) {
        return cpu_load_info;
    }
    return cpu_load_info;
}

double lark_perfbase_device_cpu_cal(host_cpu_load_info_data_t begin,host_cpu_load_info_data_t end){
    natural_t delta_user_cpu = end.cpu_ticks[CPU_STATE_USER] - begin.cpu_ticks[CPU_STATE_USER];
    natural_t delta_system_cpu = end.cpu_ticks[CPU_STATE_SYSTEM] - begin.cpu_ticks[CPU_STATE_SYSTEM];
    natural_t delta_idle_cpu = end.cpu_ticks[CPU_STATE_IDLE] - begin.cpu_ticks[CPU_STATE_IDLE];
    natural_t delta_nice_cpu = end.cpu_ticks[CPU_STATE_NICE] - begin.cpu_ticks[CPU_STATE_NICE];
    
    double device_cpu_usage = 0;
    natural_t total_cpu = delta_user_cpu + delta_system_cpu + delta_idle_cpu + delta_nice_cpu;
    natural_t active = delta_user_cpu + delta_system_cpu + delta_nice_cpu;
    if (total_cpu > 0) {
        device_cpu_usage = (active*1.0)/total_cpu;
    }
    return device_cpu_usage;
}
