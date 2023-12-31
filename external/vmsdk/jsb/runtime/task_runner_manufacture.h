#pragma once

#include <memory>
#include <mutex>

#include "basic/log/logging.h"
#include "basic/no_destructor.h"
#include "basic/threading/thread.h"
#include "jsb/runtime/task_runner.h"

namespace vmsdk {

namespace runtime {

class JSThread {
 public:
  JSThread(std::string thread_name)
      : impl_(std::make_shared<general::Thread>(
            general::MessageLoop::MESSAGE_LOOP_JS, thread_name.c_str())) {
    impl_->Start();
  }

  ~JSThread() = default;

  std::shared_ptr<general::Thread> Get() { return impl_; }

 private:
  std::shared_ptr<general::Thread> impl_;
};

class TaskRunnerManufacture {
 public:
  TaskRunnerManufacture() = default;
  virtual ~TaskRunnerManufacture() = default;

  std::shared_ptr<general::Thread> GetJSThread() { return js_thread_; }

  std::shared_ptr<TaskRunner> GetJSTaskRunner() { return js_task_runner_; }

 protected:
  std::shared_ptr<runtime::TaskRunner> js_task_runner_;
  std::shared_ptr<general::Thread> js_thread_;
};

/**
 * Single Thread Mode
 */
class TaskRunnerSingleton : public TaskRunnerManufacture {
 public:
  static std::shared_ptr<TaskRunnerSingleton> GetInstance() {
    VLOGD("TaskRunnerSingleton::GetInstance()");
    static TaskRunnerSingleton* runner = new TaskRunnerSingleton();
    static std::shared_ptr<TaskRunnerSingleton> instance =
        std::shared_ptr<TaskRunnerSingleton>(runner);
    return instance;
  }

  ~TaskRunnerSingleton() {}

 private:
  TaskRunnerSingleton() {
    js_thread_ = (new JSThread("VMSDK_JS_THREAD"))->Get();
    js_task_runner_ = std::make_shared<TaskRunner>(js_thread_);
  }
};

/**
 * Multiple Thread Mode
 */
class TaskRunnerMultiThread : public TaskRunnerManufacture {
 public:
  TaskRunnerMultiThread() {
    VLOGD("new TaskRunnerMultiThread()");
    thread_index_++;
    js_thread_ =
        (new JSThread("VMSDK_JS_THREAD_" + std::to_string(thread_index_)))
            ->Get();
    js_task_runner_ = std::make_shared<TaskRunner>(js_thread_);
  }
  ~TaskRunnerMultiThread() {}

 private:
  static int thread_index_;
};

}  // namespace runtime
}  // namespace vmsdk
