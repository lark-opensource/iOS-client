//
// Created by bytedance on 2020/12/2.
//

#ifndef STRATEGYCENTER_MESSAGE_TASK_H
#define STRATEGYCENTER_MESSAGE_TASK_H

#include "vc_base.h"
#include "vc_time_util.h"
#include <functional>
#include <queue>

VC_NAMESPACE_BEGIN

using closure = std::function<void()>;

class MessageTask {
public:
    MessageTask(size_t order, const closure &task, VCTimePoint target_time);
    MessageTask(const MessageTask &other);
    ~MessageTask();

    const closure &getTask() const;
    VCTimePoint getTargetTime() const;

    bool operator>(const MessageTask &other) const;

private:
    size_t mOrder;
    closure mTask;
    VCTimePoint mTargetTime;
};

using DelayedTaskQueue = std::priority_queue<MessageTask,
                                             std::deque<MessageTask>,
                                             std::greater<MessageTask>>;

VC_NAMESPACE_END

#endif // STRATEGYCENTER_MESSAGE_TASK_H
