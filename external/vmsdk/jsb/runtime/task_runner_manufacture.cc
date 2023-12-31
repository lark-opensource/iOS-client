#include "jsb/runtime/task_runner_manufacture.h"

namespace vmsdk {
namespace runtime {

// class ThreadPool {
// public:
//  static ThreadPool* GetInstance() {
//    static ThreadPool* instance = new ThreadPool(
//      general::MessageLoop::MESSAGE_LOOP_TYPE::MESSAGE_LOOP_JS,
//      "VMSDK_JS_Thread_", 200);
//    return instance;
//  }
//
//  ~ThreadPool() {}
//
//  std::shared_ptr<general::Thread> GetOrNewThread() {
//    long lowest_frequency = INT_MAX;
//    std::shared_ptr<general::Thread> target_thread;
//    int index = 0;
//    for (auto& weak_thread : threads_) {
//      auto thread = weak_thread.lock();
//      if (!thread) {
//        return NewThreadAtIndex(index);
//      } else if (lowest_frequency > thread.use_count()) {
//        target_thread = thread;
//        lowest_frequency = thread.use_count();
//      }
//      index++;
//    }
//    return target_thread;
//  }
//
// private:
//  ThreadPool(general::MessageLoop::MESSAGE_LOOP_TYPE type,
//             const std::string& name, size_t capacity, int32_t priority = 5)
//      : capacity_(capacity),
//        type_(type),
//        priority_(priority),
//        thread_name_(name),
//        threads_(capacity) {}
//
//  std::shared_ptr<general::Thread> NewThreadAtIndex(int index) {
//    general::ThreadInfo thread_info{thread_name_ + std::to_string(index),
//                                   priority_};
//    auto target_thread = std::make_shared<general::Thread>(type_,
//    thread_info); target_thread->Start(); threads_[index] = target_thread;
//    return target_thread;
//  }
//
//  ALLOW_UNUSED_TYPE size_t capacity_;
//  general::MessageLoop::MESSAGE_LOOP_TYPE type_;
//  const int32_t priority_;
//  std::string thread_name_;
//  std::vector<std::weak_ptr<general::Thread>> threads_;
//};

int TaskRunnerMultiThread::thread_index_ = 0;

}  // namespace runtime
}  // namespace vmsdk
