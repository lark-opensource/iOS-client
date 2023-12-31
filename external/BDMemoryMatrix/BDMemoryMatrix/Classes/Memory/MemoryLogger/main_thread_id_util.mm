//
//  MMMainThreadIDUtil.m
//  BDMemoryMatrix
//
//  Created by zhouyang11 on 2022/11/28.
//

#import "main_thread_id_util.h"
#import <pthread/pthread.h>

mach_port_t mm_main_thread_id_sync(void) {
    static mach_port_t main_thread_id = 0;
    if (main_thread_id != 0) {
        return main_thread_id;
    }
    if (pthread_main_np() != 0) {
        main_thread_id = pthread_mach_thread_np(pthread_self());
    }else {
        static dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_main_queue(), ^{
            main_thread_id = pthread_mach_thread_np(pthread_self());
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    return main_thread_id;
}
