//
//  HMDMainRunloopMonitor.cpp
//  Heimdallr
//
//  Created by 白昆仑 on 2019/9/3.
//

#import <CoreFoundation/CFRunLoop.h>
#import <atomic>
#import "NSString+HDMUtility.h"

#import "HMDMainRunloopMonitor.h"
#import "HMDTimeSepc.h"
#import "HMDApplicationSession.h"
#import "HMDSessionTracker.h"
#import "HMDSwizzle.h"
#import "HMDMacro.h"

#import "pthread_extended.h"



/* Lock */
static pthread_cond_t g_condition = PTHREAD_COND_INITIALIZER;
static pthread_mutex_t g_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t g_observer_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_rwlock_t g_runloop_mode_rwLock = PTHREAD_RWLOCK_INITIALIZER;

/* Runloop */
static std::atomic<BOOL> g_bMonitorRunning(NO);
static std::atomic<BOOL> g_bRunloopRunning(NO);
static std::atomic<NSUInteger>g_runloopCount(0);
static char *g_runloopMode = NULL;
static const char *g_UITrackingRunloopMode = NULL;
static std::atomic<BOOL> g_enableMonitorCompleteRunloop(NO);

/* Time */
const NSTimeInterval kHMDMinRunloopInterval = 0.01; // 10ms
const NSTimeInterval kHMDMilliSecond = 0.001; // 1ms
const NSTimeInterval kHMDMicroSecond = 0.000001; // 1us

static void runloopBeginCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info);
static void runloopEndCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info);
static BOOL readMonitorRunning(void) {
    return std::atomic_load_explicit(&g_bMonitorRunning, std::memory_order_acquire);
}

static void setMonitorRunning(BOOL running) {
    std::atomic_store_explicit(&g_bMonitorRunning, running, std::memory_order_release);
}

static BOOL readRunloopRunning(void) {
    return std::atomic_load_explicit(&g_bRunloopRunning, std::memory_order_acquire);
}

static void setRunloopRunning(BOOL running) {
    std::atomic_store_explicit(&g_bRunloopRunning, running, std::memory_order_release);
}

static NSUInteger readRunloopCount(void) {
    return std::atomic_load_explicit(&g_runloopCount, std::memory_order_acquire);
}

static void setRunloopCount(NSUInteger runloopCount) {
    std::atomic_store_explicit(&g_runloopCount, runloopCount, std::memory_order_release);
}

#pragma mark - UIWindowScreen

@implementation UIWindowScene(HMDMainRunlooopMonitor)

- (void)HMDMainRunloopPrepareForSuspend {
    setRunloopRunning(NO);
    pthread_cond_signal(&g_condition);
    
    [self HMDMainRunloopPrepareForSuspend]; // Prepare期间认为是休眠状态
    
    setRunloopRunning(YES);
    g_runloopCount++;
    pthread_cond_signal(&g_condition);
}

@end

#pragma mark - HMDMainRunloopObserverManager

#pragma mark - Public

bool HMDMainRunloopMonitor::addObserver(HMDRunloopMonitorCallback callback) {
    if (callback == NULL) {
        return false;
    }
    
    bool rst = true;
    int lock_rst = pthread_mutex_lock(&g_observer_mutex);
    for (int i=0; i<this->observerCount; i++) {
        HMDRunloopObserver *observer = &(this->observerList[i]);
        if (observer->callback == callback) { // 相同的callback
            rst = false;
            break;
        }
    }
    
    if (rst) {
        HMDPrint("[Runloop] addObserver [%lu]%p", (unsigned long)(this->observerCount+1), callback);
        HMDRunloopObserver *newObserverList = new HMDRunloopObserver[this->observerCount+1];
        if (this->observerList != NULL) {
            memcpy(newObserverList, this->observerList, sizeof(HMDRunloopObserver)*this->observerCount);
            delete[] this->observerList;
            this->observerList = NULL;
        }
        
        newObserverList[this->observerCount] = HMDRunloopObserver{
            .duration = 0,
            .callback = callback,
        };
        this->observerList = newObserverList;
        this->observerCount++;
        this->start();
    }
    
    if (lock_rst == 0) {
        pthread_mutex_unlock(&g_observer_mutex);
    }
    
    return rst;
}

bool HMDMainRunloopMonitor::removeObserver(HMDRunloopMonitorCallback callback) {
    if (callback == NULL) {
        return false;
    }
    
    bool rst = false;
    int index = 0;
    int lock_rst = pthread_mutex_lock(&g_observer_mutex);
    for (int i=0; i<this->observerCount; i++) {
        HMDRunloopObserver *observer = &(this->observerList[i]);
        if (observer->callback == callback) { // 相同的callback
            rst = true;
            index = i;
            break;
        }
    }
    
    if (rst) {
        HMDPrint("[Runloop] removeObserver [%lu]%p", (unsigned long)(this->observerCount-1), callback);
        if (this->observerCount == 1) {
            this->observerCount = 0;
            if (this->observerList != NULL) {
                delete[] this->observerList;
                this->observerList = NULL;
            }
        }
        else {
            HMDRunloopObserver *newObserverList = new HMDRunloopObserver[this->observerCount-1];
            memcpy(newObserverList, this->observerList, sizeof(HMDRunloopObserver)*(index));
            memcpy(&(newObserverList[index]), &(this->observerList[index+1]), sizeof(HMDRunloopObserver)*(this->observerCount-index-1));
            delete[] this->observerList;
            this->observerList = newObserverList;
            this->observerCount--;
        }
    }
    
    if (lock_rst == 0) {
        pthread_mutex_unlock(&g_observer_mutex);
    }
    
    lock_rst = pthread_rwlock_wrlock(&g_runloop_mode_rwLock);
    if (g_runloopMode != NULL) {
        free(g_runloopMode);
        g_runloopMode = NULL;
    }
    
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_runloop_mode_rwLock);
    }
    
    
    return rst;
}

bool HMDMainRunloopMonitor::isUITrackingRunloopMode() {
    bool rst = false;
    int lock_rst = pthread_rwlock_rdlock(&g_runloop_mode_rwLock);
    if (g_runloopMode != NULL && g_UITrackingRunloopMode != NULL && (strcmp(g_runloopMode, g_UITrackingRunloopMode) == 0)) {
        rst = true;
    }
    
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_runloop_mode_rwLock);
    }
    
    return rst;
}

#pragma mark - Private

HMDMainRunloopMonitor::HMDMainRunloopMonitor() {
    this->observerList = NULL;
    this->observerCount = 0;
    this->info.status = HMDRunloopStatusBegin;
    this->info.runloopCount = 0;
    this->info.begin = 0;
    this->info.duration = 0;
    this->info.background = NO;
    this->runloopBeginObserver = NULL;
    this->runloopEndObserver = NULL;
    g_UITrackingRunloopMode = UITrackingRunLoopMode.UTF8String;
    this->monitorQueue = dispatch_queue_create("com.heimdallr.runloop.observer", DISPATCH_QUEUE_SERIAL);
    
    if (@available(iOS 13.0, *)) {
        /* -(void)_prepareForSuspend; */
        SEL windowSceneOriginSel = NSSelectorFromString(@"_prepareForSuspend");
        hmd_swizzle_instance_method([UIWindowScene class], windowSceneOriginSel, @selector(HMDMainRunloopPrepareForSuspend));
    }
}

HMDMainRunloopMonitor::~HMDMainRunloopMonitor() {
    if (this->observerList != NULL) {
        delete[] this->observerList;
        this->observerList = NULL;
    }
    
    if (this->runloopBeginObserver != NULL) {
        CFRelease(this->runloopBeginObserver);
    }
    
    if (this->runloopEndObserver != NULL) {
        CFRelease(this->runloopEndObserver);
    }
}

bool HMDMainRunloopMonitor::start(void) {
    if (readMonitorRunning() || this->observerCount == 0) {
        return false;
    }
    
    setMonitorRunning(YES);
    setRunloopRunning(YES);
    setRunloopCount(0);
    this->addRunLoopObserver();
    dispatch_async(this->monitorQueue, ^{
        this->runMonitor();
    });
    
    return true;
}

void HMDMainRunloopMonitor::addRunLoopObserver(void)
{
    CFRunLoopObserverContext ctx = {};
    ctx.info = this;
    
    CFRunLoopRef mainRunloop = CFRunLoopGetMain();
    if (this->runloopBeginObserver == NULL) {
        this->runloopBeginObserver = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopEntry|kCFRunLoopBeforeSources|kCFRunLoopAfterWaiting, YES, LONG_MIN, runloopBeginCallback, &ctx);
    }
    
    if (this->runloopEndObserver == NULL) {
        this->runloopEndObserver = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopBeforeWaiting|kCFRunLoopExit, YES, LONG_MAX, runloopEndCallback, &ctx);
    }
    
    CFRunLoopAddObserver(mainRunloop, this->runloopBeginObserver, kCFRunLoopCommonModes);
    CFRunLoopAddObserver(mainRunloop, this->runloopEndObserver, kCFRunLoopCommonModes);
}

void HMDMainRunloopMonitor::removeRunLoopObserver(void)
{
    CFRunLoopRef mainRunloop = CFRunLoopGetMain();
    if (this->runloopBeginObserver != NULL) {
        CFRunLoopRemoveObserver(mainRunloop, this->runloopBeginObserver, kCFRunLoopCommonModes);
        CFRelease(this->runloopBeginObserver);
        this->runloopBeginObserver = NULL;
    }
    
    if (this->runloopEndObserver != NULL) {
        CFRunLoopRemoveObserver(mainRunloop, this->runloopEndObserver, kCFRunLoopCommonModes);
        CFRelease(this->runloopEndObserver);
        this->runloopEndObserver = NULL;
    }
    
    int lock_rst = pthread_rwlock_wrlock(&g_runloop_mode_rwLock);
    if (g_runloopMode != NULL) {
        free(g_runloopMode);
        g_runloopMode = NULL;
    }
    
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_runloop_mode_rwLock);
    }
}

// Runloop Mode 初始化
static bool updateRunloopMode(bool force) {
    if (!force && g_runloopMode != NULL) {
        return false;
    }
    
    CFRunLoopRef mainRunloop = CFRunLoopGetMain();
    CFStringRef currentModeCFString = (CFStringRef)CFRunLoopCopyCurrentMode(mainRunloop);
    if (currentModeCFString == NULL) {
        return false;
    }
    
    const char *currentMode = CFStringGetCStringPtr(currentModeCFString, kCFStringEncodingMacRoman);
    CFRelease(currentModeCFString);
    if (currentMode == NULL) {
        return false;
    }
    
    char *copyMode = strdup(currentMode);
    int lock_rst = pthread_rwlock_wrlock(&g_runloop_mode_rwLock);
    if (g_runloopMode != NULL) {
        free(g_runloopMode);
    }
    g_runloopMode = copyMode;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_runloop_mode_rwLock);
    }
    
//    HMDPrint("[Runloop] %s mode = %s", force ? "更新":"初始化", g_runloopMode);
    return true;
}

static void runloopBeginCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
//    DEBUG_C_LOG("[Runloop][%lu] %lu", (unsigned long)readRunloopCount(), activity);
    HMDMainRunloopMonitor *monitor = (HMDMainRunloopMonitor*)info;
    monitor->info.runloopActivity = activity;
    switch (activity) {
        case kCFRunLoopEntry:
        {
            setRunloopRunning(YES);
            g_runloopCount++;
            updateRunloopMode(true);
            pthread_cond_signal(&g_condition);
            break;
        }
        case kCFRunLoopBeforeSources:
        {
            if (!g_enableMonitorCompleteRunloop) {
                g_runloopCount++;
                pthread_cond_signal(&g_condition);
            }
            break;
        }
        case kCFRunLoopAfterWaiting:
        {
            setRunloopRunning(YES);
            g_runloopCount++;
            pthread_cond_signal(&g_condition);
            break;
        }
        default:
            break;
    }
    
    updateRunloopMode(false);
}

static void runloopEndCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
//    DEBUG_C_LOG("[Runloop][%lu] %lu", (unsigned long)readRunloopCount(), activity);
    HMDMainRunloopMonitor *monitor = (HMDMainRunloopMonitor*)info;
    monitor->info.runloopActivity = activity;
    switch (activity) {
        case kCFRunLoopBeforeWaiting:
        {
            setRunloopRunning(NO);
            pthread_cond_signal(&g_condition);
            break;
        }
        case kCFRunLoopExit:
        {
            setRunloopRunning(NO);
            pthread_cond_signal(&g_condition);
            break;
        }
        default:
            break;
    }
    
    updateRunloopMode(false);
}

void HMDMainRunloopMonitor::runMonitor(void) {
    int lock_rst = pthread_mutex_lock(&g_mutex);
    NSTimeInterval tsBeforeWaiting = 0;
    NSTimeInterval tsInterval = 0;
    NSTimeInterval waitDuration = 0;
    NSTimeInterval waitInterval = 0;
    struct timespec waitTimespec = {0};
    HMDRunloopObserver *currentObserverList = NULL;
    HMDRunloopObserver *copyObserverList = NULL;
    NSUInteger observerCount = 0;
    
    // Runloop监听循环，有监听者存在就一直循环
    while (true) {
        // 如果observerList有更新，则地址会变化
        if (currentObserverList != this->observerList) {
            int observer_lock_rst = pthread_mutex_lock(&g_observer_mutex);
            if (copyObserverList != NULL) {
                delete[] copyObserverList;
                copyObserverList = NULL;
            }
            
            currentObserverList = this->observerList;
            observerCount = this->observerCount;
            if (observerCount > 0) {
                copyObserverList = new HMDRunloopObserver[observerCount];
                memcpy(copyObserverList, this->observerList, sizeof(HMDRunloopObserver)*observerCount);
            }
            
            if (observer_lock_rst == 0) {
                pthread_mutex_unlock(&g_observer_mutex);
            }
        }
        
        if (copyObserverList == NULL || observerCount == 0) {
            break;
        }
        
        this->resetInfo();
        this->waitForRunloopRunning();
        // 单个Runloop监听循环
        while (readRunloopRunning() && this->info.runloopCount == readRunloopCount()) {
            waitDuration = this->getWaitDuration(copyObserverList, observerCount);
            waitInterval = waitDuration - this->info.duration;
            // 信号等待
            if (waitInterval > 0 && readRunloopRunning()) {
                tsBeforeWaiting = HMD_XNUSystemCall_timeSince1970();
                HMD_timespec_from_interval(&waitTimespec, tsBeforeWaiting + waitInterval);
                if( pthread_cond_timedwait(&g_condition, &g_mutex, &waitTimespec) == 0 ) {
                    tsInterval = HMD_XNUSystemCall_timeSince1970() - tsBeforeWaiting;
                    if (tsInterval > 0) {
                        this->info.duration += MIN(tsInterval, waitInterval);
                    }
                    else {
                        this->info.duration += waitInterval;
                    }
                    
                    break;
                }
                else {
                    this->info.duration += waitInterval;
                    if (!readRunloopRunning()) {
                        break;
                    }
                    
                    this->info.status = HMDRunloopStatusDuration;
                    for (int i=0; i<observerCount; i++) {
                        HMDRunloopObserver *observer = &(copyObserverList[i]);
                        if (observer->duration >= 0 && observer->duration < (this->info.duration + kHMDMilliSecond)) {
                            observer->duration = observer->callback(&(this->info));
                            // 如果返回的下一个时间点比当前的还小，则将其设置为需要等待1ms
                            if (observer->duration > 0 && observer->duration <= this->info.duration) {
                                observer->duration = this->info.duration + kHMDMilliSecond;
                            }
                        }
                    }
                }
            }
            else {
                break;
            }
        }
        
        // 处理Over事件
        this->info.status = HMDRunloopStatusOver;
        this->waitRunloopOver();
        
        // 回调观察者Over事件
        for (int i=0; i<observerCount; i++) {
            HMDRunloopObserver *observer = &(copyObserverList[i]);
            observer->callback(&(this->info));
        }
    }
    
    if (lock_rst == 0) {
        pthread_mutex_unlock(&g_mutex);
    }
    
    this->removeRunLoopObserver();
    setMonitorRunning(NO);
    if (copyObserverList != NULL) {
        delete[] copyObserverList;
        copyObserverList = NULL;
    }
}

void HMDMainRunloopMonitor::resetInfo(void) {
    this->info.status = HMDRunloopStatusBegin;
    this->info.runloopCount = readRunloopCount();
    this->info.begin = HMD_XNUSystemCall_timeSince1970();
    this->info.duration = 0;
    this->info.background = HMDApplicationSession_backgroundState();
}

void HMDMainRunloopMonitor::waitRunloopOver(void) {
    NSTimeInterval waitInterval = 1;
    NSTimeInterval tsInterval = 0;
    NSTimeInterval tsBeforeWaiting = 0;
    struct timespec time = {0};
    while (readRunloopRunning() && this->info.runloopCount == readRunloopCount()) {
        tsBeforeWaiting = HMD_XNUSystemCall_timeSince1970();
        HMD_timespec_from_interval(&time, tsBeforeWaiting + waitInterval);
        if (pthread_cond_timedwait(&g_condition, &g_mutex, &time) == 0) {
            tsInterval = HMD_XNUSystemCall_timeSince1970() - tsBeforeWaiting;
            if (tsInterval > 0) {
                this->info.duration += MIN(tsInterval, waitInterval);
            }
            // 系统时间被修改
            else {
                this->info.duration += waitInterval;
            }
        }
        else {
            this->info.duration += waitInterval;
        }
    }
    
    // 补偿计时误差
    tsInterval = HMD_XNUSystemCall_timeSince1970() - info.begin;
    if (tsInterval > this->info.duration && (tsInterval - this->info.duration) < 1.0) {
        this->info.duration = tsInterval;
    }
}

void HMDMainRunloopMonitor::waitForRunloopRunning(void) {
    struct timespec time = {0};
    HMD_timespec_getCurrent(&time);
    while (!readRunloopRunning()) {
        time.tv_sec += 1;
        pthread_cond_timedwait(&g_condition, &g_mutex, &time);
    }
}

NSTimeInterval HMDMainRunloopMonitor::getWaitDuration(HMDRunloopObserver *observerList, NSUInteger observerCount) {
    NSTimeInterval waitDuration = -1.0;
    if (observerList == NULL) {
        return waitDuration;
    }
    
    for (int i=0; i<observerCount; i++) {
        HMDRunloopObserver *observer = &(observerList[i]);
        if (this->info.status == HMDRunloopStatusBegin) {
            observer->duration = observer->callback(&(this->info));
            // 当前duration已经超过要等待的时间，则将等待时间调整为duration时间
            if (observer->duration > 0 && observer->duration < this->info.duration) {
                observer->duration = this->info.duration;
            }
        }
        
        if (waitDuration < 0) {
            waitDuration = observer->duration;
        }
        else if (observer->duration >= 0 &&observer->duration < waitDuration) {
            waitDuration = observer->duration;
        }
    }
    
    return waitDuration;
}

void HMDMainRunloopMonitor::updateEnableMonitorCompleteRunloop(BOOL enable) {
    g_enableMonitorCompleteRunloop = enable;
}
