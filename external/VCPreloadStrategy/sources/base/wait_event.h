//
// Created by zhongzhendong on 2020/12/4.
//

#ifndef STRATEGYCENTER_WAIT_EVENT_H
#define STRATEGYCENTER_WAIT_EVENT_H

#include "vc_base.h"
#include "vc_time_util.h"
#include <condition_variable>
#include <mutex>

VC_NAMESPACE_BEGIN

class AutoWaitEvent final {
public:
    AutoWaitEvent();
    ~AutoWaitEvent();

    void signal();
    void reset();

    void wait();
    bool waitWithTimeout(VCTimeDuration timeoutDuration);

private:
    std::condition_variable mCond;
    std::mutex mMutex;
    bool mIsSignaled = false;

    VC_DISALLOW_COPY_AND_ASSIGN(AutoWaitEvent);
};

VC_NAMESPACE_END

#endif // STRATEGYCENTER_WAIT_EVENT_H
