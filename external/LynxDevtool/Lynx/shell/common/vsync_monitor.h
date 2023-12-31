// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_COMMON_VSYNC_MONITOR_H_
#define LYNX_SHELL_COMMON_VSYNC_MONITOR_H_

#include <functional>
#include <memory>
#include <unordered_map>

#include "base/closure.h"
#include "shell/lynx_shell.h"
#include "third_party/fml/task_runner.h"

namespace lynx {
namespace shell {

class VSyncMonitor : public std::enable_shared_from_this<VSyncMonitor> {
 public:
  using Callback = base::MoveOnlyClosure<void, int64_t, int64_t>;

  VSyncMonitor() = default;
  virtual ~VSyncMonitor() = default;

  virtual void Init() {}

  // TODO(heshan):invoke this method in Init.
  // after initialization, VSyncMonitor needs to bind
  // to MessageLoop of current thread.
  void BindToCurrentThread();

  // the callback will be replaced
  void AsyncRequestVSync(Callback callback);

  // the callback is unique per id
  void AsyncRequestVSync(uintptr_t id, Callback callback);

  // frame_start_time/frame_target_time is in nanoseconds
  void OnVSync(int64_t frame_start_time, int64_t frame_target_time);

  virtual void RequestVSync() = 0;

  void set_runtime_actor(
      const std::shared_ptr<LynxActor<runtime::LynxRuntime>> &actor) {
    runtime_actor_ = actor;
  }
  const std::shared_ptr<LynxActor<runtime::LynxRuntime>> runtime_actor() const {
    return runtime_actor_;
  }

 protected:
  Callback callback_;

 private:
  void OnVSyncInternal(int64_t frame_start_time, int64_t frame_target_time);

  bool requested_{false};
  std::unordered_map<uintptr_t, Callback> secondary_callbacks_;
  std::shared_ptr<LynxActor<runtime::LynxRuntime>> runtime_actor_;
  fml::RefPtr<fml::TaskRunner> runner_;

  // disallow copy&assign
  VSyncMonitor(const VSyncMonitor &) = delete;
  VSyncMonitor &operator==(const VSyncMonitor &) = delete;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_COMMON_VSYNC_MONITOR_H_
