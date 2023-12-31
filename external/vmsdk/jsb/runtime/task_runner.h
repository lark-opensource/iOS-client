#ifndef TASK_RUNNER_H
#define TASK_RUNNER_H

#include "basic/task/callback.h"
#include "basic/threading/thread.h"
#include "basic/timer/timer_node.h"

namespace vmsdk {
namespace runtime {

class TaskRunner {
 public:
  // No thread constraint, run task on any thread that
  TaskRunner() : thread_(nullptr) {}
  // Only run task on designative thread
  explicit TaskRunner(const std::shared_ptr<general::Thread> &thread)
      : thread_(thread), running_(true) {}

  virtual ~TaskRunner() = default;

  virtual void PostTask(general::Closure *task);

  virtual void PostTaskAtFront(general::Closure *task);

  virtual void RunNowOrPostTaskAtFront(general::Closure *task);

  virtual void RunNowOrPostTask(general::Closure *task);

  virtual std::shared_ptr<general::TimerNode> PostDelayedTask(
      general::Closure *task, int32_t delayed_milliseconds);

  virtual std::shared_ptr<general::TimerNode> PostIntervalTask(
      general::Closure *task, int32_t delayed_milliseconds);

  virtual void RemoveTaskByGroupId(uintptr_t group_Id);

  virtual void RemoveTask(const std::shared_ptr<general::TimerNode> &task);

  virtual void RemoveTasks();

  virtual bool CanRunNow();

  static void RunNowOrPostTask2(std::shared_ptr<TaskRunner> runner,
                                general::Closure *task);

  void SetRunning(bool running) { running_ = running; }
  bool getRunning() { return running_; }

 private:
  std::shared_ptr<general::Thread> thread_;
  bool running_;
};

}  // namespace runtime
}  // namespace vmsdk

#endif  // TASK_RUNNER_H
