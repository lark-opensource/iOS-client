//
//  HMDProtect_Private.m
//  Heimdallr-iOS8.0
//
//  Created by 白昆仑 on 2020/2/21.
//

#import "HMDProtect_Private.h"
#import "HMDProtector.h"
#import "hmd_try_catch_detector.h"

BOOL HMDProtectTestEnvironment = NO;

extern BOOL HMDProtectIgnoreTryCatch;

bool HMD_NO_OPT_ATTRIBUTE hmd_upper_trycatch_effective(unsigned int ignore_depth) {
    if (HMDProtectIgnoreTryCatch && hmd_check_in_try_catch(ignore_depth+1)) {
        return true;
    }
    
    return false;
}

// 检查当前线程的私有数据中，key是否为flag状态
bool hmd_check_thread_specific_flag(pthread_key_t key) {
    return (pthread_getspecific(key) != NULL);
}

// 标记当前线程某一key为flag状态
void hmd_thread_specific_set_flag(pthread_key_t key) {
    pthread_setspecific(key, (void *)1);
}

// 清除当前线程某一key的flag状态
void hmd_thread_specific_clear_flag(pthread_key_t key) {
    pthread_setspecific(key, NULL);
}
