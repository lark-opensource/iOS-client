//
//  HMDCPUFreqTool.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/8/6.
//

#ifndef HMDCPUFreqTool_h
#define HMDCPUFreqTool_h

#include <stdio.h>


#ifdef __cplusplus
extern "C" {
#endif
/*
 获取CPU当前频率: !!! 注意该方法不要频繁调用,可能会block主线程或者其他线程,因为在执行这段代码的时候CPU可能会中断原有的工作流程,来执行CPU频率的测试工作,进而会影响或者block住其他线程的工作,待获取到CPU频率之后才能正常运行.
    建议只在怀疑当前CPU被降频时或者从降频恢复时,获取一次就可以;
 
 Get the current CPU frequency: !!! Note that this method should not be called too often, it may block the main thread or other threads, because the CPU may interrupt the original workflow when executing this code to perform the CPU frequency test, which may affect or block the work of other threads, until the CPU frequency is obtained to run normally.
    It is recommended to get the CPU frequency only once when you suspect that the current CPU is downclocked or when you recover from the downclock.
 */
double hmd_cpu_frequency(void);
double hmd_cpu_absolute_nanosecond_to_sec(uint64_t diff_time);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCPUFreqTool_h */
