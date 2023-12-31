//
//  HMDEMCollectTraceData.cpp
//  AWECloudCommand
//
//  Created by maniackk on 2021/5/31.
//

#include "HMDEMCollectTraceData.h"
#include "HMDEMMacro.h"
#include "HeimdallrUtilities.h"
#include "HMDEMCollectData.h"
#include <vector>
#include <mach/mach_host.h>
#include <mach/mach_time.h>
#include <mach/thread_act.h>
#include <pthread/pthread.h>

BOOL heimdallrEvilMethodEnabled = NO;
static std::vector<EMFuncMeta *> *dataVec = NULL;
static CFRunLoopObserverRef runLoopObserver;
static u_int64_t *currentNum = NULL;
static NSTimeInterval const kHMDEMTTimeoutIntervalMin = 0.5; // min timeoutInterval 500ms
static BOOL kHMDFilterEvilMethod = YES;
static integer_t kHMDEMTTimeoutInterval = 1000000; // default timeoutInterval 1000ms
static NSInteger kHMDEMFilterMicrosecond = 1000; //default 1000
static EMFuncMeta *lastFuncMeta = NULL;

BOOL kHMDEMCollectFrameDrop = NO;
BOOL kHMDEvilMethodinstrumentationSuccess = NO;
static NSTimeInterval kHMDEMCollectFrameDropThreshold = 500;

void setEMFilterMillisecond(NSInteger millisecond) {
    if (millisecond >= 1) {
        kHMDEMFilterMicrosecond = millisecond * 1000;
    }
}

void setEMTTimeoutInterval(NSTimeInterval time) {
    kHMDEMTTimeoutInterval = (time < kHMDEMTTimeoutIntervalMin ? kHMDEMTTimeoutIntervalMin : time) * 1000000;
}

void setEMFilterEvilMethod(BOOL filterEvilMethod) {
    kHMDFilterEvilMethod = filterEvilMethod;
}

void setEMCollectFrameDrop(BOOL collect) {
    kHMDEMCollectFrameDrop = collect;
}

void setEMCollectFrameDropThreshold(NSTimeInterval threshold) {
    kHMDEMCollectFrameDropThreshold = threshold;
}

static time_value_t cur_wall_time_v1(void) {
    /*
    ** Monotonic timer on Mac OS is provided by mach_absolute_time(), which
    ** returns time in Mach "absolute time units," which are platform-dependent.
    ** To convert to nanoseconds, one must use conversion factors specified by
    ** mach_timebase_info().
    */
    static mach_timebase_info_data_t timebase;
    if (0 == timebase.denom) {
        mach_timebase_info(&timebase);
    }

    uint64_t usecs = mach_absolute_time();
    usecs *= timebase.numer;
    usecs /= timebase.denom;
    usecs /= 1000;

    time_value_t tnow = {0, 0};
    tnow.seconds = (int)(usecs / 1000000);
    tnow.microseconds = (int)(usecs % 1000000);

    return tnow;
}

static time_value_t cur_wall_time(void) {
    struct timespec ts = {0, 0};
    if (@available(iOS 10.0, *)) {
        clock_gettime(CLOCK_REALTIME, &ts);
        time_value_t result = {static_cast<integer_t>(ts.tv_sec), static_cast<integer_t>(ts.tv_nsec / 1000)};
        return result;
    } else {
        return cur_wall_time_v1();
    }
}

static void track_record(char phase, u_int64_t hash) {
    if (!dataVec || !currentNum) {
        dataVec = new std::vector<EMFuncMeta *>;
        currentNum = new u_int64_t;
        (*currentNum) = 0;
    }
    
    if ((*currentNum) < kMapMaxCapacity) {
        time_value_t wall_ts = cur_wall_time();
        EMFuncMeta *curFuncMeta = NULL;
        if (kHMDFilterEvilMethod) {
            if (!lastFuncMeta) {
                lastFuncMeta = (EMFuncMeta *)malloc(sizeof(EMFuncMeta));
                lastFuncMeta->hash = 0;
            }
            
            if (lastFuncMeta->hash == 0) {
                lastFuncMeta->hash = hash;
                lastFuncMeta->phase = phase;
                lastFuncMeta->wall_ts = wall_ts;
                return;
            }
            BOOL isFilter = NO;
            if (lastFuncMeta->hash==hash && lastFuncMeta->phase == 'B' &&'E' == phase) {
                isFilter = ((wall_ts.seconds - lastFuncMeta->wall_ts.seconds)*1000000ll+wall_ts.microseconds-lastFuncMeta->wall_ts.microseconds)<kHMDEMFilterMicrosecond;
            }
            EMFuncMeta *vecBack = NULL;
            if ((*currentNum) > 0) {
                vecBack = (*dataVec).back();
            }
            if (isFilter) {
                if (lastFuncMeta == vecBack) {
                    (*currentNum)--;
                    (*dataVec).pop_back();
                    free(vecBack);
                    lastFuncMeta = ((*currentNum) > 0) ? (*dataVec).back() :NULL;
                    
                }
                else {
                    if (vecBack) {
                        free(lastFuncMeta);
                        lastFuncMeta = vecBack;
                    }
                    else {
                        lastFuncMeta->hash = 0;
                    }
                }
            }
            else {
                if (vecBack == lastFuncMeta) {
                    lastFuncMeta = (EMFuncMeta *)malloc(sizeof(EMFuncMeta));
                }
                else {
                    curFuncMeta = (EMFuncMeta *)malloc(sizeof(EMFuncMeta));
                    curFuncMeta->phase = lastFuncMeta->phase;
                    curFuncMeta->hash = lastFuncMeta->hash;
                    curFuncMeta->wall_ts = lastFuncMeta->wall_ts;
                }
                lastFuncMeta->hash = hash;
                lastFuncMeta->phase = phase;
                lastFuncMeta->wall_ts = wall_ts;
            }
        }
        else {
            curFuncMeta = (EMFuncMeta *)malloc(sizeof(EMFuncMeta));
            curFuncMeta->phase = phase;
            curFuncMeta->hash = hash;
            curFuncMeta->wall_ts = wall_ts;
        }
        
        if (curFuncMeta) {
            (*currentNum)++;
            (*dataVec).emplace_back(curFuncMeta);
        }
    }
}

static void freeDataVec() {
    if (dataVec) {
        typename std::vector<EMFuncMeta *>::iterator iter;
        for(iter = (*dataVec).begin(); iter != (*dataVec).end(); iter++) {
            free(*iter);
        }
        delete dataVec;
        dataVec = NULL;
    }
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    static time_value_t runloopStartTime = {0,0};
    if (activity == kCFRunLoopBeforeWaiting) {
        time_value_t runloopEndTime = cur_wall_time();
        if (runloopStartTime.seconds == 0) {  // first time
            runloopStartTime = runloopEndTime;
        }
        integer_t duration = (runloopEndTime.seconds - runloopStartTime.seconds)*1000000 - runloopStartTime.microseconds + runloopEndTime.microseconds;
        if (dataVec && (*currentNum)>0 ) {
            EMFuncMeta *vecBack = (*dataVec).back();
            if (lastFuncMeta == vecBack) {
                lastFuncMeta = NULL;
            }
            else if (lastFuncMeta && lastFuncMeta->hash != 0 && lastFuncMeta->phase == 'E') {
                (*dataVec).emplace_back(lastFuncMeta);
                lastFuncMeta = NULL;
            }
            if (lastFuncMeta) {
                lastFuncMeta->hash = 0;
            }
            
            if (duration >= kHMDEMTTimeoutInterval) {
                uint64_t startTime = runloopStartTime.seconds;
                startTime = startTime*1000 + runloopStartTime.microseconds/1000;
                uint64_t endTime = runloopEndTime.seconds;
                endTime = endTime*1000 + runloopEndTime.microseconds/1000;
                writeEMDataToDisk(dataVec, duration, startTime, endTime);
            }
            else {
                freeDataVec();
            }
            delete currentNum;
            currentNum = NULL;
            dataVec = NULL;
        }
    }
    else //kCFRunLoopAfterWaiting
    {
        //kCFRunLoopBeforeWaiting回调之后，也有可能调用函数被记录。
        if (currentNum && (*currentNum)>0) {
            delete currentNum;
            currentNum = NULL;
            if (dataVec) {
                EMFuncMeta *vecBack = (*dataVec).back();
                if (lastFuncMeta == vecBack) {
                    lastFuncMeta = NULL;
                }
                freeDataVec();
            }
        }
        if (lastFuncMeta) {
            lastFuncMeta->hash = 0;
        }
        runloopStartTime = cur_wall_time();
    }
}

void EMRunloopAddObserver() {
    if (runLoopObserver) {
        return;
    }
    runLoopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault,kCFRunLoopBeforeWaiting|kCFRunLoopAfterWaiting,YES,0,&runLoopObserverCallBack,NULL);
    CFRunLoopAddObserver(CFRunLoopGetMain(), runLoopObserver, kCFRunLoopCommonModes);
}

void EMRunloopRemoveObserver() {
    if (!runLoopObserver) {
            return;
    }
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), runLoopObserver, kCFRunLoopCommonModes);
    CFRelease(runLoopObserver);
    runLoopObserver = NULL;
}

static time_value_t customStartTime;
static time_value_t customEndTime;
void startEMCollect() {
    /**
     用户 startTrace 时，还没拉取到配置，开启了 runloop 监控
     拉取到配置开启丢帧慢函数采集后，关闭 runloop 监控
     */
    if(runLoopObserver) {
        EMRunloopRemoveObserver();
    }
    if (currentNum && (*currentNum)>0) {
        delete currentNum;
        currentNum = NULL;
        if (dataVec) {
            EMFuncMeta *vecBack = (*dataVec).back();
            if (lastFuncMeta == vecBack) {
                lastFuncMeta = NULL;
            }
            freeDataVec();
        }
    }
    if (lastFuncMeta) {
        lastFuncMeta->hash = 0;
    }
    customStartTime = cur_wall_time();
}

void endEMCollect(NSTimeInterval hitch, bool isScrolling) {
    customEndTime = cur_wall_time();
    if (customStartTime.seconds == 0) {  // first time
        customStartTime = customEndTime;
    }
    integer_t duration = (customEndTime.seconds - customStartTime.seconds)*1000000 - customStartTime.microseconds + customEndTime.microseconds;
    if (dataVec && (*currentNum)>0 ) {
        EMFuncMeta *vecBack = (*dataVec).back();
        if (lastFuncMeta == vecBack) {
            lastFuncMeta = NULL;
        }
        else if (lastFuncMeta && lastFuncMeta->hash != 0 && lastFuncMeta->phase == 'E') {
            (*dataVec).emplace_back(lastFuncMeta);
            lastFuncMeta = NULL;
        }
        if (lastFuncMeta) {
            lastFuncMeta->hash = 0;
        }
        if (hitch >= kHMDEMCollectFrameDropThreshold) {
            uint64_t startTime = customStartTime.seconds;
            startTime = startTime*1000 + customStartTime.microseconds/1000;
            uint64_t endTime = customEndTime.seconds;
            endTime = endTime*1000 + customEndTime.microseconds/1000;
            writeCustomEMDataToDisk(dataVec, duration, startTime, endTime, hitch, isScrolling);
        }
        else {
            freeDataVec();
        }
        
        delete currentNum;
        currentNum = NULL;
        dataVec = NULL;
    }
}

// MARK: - conveniences

void __heimdallr_instrument_begin(u_int64_t hash) {
    kHMDEvilMethodinstrumentationSuccess = YES;
    if (heimdallrEvilMethodEnabled && pthread_main_np() != 0)
    {
        track_record('B', hash);
    }
}

void __heimdallr_instrument_end(u_int64_t hash) {
    if (heimdallrEvilMethodEnabled && pthread_main_np() != 0)
    {
        track_record('E', hash);
    }
}



