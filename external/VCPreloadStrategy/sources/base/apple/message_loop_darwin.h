//
// Created by bytedance on 2020/12/2.
//

#ifndef STRATEGYCENTER_MESSAGE_LOOP_DARWIN_H
#define STRATEGYCENTER_MESSAGE_LOOP_DARWIN_H

#include "cf_reference_util.h"
#include "message_loop_impl.h"
#include "vc_base.h"
#include <CoreFoundation/CoreFoundation.h>

VC_NAMESPACE_BEGIN

class MessageLoopDarwin : public MessageLoopImpl {
public:
    MessageLoopDarwin();
    ~MessageLoopDarwin() override;

private:
    void run() override;
    void terminate() override;
    void runForTime(VCTimeDuration duration) override;

    void wakeUp(VCTimePoint time_point) override;
    static void onTimerFire(CFRunLoopTimerRef timer, MessageLoopDarwin *loop);

private:
    std::atomic_bool mIsRunning;
    CFRef<CFRunLoopRef> mLoop;
    CFRef<CFRunLoopTimerRef> mDelayWakeTimer;

    VC_DISALLOW_COPY_AND_ASSIGN(MessageLoopDarwin);
};

VC_NAMESPACE_END

#endif // STRATEGYCENTER_MESSAGE_LOOP_DARWIN_H
