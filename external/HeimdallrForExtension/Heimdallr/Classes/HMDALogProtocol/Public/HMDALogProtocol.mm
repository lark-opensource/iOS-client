//
//  HMDALogProtocol.m
//  Pods
//
//  Created by bytedance on 2020/5/28.
//

#include "HMDALogProtocol.h"

#if !HMD_DISABLE_ALOG && __has_include("BDAlogProtocol/BDAlogProtocol.h")
bool hmd_log_enable(void) {
    return true;
}
#else
bool hmd_log_enable(void) {
    return false;
}
#endif
