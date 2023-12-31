//
//  OKStartUpTask+Private.m
//  OKStartUp
//
//  Created by bob on 2020/4/24.
//

#import "OKStartUpTask+Private.h"
#import "OKStartUpScheduler+Track.h"
#import "OKUtility.h"

@implementation OKStartUpTask (Private)

- (void)_privateStartWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    if (!self.enabled) {
        return;
    }
    int64_t start = OK_CurrentMachTime();
    
    /* 执行BeforeBlock（如定义） */
    dispatch_block_t customTaskBeforeBlock = self.customTaskBeforeBlock;
    if (customTaskBeforeBlock) {
        customTaskBeforeBlock();
    }
    
    /* 执行初始化任务 */
    // 兼容老接口。若子类实现了新接口，则调用新接口。否则调用老接口。
    if ([self methodForSelector:@selector(startWithLaunchOptions:)] != [OKStartUpTask instanceMethodForSelector:@selector(startWithLaunchOptions:)]) {
        [self startWithLaunchOptions:launchOptions];
    } else {
        [self start];
    }
    
    /* 执行AfterBlock（如定义） */
    dispatch_block_t customTaskAfterBlock = self.customTaskAfterBlock;
    if (customTaskAfterBlock) {
        customTaskAfterBlock();
    }
    int64_t end = OK_CurrentMachTime();
   
    long long millisecond = OK_MachTimeToSecs(end - start) * 1000;
    [[OKStartUpScheduler sharedScheduler] trackStartupTask:self.taskIdentifier duration:millisecond];
}

@end
