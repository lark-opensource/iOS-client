//
//  HMDMainRunloopMonitor.hpp
//  Heimdallr
//
//  Created by 白昆仑 on 2019/9/3.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <stdio.h>

#import "hmd_runloop_define.h"
#import "HMDRunloopMonitor.h"

#ifndef HMDMainRunloopMonitor_hpp
#define HMDMainRunloopMonitor_hpp

/**
 * RunloopMonitor监控
 */
class HMDMainRunloopMonitor {
    
public:
    
    // function
    static HMDMainRunloopMonitor* _Nonnull getInstance(void) {
        static HMDMainRunloopMonitor *instance;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = new HMDMainRunloopMonitor();
        });
        return instance;
    }
    
    bool addObserver(HMDRunloopMonitorCallback _Nonnull callback);
    bool removeObserver(HMDRunloopMonitorCallback _Nonnull callback);
    bool isUITrackingRunloopMode(void);
    struct HMDRunloopMonitorInfo info;
    
    void updateEnableMonitorCompleteRunloop(BOOL enable);
    
private:
    // variable
    HMDRunloopObserver * _Nullable observerList;
    NSUInteger observerCount;
    dispatch_queue_t _Nullable monitorQueue;
    CFRunLoopObserverRef _Nullable runloopBeginObserver;
    CFRunLoopObserverRef _Nullable runloopEndObserver;
    
    // function
    HMDMainRunloopMonitor();
    ~HMDMainRunloopMonitor();
    bool start(void);
    void addRunLoopObserver(void);
    void runMonitor(void);
    void removeRunLoopObserver(void);
    void resetInfo(void);
    void waitForRunloopRunning(void);
    void waitRunloopOver(void);
    NSTimeInterval getWaitDuration(HMDRunloopObserver * _Nullable observerList, NSUInteger observerCount);
};

#endif /* HMDMainRunloopMonitor_hpp */
