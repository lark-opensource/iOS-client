//
// Created by bytedance on 2020/12/2.
//

#ifndef STRATEGYCENTER_MESSAGE_TASK_RUNNER_H
#define STRATEGYCENTER_MESSAGE_TASK_RUNNER_H

#include "vc_base.h"
#include "vc_time_util.h"
#include <functional>
#include <memory>

VC_NAMESPACE_BEGIN

using closure = std::function<void()>;
class MessageLoopImpl;

class MessageTaskRunner {
public:
    explicit MessageTaskRunner(std::shared_ptr<MessageLoopImpl> loop);
    virtual ~MessageTaskRunner();

    void postTask(const closure &task);
    void postTaskForTime(const closure &task, VCTimePoint target_time);
    void postDelayTask(const closure &task, VCTimeDuration duration);

    virtual bool runTasksOnCurrentThread();

private:
    std::shared_ptr<MessageLoopImpl> mLoop;
    VC_DISALLOW_COPY_AND_ASSIGN(MessageTaskRunner);
};

VC_NAMESPACE_END

#endif // STRATEGYCENTER_MESSAGE_TASK_RUNNER_H
