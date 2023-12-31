//
// Created by zhongzhendong on 2020/12/2.
//

#ifndef STRATEGYCENTER_MESSAGE_LOOP_IMPL_H
#define STRATEGYCENTER_MESSAGE_LOOP_IMPL_H

#include "message_loop_task_queue.h"
#include "vc_base.h"
#include "vc_time_util.h"

VC_NAMESPACE_BEGIN

class MessageTaskQueueId;

class MessageLoopImpl : public MessageLoopWakeupHandler {
public:
    static std::shared_ptr<MessageLoopImpl> create();
    ~MessageLoopImpl() override;

    virtual void run() = 0;
    virtual void runForTime(VCTimeDuration duration) = 0;
    virtual void terminate() = 0;

    void postTask(const closure &task, VCTimePoint target_time);

    void doRun();
    void doRunForTime(VCTimeDuration delay);
    void doTerminate();

    virtual MessageTaskQueueId getTaskQueueId() const;

protected:
    friend class MessageLoop;
    void runExpiredTasksNow();
    void runSingleExpiredTaskNow();
    MessageLoopImpl();

private:
    MessageLoopTaskQueues *mTaskQueues;
    MessageTaskQueueId mQueueId;
    std::atomic_bool mTerminated;

    void runAndPopTasks(FlushType type);

    VC_DISALLOW_COPY_AND_ASSIGN(MessageLoopImpl);
};

VC_NAMESPACE_END

#endif // STRATEGYCENTER_MESSAGE_LOOP_IMPL_H
