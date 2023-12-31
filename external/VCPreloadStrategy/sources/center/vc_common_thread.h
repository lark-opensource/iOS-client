//
// Created by 黄清 on 3/16/21.
//

#ifndef PRELOAD_VC_COMMON_THREAD_H
#define PRELOAD_VC_COMMON_THREAD_H

#include "message_task_runner.h"
#include "vc_base.h"
#include <thread>

VC_NAMESPACE_BEGIN

class VCCommonThread {
private:
    VCCommonThread();
    ~VCCommonThread();

public:
    static VCCommonThread &thread() {
        [[clang::no_destroy]] static VCCommonThread s_singleton;
        return s_singleton;
    }

public: /// state
    void start();
    void stop();

public: /// task
    void postTask(const closure &task);
    void postDelayTask(const closure &task, VCTimeDuration &duration);
    void sendTask(const closure &task);

private:
    std::thread *mThread{nullptr};
    std::shared_ptr<MessageTaskRunner> mTaskRunner;

private:
#if defined(__ANDROID__)
    bool mAttachEnv{false};
#endif

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCCommonThread);
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_COMMON_THREAD_H
