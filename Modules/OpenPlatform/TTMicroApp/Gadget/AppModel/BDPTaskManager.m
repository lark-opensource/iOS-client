//
//  BDPTaskManager.m
//  Timor
//
//  Created by 王浩宇 on 2019/5/23.
//

#import "BDPTaskManager.h"
#import <OPFoundation/BDPTracingManager.h>
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPSDK/OPSDK-Swift.h>

@interface BDPTaskManager ()

@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, strong) NSMapTable <BDPUniqueID *, BDPTask *> *tasks;

@end

@implementation BDPTaskManager

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
+ (instancetype)sharedManager
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDPTaskManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _tasks = [[NSMapTable alloc] initWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableStrongMemory capacity:5];
        _lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

// 外部调用方避免多线程问题
- (void)addTask:(BDPTask *)task uniqueID:(BDPUniqueID *)uniqueID
{
    if (task && uniqueID) {
        // 将task添加到Manager中，表示task进入预期持有状态
        [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedRetain for:task];
        [_lock lock];
        [self.tasks setObject:task forKey:uniqueID];
        [_lock unlock];
    }
}

- (void)removeTaskWithUniqueID:(BDPUniqueID *)uniqueID
{
    if (uniqueID) {
        [_lock lock];
        BDPTask * task = [self.tasks objectForKey:uniqueID];
        // 在此处将BDPTask的状态置为预期销毁
        if (task) {
            [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedDestroy for:task];
        }
        [self.tasks removeObjectForKey:uniqueID];
        [_lock unlock];
        [BDPTracingManager.sharedInstance clearTracingByUniqueID:uniqueID]; // 清理Tracing
    }
}

- (BDPTask *)getTaskWithUniqueID:(BDPUniqueID *)uniqueID
{
    if (uniqueID) {
        BDPTask *ret = nil;
        [_lock lock];
        ret = [self.tasks objectForKey:uniqueID];
        [_lock unlock];
        return ret;
    }
    return nil;
}

@end
