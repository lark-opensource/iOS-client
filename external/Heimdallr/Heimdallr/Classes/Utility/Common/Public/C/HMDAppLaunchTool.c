//
//  HMDAppLaunchTool.m
//  Heimdallr-iOS13.0
//
//  Created by zhangxiao on 2019/12/23.
//

#include "HMDAppLaunchTool.h"
#include <sys/sysctl.h>
#include <mach/mach.h>
#include <unistd.h>

bool fetchProcessInfo(int pid, struct kinfo_proc * processInfo) {
    int cmd[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
    size_t size = sizeof(*processInfo);
    return sysctl(cmd, sizeof(cmd) / sizeof(*cmd), processInfo, &size, NULL, 0) == 0;
}

double hmdTimeWithProcessExec(void) {
    struct kinfo_proc processInfo;
    int pid = getpid();
    if (fetchProcessInfo(pid, &processInfo)) {
        return processInfo.kp_proc.p_un.__p_starttime.tv_sec * 1000.0 + processInfo.kp_proc.p_un.__p_starttime.tv_usec / 1000.0;
    } else {
        return 0;
    }
}
