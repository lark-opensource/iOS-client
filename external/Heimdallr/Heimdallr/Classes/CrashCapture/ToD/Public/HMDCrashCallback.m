//
//  HMDCrashCustomCallback.m
//  Pods
//
//  Created by bytedance on 2020/8/20.
//

#import "HMDCrashCallback.h"

@implementation HMDCrashCallback

+ (void)registerCallback:(hmd_crash_dynamic_data_callback)callback
{
    hmd_crash_extra_dynamic_data_add_callback(callback);
}

+ (void)removeCallback:(hmd_crash_dynamic_data_callback)callback
{
    hmd_crash_extra_dynamic_data_remove_callback(callback);
}

@end
