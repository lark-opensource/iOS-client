//
// Created by zhongzhendong on 2020/12/2.
//

#ifndef STRATEGYCENTER_MESSAGE_LOOP_H
#define STRATEGYCENTER_MESSAGE_LOOP_H

#include "message_loop_impl.h"
#include "message_task_runner.h"
#include "vc_base.h"
#include "vc_time_util.h"

#include <memory>

VC_NAMESPACE_BEGIN

class MessageLoopImpl;

class MessageLoop {
public:
    static MessageLoop &getCurrent();
    static void initForCurrentThread();
    static bool isCurrentThreadInitialized();
    static MessageTaskQueueId getCurrentTaskQueueId();

    void run();
    void runForTime(VCTimeDuration duration);
    void terminate();

    std::shared_ptr<MessageTaskRunner> getTaskRunner() const;

    ~MessageLoop();

private:
    friend MessageLoopImpl;
    friend MessageTaskRunner;

    std::shared_ptr<MessageLoopImpl> mLoop;
    std::shared_ptr<MessageTaskRunner> mTaskRunner;

    MessageLoop();

    std::shared_ptr<MessageLoopImpl> getLoopImpl() const;

    VC_DISALLOW_COPY_AND_ASSIGN(MessageLoop);
};

VC_NAMESPACE_END

#endif // STRATEGYCENTER_MESSAGE_LOOP_H
