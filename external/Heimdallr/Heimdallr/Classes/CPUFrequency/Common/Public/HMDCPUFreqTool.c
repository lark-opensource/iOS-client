//
//  HMDCPUFreqTool.c
//  Heimdallr
//
//  Created by zhangxiao on 2021/8/6.
//

#include "HMDCPUFreqTool.h"
#import <mach/mach_time.h>

double hmd_cpu_absolute_nanosecond_to_sec(uint64_t diff_time) {
    static mach_timebase_info_data_t timebase;
    if (0 == timebase.denom) {
        mach_timebase_info(&timebase);
    }

    double usecs =  diff_time;
    if (timebase.denom == 0) { return 0; }
    usecs = diff_time * timebase.numer / timebase.denom;
    usecs = usecs / NSEC_PER_SEC;
    return usecs;
}

double hmd_cpu_frequency(void)
{
    double curFreq = 1;
#if defined(__arm64__)
    volatile uint64_t times[500] = {0.0};
    for(int i = 0; i < 500; i++)
    {
        times[i] = mach_absolute_time();
        int count = 10000;
        asm volatile (
            "0:"
            //loop 1
            "add     x2,  x2,  x1  \n"
            "add     x3,  x3,  x2  \n"
            "add     x4,  x4,  x3  \n"
            "add     x5,  x5,  x4  \n"
            "add     x6,  x6,  x5  \n"
            "add     x7,  x7,  x6  \n"
            "add     x8,  x8,  x7  \n"
            "add     x9,  x9,  x8  \n"
            "add     x10, x10, x9  \n"
            "add     x11, x11, x10 \n"
            "add     x12, x12, x11 \n"
            "add     x14, x14, x12 \n"
            "add     x1,  x1,  x14 \n"

            //loop 2
            "add     x2,  x2,  x1  \n"
            "add     x3,  x3,  x2  \n"
            "add     x4,  x4,  x3  \n"
            "add     x5,  x5,  x4  \n"
            "add     x6,  x6,  x5  \n"
            "add     x7,  x7,  x6  \n"
            "add     x8,  x8,  x7  \n"
            "add     x9,  x9,  x8  \n"
            "add     x10, x10, x9  \n"
            "add     x11, x11, x10 \n"
            "add     x12, x12, x11 \n"
            "add     x14, x14, x12 \n"
            "add     x1,  x1,  x14 \n"

            //loop 3
            "add     x2,  x2,  x1  \n"
            "add     x3,  x3,  x2  \n"
            "add     x4,  x4,  x3  \n"
            "add     x5,  x5,  x4  \n"
            "add     x6,  x6,  x5  \n"
            "add     x7,  x7,  x6  \n"
            "add     x8,  x8,  x7  \n"
            "add     x9,  x9,  x8  \n"
            "add     x10, x10, x9  \n"
            "add     x11, x11, x10 \n"
            "add     x12, x12, x11 \n"
            "add     x14, x14, x12 \n"
            "add     x1,  x1,  x14 \n"

            //loop 4
            "add     x2,  x2,  x1  \n"
            "add     x3,  x3,  x2  \n"
            "add     x4,  x4,  x3  \n"
            "add     x5,  x5,  x4  \n"
            "add     x6,  x6,  x5  \n"
            "add     x7,  x7,  x6  \n"
            "add     x8,  x8,  x7  \n"
            "add     x9,  x9,  x8  \n"
            "add     x10, x10, x9  \n"
            "add     x11, x11, x10 \n"
            "add     x12, x12, x11 \n"
            "add     x14, x14, x12 \n"
            "add     x1,  x1,  x14 \n"

            //loop 5
            "add     x2,  x2,  x1  \n"
            "add     x3,  x3,  x2  \n"
            "add     x4,  x4,  x3  \n"
            "add     x5,  x5,  x4  \n"
            "add     x6,  x6,  x5  \n"
            "add     x7,  x7,  x6  \n"
            "add     x8,  x8,  x7  \n"
            "add     x9,  x9,  x8  \n"
            "add     x10, x10, x9  \n"
            "add     x11, x11, x10 \n"
            "add     x12, x12, x11 \n"
            "add     x14, x14, x12 \n"
            "add     x1,  x1,  x14 \n"

            //loop 6
            "add     x2,  x2,  x1  \n"
            "add     x3,  x3,  x2  \n"
            "add     x4,  x4,  x3  \n"
            "add     x5,  x5,  x4  \n"
            "add     x6,  x6,  x5  \n"
            "add     x7,  x7,  x6  \n"
            "add     x8,  x8,  x7  \n"
            "add     x9,  x9,  x8  \n"
            "add     x10, x10, x9  \n"
            "add     x11, x11, x10 \n"
            "add     x12, x12, x11 \n"
            "add     x14, x14, x12 \n"
            "add     x1,  x1,  x14 \n"

            //loop 7
            "add     x2,  x2,  x1  \n"
            "add     x3,  x3,  x2  \n"
            "add     x4,  x4,  x3  \n"
            "add     x5,  x5,  x4  \n"
            "add     x6,  x6,  x5  \n"
            "add     x7,  x7,  x6  \n"
            "add     x8,  x8,  x7  \n"
            "add     x9,  x9,  x8  \n"
            "add     x10, x10, x9  \n"
            "add     x11, x11, x10 \n"
            "add     x12, x12, x11 \n"
            "add     x14, x14, x12 \n"
            "add     x1,  x1,  x14 \n"

            //loop 8
            "add     x2,  x2,  x1  \n"
            "add     x3,  x3,  x2  \n"
            "add     x4,  x4,  x3  \n"
            "add     x5,  x5,  x4  \n"
            "add     x6,  x6,  x5  \n"
            "add     x7,  x7,  x6  \n"
            "add     x8,  x8,  x7  \n"
            "add     x9,  x9,  x8  \n"
            "add     x10, x10, x9  \n"
            "add     x11, x11, x10 \n"
            "add     x12, x12, x11 \n"
            "add     x14, x14, x12 \n"
            "add     x1,  x1,  x14 \n"

            //loop 9
            "add     x2,  x2,  x1  \n"
            "add     x3,  x3,  x2  \n"
            "add     x4,  x4,  x3  \n"
            "add     x5,  x5,  x4  \n"
            "add     x6,  x6,  x5  \n"
            "add     x7,  x7,  x6  \n"
            "add     x8,  x8,  x7  \n"
            "add     x9,  x9,  x8  \n"
            "add     x10, x10, x9  \n"
            "add     x11, x11, x10 \n"
            "add     x12, x12, x11 \n"
            "add     x14, x14, x12 \n"
            "add     x1,  x1,  x14 \n"

            //loop q10
            "add     x2,  x2,  x1  \n"
            "add     x3,  x3,  x2  \n"
            "add     x4,  x4,  x3  \n"
            "add     x5,  x5,  x4  \n"
            "add     x6,  x6,  x5  \n"
            "add     x7,  x7,  x6  \n"
            "add     x8,  x8,  x7  \n"
            "add     x9,  x9,  x8  \n"
            "add     x10, x10, x9  \n"
            "add     x11, x11, x10 \n"
            "add     x12, x12, x11 \n"
            "add     x14, x14, x12 \n"
            "add     x1,  x1,  x14 \n"

            "subs    %x0, %x0, #1  \n"
            "bne     0b            \n"

            :
            "=r" (count)
            :
            "0" (count)
            :
            "cc", "memory",

            "x1", "x2", "x3", "x4", "x5",
            "x6", "x7", "x8", "x9", "x10",
            "x11", "x12", "x13","x14"
            );
        times[i] = (mach_absolute_time() - times[i]); //for ms
    }

    uint64_t max_time = times[0];
    for(int i = 1; i < 500; i++)
    {
        if(max_time > times[i]) {
            max_time = times[i];
        }
    }

    double used_sec = hmd_cpu_absolute_nanosecond_to_sec(max_time);
    if (used_sec != 0) {
        curFreq = 1300000 / used_sec;
    }
#else
    curFreq = 0;
#endif
    return curFreq;
}


