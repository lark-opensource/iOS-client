//
// Created by bytedance on 2020/8/24.
//

#ifndef HERMAS_HANDLER_H
#define HERMAS_HANDLER_H


#include <thread>
#include <atomic>

#include "env.h"

namespace hermas {

class TaskQueue;

class Handler {
  public:
    /**
     * @param is_global_handler 全局共用一个线程
     */
    explicit Handler(bool is_global_handler = true);
    explicit Handler(const std::string&name, bool is_global_handler = false);
    virtual ~Handler();
    
    void Stop();
    
    struct IRunnable {
      public:
        explicit IRunnable();
        virtual ~IRunnable();
        virtual void run();
    };

    void Post(IRunnable * runnable, int64_t delay_millis = 0);

    virtual void SendMsg(int what, int64_t delay_millis = 0);
    virtual void SendMsg(int what, void *obj, int64_t delay_mills = 0);
    virtual void SendMsg(int what, int64_t arg1, int64_t arg2, int64_t delay_millis = 0);
    virtual void SendMsg(int what, int64_t arg1, int64_t arg2, void * obj, int64_t delay_millis = 0);

    virtual void HandleMessage(int what, int64_t arg1, int64_t arg2, void * obj);

  private:
    std::string m_name;
    std::unique_ptr<TaskQueue> mp_task_queue;
    std::thread mp_thread;
    std::atomic<bool> is_running_;
    bool m_is_global_handler;
};

}

#endif //HERMAS_HANDLER_H
