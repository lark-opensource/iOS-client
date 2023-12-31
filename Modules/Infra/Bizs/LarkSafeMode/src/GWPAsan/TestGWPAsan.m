//
//  TestGWPAsan.m
//  LarkSafeMode
//
//  Created by luyz on 2022/6/16.
//

#import "TestGWPAsan.h"
#import <pthread/pthread.h>

@implementation TestGWPAsan

/** 主线程优先级调整
+ (void)load {
    pthread_t selfThread = pthread_self();
    int policy = 0;
    struct sched_param param;
    int getParamRes = pthread_getschedparam(selfThread, &policy, &param);
    if (getParamRes == 0) {
        param.sched_priority = 63;
        int setParamRes = pthread_setschedparam(selfThread, policy, &param);
        if (setParamRes == 0) {
            NSLog(@"=== xsq === update priority success");
        }
    }
}
 */

+ (void)testGWPAsanCrash {
    for (int i = 0; i < 200000; i++) {
        int *p = malloc(10);
        int q = p[17];
        if (q % 1000 == 0) {
            i++;
        }
        if (p < 0x0000000130000000) {
            free(p);
        }
        free(p);
    }
}

@end
