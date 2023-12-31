//
//  HMDRunloopMonitor.mm
//  Heimdallr
//
//  Created by wangyinhui on 2023/4/24.
//

#import <Foundation/Foundation.h>
#import "HMDRunloopMonitor.h"
#import "pthread_extended.h"
#import "HMDTimeSepc.h"
#import "HMDApplicationSession.h"

#import <stdio.h>

//unit ms
#define MinMonitorThreadInterval 32

bool HMDRunloopMonitor::addObserver(HMDRunloopMonitorCallback callback) {
    if (callback == NULL) {
        return false;
    }
    
    bool rst = true;
    int lock_rst = pthread_mutex_lock(&this->observerLock);
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
        pthread_mutex_unlock(&this->observerLock);
    }
    
    return rst;
}

bool HMDRunloopMonitor::removeObserver(HMDRunloopMonitorCallback callback) {
    if (callback == NULL) {
        return false;
    }
    
    bool rst = false;
    int index = 0;
    int lock_rst = pthread_mutex_lock(&this->observerLock);
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
        pthread_mutex_unlock(&this->observerLock);
    }
    
    lock_rst = pthread_rwlock_wrlock(&this->runloopModeRwLock);
    if (this->runloopMode != NULL) {
        free(this->runloopMode);
        this->runloopMode = NULL;
    }
    
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&this->runloopModeRwLock);
    }
    
    
    return rst;
}


HMDRunloopMonitor::HMDRunloopMonitor(CFRunLoopRef runloop,const char *observer_name, hmd_thread tid) {
    this->observerList = NULL;
    this->observerCount = 0;
    this->info.status = HMDRunloopStatusBegin;
    this->info.runloopCount = 0;
    this->info.begin = 0;
    this->info.duration = 0;
    this->info.background = NO;
    this->info.tid = tid;
    this->runloopBeginObserver = NULL;
    this->runloopEndObserver = NULL;
    this->runloop = runloop;
    this->runloopMode = NULL;
    
    this->isRunloopRunning = false;
    this->isMonitorRunning = false;
    
    this->monitorThreadSleepInterval = 500;
    
    this->monitorQueue = dispatch_queue_create(observer_name, DISPATCH_QUEUE_SERIAL);
    
    pthread_rwlock_init(&this->runloopModeRwLock, NULL);
    pthread_mutex_init(&this->observerLock , NULL);
    
}

HMDRunloopMonitor::~HMDRunloopMonitor() {
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
    
    pthread_mutex_destroy(&this->observerLock);
    pthread_rwlock_destroy(&this->runloopModeRwLock);
}

bool HMDRunloopMonitor::start(void) {
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

void HMDRunloopMonitor::stop(void) {
    setMonitorRunning(NO);
    this->observerCount = 0;
}

void HMDRunloopMonitor::addRunLoopObserver() {
    CFRunLoopObserverContext ctx = {};
    ctx.info = this;
    if (this->runloopBeginObserver == NULL) {
        this->runloopBeginObserver = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopEntry|kCFRunLoopBeforeSources|kCFRunLoopAfterWaiting, YES, LONG_MIN, runloopBeginCallback, &ctx);
    }
    
    if (this->runloopEndObserver == NULL) {
        
        this->runloopEndObserver = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopBeforeWaiting|kCFRunLoopExit, YES, LONG_MAX, runloopEndCallback, &ctx);
    }
    
    CFRunLoopAddObserver(this->runloop, this->runloopBeginObserver, kCFRunLoopCommonModes);
    CFRunLoopAddObserver(this->runloop, this->runloopEndObserver, kCFRunLoopCommonModes);
}

void HMDRunloopMonitor::removeRunLoopObserver(void)
{
    if (this->runloopBeginObserver != NULL) {
        CFRunLoopRemoveObserver(this->runloop, this->runloopBeginObserver, kCFRunLoopCommonModes);
        CFRelease(this->runloopBeginObserver);
        this->runloopBeginObserver = NULL;
    }
    
    if (this->runloopEndObserver != NULL) {
        CFRunLoopRemoveObserver(this->runloop, this->runloopEndObserver, kCFRunLoopCommonModes);
        CFRelease(this->runloopEndObserver);
        this->runloopEndObserver = NULL;
    }
    
    int lock_rst = pthread_rwlock_wrlock(&this->runloopModeRwLock);
    if (this->runloopMode != NULL) {
        free(this->runloopMode);
        this->runloopMode = NULL;
    }
    
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&this->runloopModeRwLock);
    }
}

void HMDRunloopMonitor::runloopBeginCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    if (!info) return;
    HMDRunloopMonitor *monitor = (HMDRunloopMonitor *)info;
    switch (activity) {
        case kCFRunLoopEntry:
        {
            monitor->setRunloopRunning(YES);
            monitor->runloopCount++;
            monitor->updateRunloopMode(true);
            break;
        }
        case kCFRunLoopBeforeSources:
        {
            if (!monitor->enableMonitorCompleteRunloop) {
                monitor->runloopCount++;
            }
            break;
        }
        case kCFRunLoopAfterWaiting:
        {
            monitor->setRunloopRunning(YES);
            monitor->runloopCount++;
            break;
        }
        default:
            break;
    }
    
    monitor->updateRunloopMode(false);
}

void HMDRunloopMonitor::HMDRunloopMonitor::runloopEndCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    if (!info) return;
    HMDRunloopMonitor *monitor = (HMDRunloopMonitor *)info;
    switch (activity) {
        case kCFRunLoopBeforeWaiting:
        {
            monitor->setRunloopRunning(NO);
            break;
        }
        case kCFRunLoopExit:
        {
            monitor->setRunloopRunning(NO);
            break;
        }
        default:
            break;
    }
    
    monitor->updateRunloopMode(false);
}


void HMDRunloopMonitor::runMonitor(void) {

    NSTimeInterval smallestWaitDuration = 0;

    HMDRunloopObserver *currentObserverList = NULL;
    HMDRunloopObserver *copyObserverList = NULL;
    NSUInteger observerCount = 0;
    
    // Runloop监听循环，有监听者存在就一直循环
    while (true) {
        // 如果observerList有更新，则地址会变化
        if (currentObserverList != this->observerList) {
            int observer_lock_rst = pthread_mutex_lock(&this->observerLock);
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
                pthread_mutex_unlock(&this->observerLock);
            }
        }
        
        if (copyObserverList == NULL || observerCount == 0) {
            break;
        }
        
        this->resetInfo();
        
        // a temp sleep interval in current runloop cycle.
        uint currentRunloopMonitorSleepInterval = this->monitorThreadSleepInterval;
        
        do {
            //find the smallest WaitDuration in all observers. if current runloop status is begin, run observer's callback.
            smallestWaitDuration = this->getWaitDuration(copyObserverList, observerCount);
            
            if (smallestWaitDuration - this->info.duration > 0) {
                
                BOOL runningBeforeSleep = readRunloopRunning();
                
                //sleep for a period of time
                usleep(currentRunloopMonitorSleepInterval * 1000);
                
                this->info.duration = (HMD_XNUSystemCall_timeSince1970() - this->info.begin);
                
                //wake up to detect whether the current runloop cycle has exceeded the smallestWaitDuration
                if (readRunloopRunning() && this->info.runloopCount == readRunloopCount()) {
                    //this runloop cycle will be duration, reduce currentRunloopMonitorSleepInterval, let monitor thread wake up quickly.
                    currentRunloopMonitorSleepInterval = MAX(currentRunloopMonitorSleepInterval/2, MinMonitorThreadInterval);
                    
                    if (this->info.duration > smallestWaitDuration) {
                        //this runloop cycle has been duration.
                        this->info.status = HMDRunloopStatusDuration;
                        for (int i=0; i<observerCount; i++) {
                            HMDRunloopObserver *observer = &(copyObserverList[i]);
                            if (observer->duration >= 0 && observer->duration < (this->info.duration + kHMDMilliSecond)) {
                                observer->duration = observer->callback(&(this->info));
                                // If the next time point returned is smaller than the current duration, set it to wait 1ms.
                                if (observer->duration > 0 && observer->duration <= this->info.duration) {
                                    observer->duration = this->info.duration + kHMDMilliSecond;
                                }
                            }
                        }
                    }
                }
                
                //in sleep interval, runloop state changed, running -> sleep. now need to notice observers current runloop is over.
                if (runningBeforeSleep && !readRunloopRunning()) {
                    break;
                }
                
                //in sleep interval, runloop state changed, sleep -> running. Has entered the next runloop.
                if (!runningBeforeSleep && readRunloopRunning()) {
                    break;
                }
            } else {
                break;
            }
        } while (this->info.runloopCount == readRunloopCount());
        
        // 处理Over事件
        this->info.status = HMDRunloopStatusOver;
        
        // 回调观察者Over事件
        for (int i=0; i<observerCount; i++) {
            HMDRunloopObserver *observer = &(copyObserverList[i]);
            observer->callback(&(this->info));
        }
    }
    
    
    this->removeRunLoopObserver();
    setMonitorRunning(NO);
    if (copyObserverList != NULL) {
        delete[] copyObserverList;
        copyObserverList = NULL;
    }
}

void HMDRunloopMonitor::resetInfo(void) {
    this->info.status = HMDRunloopStatusBegin;
    this->info.runloopCount = readRunloopCount();
    this->info.begin = HMD_XNUSystemCall_timeSince1970();
    this->info.duration = 0;
    this->info.background = HMDApplicationSession_backgroundState();
}

NSTimeInterval HMDRunloopMonitor::getWaitDuration(HMDRunloopObserver *observerList, NSUInteger observerCount) {
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


bool HMDRunloopMonitor::updateRunloopMode(bool force) {
    if (!force && this->runloopMode != NULL) {
        return false;
    }
    
    CFStringRef currentModeCFString = (CFStringRef)CFRunLoopCopyCurrentMode(this->runloop);
    if (currentModeCFString == NULL) {
        return false;
    }
    
    const char *currentMode = CFStringGetCStringPtr(currentModeCFString, kCFStringEncodingMacRoman);
    CFRelease(currentModeCFString);
    if (currentMode == NULL) {
        return false;
    }
    
    char *copyMode = strdup(currentMode);
    int lock_rst = pthread_rwlock_wrlock(&this->runloopModeRwLock);
    if (this->runloopMode != NULL) {
        free(this->runloopMode);
    }
    this->runloopMode = copyMode;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&this->runloopModeRwLock);
    }
    
//    HMDPrint("[Runloop] %s mode = %s", force ? "更新":"初始化", g_runloopMode);
    return true;
}

BOOL HMDRunloopMonitor::readMonitorRunning(void) {
    return std::atomic_load_explicit(&this->isMonitorRunning, std::memory_order_acquire);
}

void HMDRunloopMonitor::setMonitorRunning(BOOL running) {
    std::atomic_store_explicit(&this->isMonitorRunning, running, std::memory_order_release);
}

BOOL HMDRunloopMonitor::readRunloopRunning(void) {
    return std::atomic_load_explicit(&this->isRunloopRunning, std::memory_order_acquire);
}

void HMDRunloopMonitor::setRunloopRunning(BOOL running) {
    std::atomic_store_explicit(&this->isRunloopRunning, running, std::memory_order_release);
}

NSUInteger HMDRunloopMonitor::readRunloopCount(void) {
    return std::atomic_load_explicit(&this->runloopCount, std::memory_order_acquire);
}

void HMDRunloopMonitor::setRunloopCount(NSUInteger runloopCount) {
    std::atomic_store_explicit(&this->runloopCount, runloopCount, std::memory_order_release);
}

void HMDRunloopMonitor::updateMonitorThreadSleepInterval(uint interval) {
    //The current sleep interval is smaller than the value you want to set. Ignore this update.
    if (this->monitorThreadSleepInterval < interval) {
        return;
    }
    //Waking up too frequently is a performance problem, the minimum interval is 32 ms.
    this->monitorThreadSleepInterval = MAX(MinMonitorThreadInterval, interval);
}

void HMDRunloopMonitor::updateEnableMonitorCompleteRunloop(BOOL enable) {
    this->enableMonitorCompleteRunloop = enable;
}


