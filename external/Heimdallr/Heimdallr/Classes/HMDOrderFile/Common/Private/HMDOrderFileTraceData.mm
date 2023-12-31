//
//  HMDOrderFileTraceData.cpp
//  AWECloudCommand
//
//  Created by maniackk on 2021/11/16.
//

#include "HMDOrderFileTraceData.h"
#include "HMDOrderFileCollectData.h"
#include <map>
#include <mach/mach_host.h>
#include <mach/mach_time.h>
#include <mach/thread_act.h>
#include <pthread/pthread.h>


BOOL heimdallrOrderFileEnabled = NO;

#define kOrderFileMaxCapacity 10000

static pthread_mutex_t mutexlock = PTHREAD_MUTEX_INITIALIZER;
static std::map<u_int64_t, std::pair<integer_t, integer_t>> *mainThreadDataMap;
static std::map<u_int64_t, std::pair<integer_t, integer_t>> *subThreadDataMap;
static u_int64_t *mainThreadMapCount;
static u_int64_t *subThreadMapCount;

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
        clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
        time_value_t result = {static_cast<integer_t>(ts.tv_sec), static_cast<integer_t>(ts.tv_nsec / 1000)};
        return result;
    } else {
        return cur_wall_time_v1();
    }
}

static void track_record(u_int64_t hash) {
    time_value_t wall_ts = cur_wall_time();
    if (pthread_main_np()) {
        if (!mainThreadMapCount || !mainThreadDataMap) {
            mainThreadDataMap = new std::map<u_int64_t, std::pair<integer_t, integer_t>>;
            mainThreadMapCount = new uint64_t;
        }
        if ((*mainThreadDataMap).find(hash) == (*mainThreadDataMap).end()) {
            (*mainThreadMapCount)++;
            (*mainThreadDataMap)[hash] = std::make_pair(wall_ts.seconds, wall_ts.microseconds);
            if ((*mainThreadMapCount) > kOrderFileMaxCapacity) {
                writeOrderFileDataToDisk(mainThreadDataMap);
                delete mainThreadMapCount;
                mainThreadMapCount = NULL;
            }
        }
    }else {
        pthread_mutex_lock(&mutexlock);
        if (!subThreadMapCount || !subThreadDataMap) {
            subThreadDataMap = new std::map<u_int64_t, std::pair<integer_t, integer_t>>;
            subThreadMapCount = new uint64_t;
        }
        if ((*subThreadDataMap).find(hash) == (*subThreadDataMap).end()) {
            (*subThreadMapCount)++;
            (*subThreadDataMap)[hash] = std::make_pair(wall_ts.seconds, wall_ts.microseconds);
            if ((*subThreadMapCount) > kOrderFileMaxCapacity) {
                writeOrderFileDataToDisk(subThreadDataMap);
                delete subThreadMapCount;
                subThreadMapCount = NULL;
            }
        }
        pthread_mutex_unlock(&mutexlock);
    }
}

void __heimdallr_instrument_orderfile(u_int64_t hash) {
    if (heimdallrOrderFileEnabled) {
        track_record(hash);
    }
}

void StartEnd(void) {
    if (pthread_main_np()) {
        writeOrderFileDataToDisk(mainThreadDataMap);
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            writeOrderFileDataToDisk(mainThreadDataMap);
        });
    }
    pthread_mutex_lock(&mutexlock);
    writeOrderFileDataToDisk(subThreadDataMap);
    pthread_mutex_unlock(&mutexlock);
    finishWriteFile();
}
