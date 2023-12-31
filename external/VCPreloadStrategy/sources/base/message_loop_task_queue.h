//
// Created by zhongzhendong on 2020/12/2.
//

#ifndef STRATEGYCENTER_MESSAGE_LOOP_TASK_QUEUE_H
#define STRATEGYCENTER_MESSAGE_LOOP_TASK_QUEUE_H

#include "message_task.h"
#include "vc_base.h"
#include "vc_time_util.h"
#include <atomic>
#include <climits>
#include <memory>
#include <mutex>

VC_NAMESPACE_BEGIN

class MessageTaskQueueId {
public:
    static const size_t kDefaultValue = ULONG_MAX;

    explicit MessageTaskQueueId(size_t value) : value_(value) {}

    operator int() const {
        return (int)value_;
    }

private:
    size_t value_ = kDefaultValue;
};

class MessageTaskQueueEntry;

class MessageLoopWakeupHandler {
public:
    virtual ~MessageLoopWakeupHandler() = default;
    virtual void wakeUp(VCTimePoint timepoint) = 0;
};

enum class FlushType {
    kSingle,
    kAll,
};

class MessageLoopTaskQueues {
public:
    static MessageLoopTaskQueues *getInstance();
    ~MessageLoopTaskQueues();

    MessageTaskQueueId createTaskQueue();
    void dispose(MessageTaskQueueId queue_id);
    void disposeTasks(MessageTaskQueueId queue_id);

    // Task
    void registerTask(MessageTaskQueueId queue_id,
                      const closure &task,
                      VCTimePoint target_time);
    bool hasPendingTask(MessageTaskQueueId queue_id) const;
    size_t getNumPendingTasks(MessageTaskQueueId queue_id) const;
    closure popNextTaskToRun(MessageTaskQueueId queue_id,
                             VCTimePoint from_time);

    void setMessageLoopWakeupHandler(MessageTaskQueueId queue_id,
                                     MessageLoopWakeupHandler *wakeupHandler);

private:
    MessageLoopTaskQueues();
    static MessageLoopTaskQueues &singleton();

    void wakeUpUnlocked(MessageTaskQueueId queue_id, VCTimePoint time) const;

    bool hasPendingTasksUnlocked(MessageTaskQueueId queue_id) const;
    const MessageTask &
    peekNextTaskUnlocked(MessageTaskQueueId owner_id,
                         MessageTaskQueueId &top_queue_id) const;

    VCTimePoint getNextWakeTimeUnlocked(MessageTaskQueueId queue_id) const;

private:
    static MessageLoopTaskQueues *gInstance;

    mutable std::mutex mQueueMutex;
    std::map<MessageTaskQueueId, std::unique_ptr<MessageTaskQueueEntry>>
            mQueueEntries;

    size_t mTaskQueueIdCounter;
    std::atomic<int> mOrder;

    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(MessageLoopTaskQueues);
};

VC_NAMESPACE_END

#endif // STRATEGYCENTER_MESSAGE_LOOP_TASK_QUEUE_H
