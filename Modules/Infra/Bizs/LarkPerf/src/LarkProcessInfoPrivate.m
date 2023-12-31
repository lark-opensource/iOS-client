//
//  LarkProcessInfoPrivate.m
//  LarkPerf
//
//  Created by KT on 2020/6/23.
//

#import "LarkProcessInfoPrivate.h"
#import <sys/sysctl.h>
#import <mach/mach.h>
#import <objc/runtime.h>
#include <sys/resource.h>
#if !TARGET_IPHONE_SIMULATOR
#include <sys/utsname.h>
#endif
#import <LKLoadable/LKLoadableManager.h>

@implementation LarkProcessInfoPrivate

+ (BOOL)processInfoForPID:(int)pid procInfo:(struct kinfo_proc*)procInfo
{
    int cmd[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
    size_t size = sizeof(*procInfo);
    return sysctl(cmd, sizeof(cmd)/sizeof(*cmd), procInfo, &size, NULL, 0) == 0;
}

+ (CFTimeInterval)getWillFinishLaunchTime {
    return [LKLoadableManager getWillFinishLaunchingTime];
}

/**
 进程创建时间
 为时间戳：timeIntervalSince1970
 进度为ms
 Xcode Run统计不准，因为Xcode Run进程创建的时间包含安装App的时间
 */
+ (NSTimeInterval)processStartTime
{
    struct kinfo_proc kProcInfo;
    if ([self processInfoForPID:[[NSProcessInfo processInfo] processIdentifier] procInfo:&kProcInfo]) {
        return kProcInfo.kp_proc.p_un.__p_starttime.tv_sec * 1000.0 + kProcInfo.kp_proc.p_un.__p_starttime.tv_usec / 1000.0;
    } else {
        NSAssert(NO, @"无法取得进程的信息");
        return 0;
    }
}

///通过ActivePrewarm字段检查是否是prewark
+ (BOOL)checkPreWarm {
    static BOOL isPreWarm = false;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 15.0, *)) {
            id activePrewarmVal = [[[NSProcessInfo processInfo] environment] objectForKey:@"ActivePrewarm"];
            if (activePrewarmVal && [activePrewarmVal respondsToSelector:@selector(boolValue)]) {
                if ([activePrewarmVal boolValue] == true) {
                    isPreWarm = true;
                }
            }
        }
    });
    return isPreWarm;
}

/// 判断是否是warm启动，可能会存在误差，试用
+ (int)isWarmLaunch {
    static int isWarmLaunch = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ((double)[self getHardPageFault] / (double)[self getSoftPageFault] < 0.2) {
            isWarmLaunch = 1;
        }
    });
    return isWarmLaunch;
}

+ (long)getHardPageFault {
    static long pageFaults = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct rusage usage;
        getrusage(RUSAGE_SELF, &usage);
        pageFaults = usage.ru_majflt;
    });
    
    return pageFaults;
}

+ (long)getSoftPageFault {
    static long pageFaults = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct rusage usage;
        getrusage(RUSAGE_SELF, &usage);
        pageFaults = usage.ru_minflt;
    });
    return pageFaults;
}

@end
