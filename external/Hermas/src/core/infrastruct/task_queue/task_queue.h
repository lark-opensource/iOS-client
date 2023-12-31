//
// Created by bytedance on 2020/8/10.
//

#ifndef HERMAS_TASK_QUEUE_H
#define HERMAS_TASK_QUEUE_H

#include <cstdint>
#include <queue>
#include <mutex>
#include <condition_variable>

namespace hermas
{

struct TaskNode
{
    int64_t time;
    void* value;

    bool operator<(const TaskNode & node) const
    {
        return node.time < time;
    }
};

class TaskQueue
{
public:
    explicit TaskQueue();
    virtual ~TaskQueue();

    void push_front(const void* msg_value, int64_t delay_millis = 0);
    void push_back(const void* msg_value, int64_t delay_millis = 0);

    void* pop_front();

private:
    void push(const void* msg_value, bool front_or_back, int64_t delay_millis = 0);

private:
    std::priority_queue<TaskNode> m_messages;
    std::mutex m_messages_mutex;

    std::condition_variable m_condition;
    std::mutex m_condition_mutex;
    bool m_blocked;
    bool m_is_awoken;
};

}

#endif //HERMAS_TASK_QUEUE_H
