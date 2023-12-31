//
//  HMDRunloopMonitor.h
//  Pods
//
//  Created by wangyinhui on 2023/4/24.
//
#import <atomic>
#import <stdio.h>
#include <pthread.h>
#import <CoreFoundation/CoreFoundation.h>

#import "hmd_runloop_define.h"
#import "HMDAsyncThread.h"


#ifndef HMDRunloopMonitor_h
#define HMDRunloopMonitor_h

extern const NSTimeInterval kHMDMinRunloopInterval;
extern const NSTimeInterval kHMDMilliSecond;
extern const NSTimeInterval kHMDMicroSecond;


/**
 * Runloop监听信息
 */
struct HMDRunloopMonitorInfo {
    HMDRunloopStatus status;
    NSUInteger runloopCount; // Runloop计数器，区别不同Runloop循环，初始值为0
    NSTimeInterval begin; // Runloop开始时间戳
    NSTimeInterval duration; // Runloop持续时长
    BOOL background; // 后台状态
    hmd_thread tid; // runloop thread id
    CFRunLoopActivity runloopActivity; // 当前的runloopActivity
};

/**
 * Runloop监听回调，返回下次等待的duraion（duration表示从Runloop开始持续时间），返回 < 0表示等待直至Runloop结束
 */
typedef NSTimeInterval (*HMDRunloopMonitorCallback)(struct HMDRunloopMonitorInfo * _Nonnull info);

/**
 * RunloopObserver抽象
 */
struct HMDRunloopObserver {
    NSTimeInterval duration;
    HMDRunloopMonitorCallback _Nullable callback;
};

/**
 * RunloopMonitor监控
 */
class HMDRunloopMonitor {
    
public:
    
    bool addObserver(HMDRunloopMonitorCallback _Nonnull callback);
    bool removeObserver(HMDRunloopMonitorCallback _Nonnull callback);
    HMDRunloopMonitor(CFRunLoopRef _Nullable runloop, const char * _Nullable observer_name, hmd_thread tid);
    ~HMDRunloopMonitor();
    bool start(void);
    void stop(void);
    
    
    std::atomic<NSUInteger> runloopCount;
    
    BOOL readRunloopRunning(void);
    void setRunloopRunning(BOOL running);
    
    //unit: ms
    void updateMonitorThreadSleepInterval(uint interval);
    
    void updateEnableMonitorCompleteRunloop(BOOL enable);
    
    
protected:
    // variable
    HMDRunloopObserver * _Nullable observerList;
    NSUInteger observerCount;
    pthread_mutex_t observerLock;
    
    struct HMDRunloopMonitorInfo info;
    
    dispatch_queue_t _Nullable monitorQueue;
    
    CFRunLoopObserverRef _Nullable runloopBeginObserver;
    CFRunLoopObserverRef _Nullable runloopEndObserver;
    
    char * _Nullable runloopMode;
    pthread_rwlock_t runloopModeRwLock;
    
    /* Runloop */
    std::atomic<BOOL> isMonitorRunning;
    
    std::atomic<BOOL> isRunloopRunning;
    
    CFRunLoopRef _Nonnull runloop;
    
    std::atomic<uint> monitorThreadSleepInterval;
    
    std::atomic<BOOL> enableMonitorCompleteRunloop;
    
    
    // function
    void addRunLoopObserver(void);
    void runMonitor(void);
    void removeRunLoopObserver(void);
    void resetInfo(void);
    void waitForRunloopRunning(void);
    void waitRunloopOver(void);
    NSTimeInterval getWaitDuration(HMDRunloopObserver * _Nullable observerList, NSUInteger observerCount);
    
    BOOL readMonitorRunning(void);
    void setMonitorRunning(BOOL running);

    NSUInteger readRunloopCount(void);
    void setRunloopCount(NSUInteger runloopCount);
    
    bool updateRunloopMode(bool force);
    
    static void runloopBeginCallback(CFRunLoopObserverRef _Nullable observer, CFRunLoopActivity activity, void * _Nullable info);
    static void runloopEndCallback(CFRunLoopObserverRef _Nullable observer, CFRunLoopActivity activity, void * _Nullable info);
};



#endif /* HMDRunloopMonitor_h */
