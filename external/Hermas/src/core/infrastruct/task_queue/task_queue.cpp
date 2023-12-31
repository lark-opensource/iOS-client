//
// Created by bytedance on 2020/8/10.
//

#include <chrono>
#include <algorithm>
#include "time_util.h"
#include "task_queue.h"

#include "log.h"

#define WAIT_FOREVER -1

using namespace hermas;

TaskQueue::TaskQueue()
        : m_messages()
        , m_messages_mutex()
        , m_condition()
        , m_condition_mutex()
        , m_blocked(false)
        , m_is_awoken(false)
{}

TaskQueue::~TaskQueue() {}

void TaskQueue::push_front(const void* msg_value, int64_t delay_millis) {
    //loge("TaskQueue", "[push_front] msg_value = %lld, delayMillis = %lld", msg_value, delayMillis);

    push(msg_value, true, delay_millis);

}

void TaskQueue::push_back(const void* msg_value, int64_t delay_millis) {
    //loge("TaskQueue", "[push_back] msg_value = %lld, delayMillis = %lld", msg_value, delayMillis);

    push(msg_value, false, delay_millis);

}

void TaskQueue::push(const void* msg_value, bool front_or_back, int64_t delay_millis) {
//    loge("hermas_android", "[push] msg_value = %lld, delayMillis = %lld", msg_value, delay_millis);

    TaskNode priorityNode = TaskNode();

    priorityNode.time = (front_or_back ? 0 : CurTimeMillis()) + delay_millis;
    priorityNode.value = (void*)msg_value;

    m_messages_mutex.lock();
    {
        std::unique_lock<std::mutex> condition_lock(m_condition_mutex);
        m_messages.push(priorityNode);

        if (m_blocked) {
            m_is_awoken = true; // m_is_awoken 的作用是为了避免 m_condition 的 多线程先解后锁 导致死锁
            m_condition.notify_all();
        }
    }
    m_messages_mutex.unlock();
}

void* TaskQueue::pop_front() {
    void* ret = nullptr;

    int64_t timeout_millis = 0;

    while (true) {
        // 一直等到被新插入节点唤起，或top节点超时唤起
        // wait_until_ms等待时间
        {
            int64_t wait_until_ms = 0;
            if (timeout_millis < 0) {
                wait_until_ms = WAIT_FOREVER;
            } else {
                wait_until_ms = CurTimeMillis() + timeout_millis;
            }

            std::unique_lock<std::mutex> condition_lock(m_condition_mutex);
            int64_t now_ms = 0;

            // (无top节点,永久等待 or 有top节点但没超时，等一段时间) and 不是被唤起
            while ((timeout_millis < 0 || (now_ms = CurTimeMillis()) < wait_until_ms) && !m_is_awoken) {
                if (timeout_millis == WAIT_FOREVER || timeout_millis < 0) {
                    m_condition.wait(condition_lock); // 等新消息唤起
                } else {
                    int64_t timeout_millis_update = wait_until_ms - now_ms;
                    timeout_millis_update = std::min(timeout_millis_update, timeout_millis); //避免调时间干扰
                    std::chrono::milliseconds delay_mills(timeout_millis_update);
                    m_condition.wait_for(condition_lock, delay_mills);
                }
            }

            // m_is_awoken 的作用是为了避免 m_condition 的 多线程先解后锁 导致死锁
            if (m_is_awoken) {
                // condition wait ret = WAKE，主动唤起
                m_is_awoken = false;
            } else {
                // condition wait ret = TIME_OUT，超时而起
            }
            // TODO 检查 wait_for 的结果，应该有异常中断的情况
        }

        //----------------------------------------------------------------------------

        // 被唤起了，检查情况。要么重新等待，要么拿到结果
        bool is_return = false;

        std::lock_guard<std::mutex> lk(m_messages_mutex);
        {
            // 当前时间
            int64_t cur_time_mills = CurTimeMillis();

            if (m_messages.empty()) {
                // 没消息，等新消息来
                m_blocked = true;

                timeout_millis = WAIT_FOREVER;

                //loge("TaskQueue", "[pop_front] wait");
            } else {
                // top节点
                TaskNode priority_node = m_messages.top();
                if (cur_time_mills < priority_node.time) {
                    // 没超时，等消息超时
                    m_blocked = true;

                    timeout_millis = priority_node.time - cur_time_mills;

                    //loge("TaskQueue", "[pop_front] delay_again = %lld", timeout_millis);
                } else {
                    // top节点超时，取到结果
                    m_blocked = false;

                    ret = priority_node.value;
                    m_messages.pop();

                    //loge("TaskQueue", "[pop_front] item = %lld", priority_node);

                    is_return = true;
                }
            }
        }
        
        if (is_return) {
            return ret;
        } else {
            continue;
        }
    }
}
