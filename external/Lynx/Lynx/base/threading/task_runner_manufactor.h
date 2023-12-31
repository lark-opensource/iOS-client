// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_THREADING_TASK_RUNNER_MANUFACTOR_H_
#define LYNX_BASE_THREADING_TASK_RUNNER_MANUFACTOR_H_

#include <memory>
#include <mutex>
#include <string>

#include "base/no_destructor.h"
#include "third_party/fml/task_runner.h"
#include "third_party/fml/thread.h"

namespace lynx {
namespace base {

enum ThreadStrategyForRendering {
  ALL_ON_UI = 0,
  MOST_ON_TASM = 1,
  PART_ON_LAYOUT = 2,
  MULTI_THREADS = 3,
};

// TODO(heshan):for 1.5, put here, will refactor to base in 2.0...
class UIThread {
 public:
  BASE_EXPORT_FOR_DEVTOOL static fml::RefPtr<fml::TaskRunner>& GetRunner();

  // ensure call on ui thread.
  static void Init();

 private:
  UIThread() = delete;
  ~UIThread() = delete;
};

class TaskRunnerManufactor {
 public:
  // Should be created on UI thread
  TaskRunnerManufactor(ThreadStrategyForRendering strategy,
                       bool enable_multi_tasm_thread,
                       bool enable_multi_layout_thread);

  virtual ~TaskRunnerManufactor() = default;

  TaskRunnerManufactor(const TaskRunnerManufactor&) = delete;
  TaskRunnerManufactor& operator=(const TaskRunnerManufactor&) = delete;
  TaskRunnerManufactor(TaskRunnerManufactor&&) = default;
  TaskRunnerManufactor& operator=(TaskRunnerManufactor&&) = default;

  // TODO(heshan):will be deleted, temporary use for Helium...
  static fml::RefPtr<fml::TaskRunner> GetJSRunner();

  fml::RefPtr<fml::TaskRunner> GetTASMTaskRunner();

  fml::RefPtr<fml::TaskRunner> GetLayoutTaskRunner();

  fml::RefPtr<fml::TaskRunner> GetUITaskRunner();

  fml::RefPtr<fml::TaskRunner> GetJSTaskRunner();

  fml::RefPtr<fml::TaskRunner> GetGPUTaskRunner();

  ThreadStrategyForRendering GetThreadStrategyForRendering();

  void StartGPUThread();

  static fml::Thread CreateJSWorkerThread(const std::string& worker_name);

 private:
  void StartUIThread();

  void StartTASMThread(bool enable_multi_tasm_thread);

  void StartLayoutThread(bool enable_multi_layout_thread);

  void StartJSThread();

  fml::RefPtr<fml::TaskRunner> tasm_task_runner_;
  fml::RefPtr<fml::TaskRunner> layout_task_runner_;
  fml::RefPtr<fml::TaskRunner> ui_task_runner_;
  fml::RefPtr<fml::TaskRunner> gpu_task_runner_;

  fml::RefPtr<fml::TaskRunner> js_task_runner_;

  // Can only be used when multiple TASM thread is enabled
  std::unique_ptr<fml::Thread> tasm_thread_;
  // Can only be used when multiple Layout thread is enabled
  std::unique_ptr<fml::Thread> layout_thread_;

  ThreadStrategyForRendering thread_strategy_;

  uint64_t label_;
};

}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_THREADING_TASK_RUNNER_MANUFACTOR_H_
