// Copyright 2019 The Lynx Authors. All rights reserved.

#include "base/threading/task_runner_manufactor.h"

#include <condition_variable>
#include <vector>

#include "base/compiler_specific.h"
#include "base/no_destructor.h"
#include "third_party/fml/message_loop.h"

#ifdef OS_WIN
#include "third_party/fml/platform/win/task_runner_win32.h"
#endif

namespace lynx {
namespace base {

namespace {

inline bool& HasInit() {
  static bool has_init = false;
  return has_init;
}

inline std::condition_variable& GetUIInitCV() {
  static base::NoDestructor<std::condition_variable> ui_thread_init_cv_;
  return *ui_thread_init_cv_;
}

#if !defined(OS_WIN) && !defined(MODE_HEADLESS)
// fix for unused function error.
inline std::mutex& GetUIThreadMutex() {
  static base::NoDestructor<std::mutex> ui_thread_init_mutex;
  return *ui_thread_init_mutex;
}
#endif

inline fml::RefPtr<fml::TaskRunner>& GetUITaskRunner() {
// win need use fml::TaskRunnerWin32
#ifdef OS_WIN
  static base::NoDestructor<fml::RefPtr<fml::TaskRunner>> runner(
      fml::TaskRunnerWin32::Create());
// headless not have a ui thread loop, create a async thread instead
#elif MODE_HEADLESS
  static base::NoDestructor<fml::Thread> ui_thread("Lynx_UI");
  static base::NoDestructor<fml::RefPtr<fml::TaskRunner>> runner(
      ui_thread->GetTaskRunner());
#else
  // other platform, UIThread::Init init ui thread loop and set runner here
  static base::NoDestructor<fml::RefPtr<fml::TaskRunner>> runner;
#endif
  return *runner;
}
}  // namespace

fml::RefPtr<fml::TaskRunner>& UIThread::GetRunner() {
#if !defined(OS_WIN) && !defined(MODE_HEADLESS)
  if (!HasInit()) {
    LOGI("Waiting for UIThread to initialize.");
    std::unique_lock<std::mutex> local_lock(GetUIThreadMutex());
    GetUIInitCV().wait(local_lock);
  }
#endif
  return GetUITaskRunner();
}

void UIThread::Init() {
  if (HasInit()) {
    return;
  }
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  GetUITaskRunner() = fml::MessageLoop::GetCurrent().GetTaskRunner();
  HasInit() = true;
  GetUIInitCV().notify_all();
}

TaskRunnerManufactor::TaskRunnerManufactor(ThreadStrategyForRendering strategy,
                                           bool enable_multi_tasm_thread,
                                           bool enable_multi_layout_thread) {
  static uint64_t current_label = 0;
  label_ = ++current_label;
  thread_strategy_ = strategy;
  switch (strategy) {
    case ALL_ON_UI: {
      StartUIThread();
      StartJSThread();
      tasm_task_runner_ = ui_task_runner_;
      layout_task_runner_ = ui_task_runner_;
    } break;
    case MOST_ON_TASM: {
      StartUIThread();
      StartJSThread();
      StartTASMThread(enable_multi_tasm_thread);
      layout_task_runner_ = tasm_task_runner_;
    } break;
    case PART_ON_LAYOUT: {
      StartUIThread();
      StartJSThread();
      StartLayoutThread(enable_multi_layout_thread);
      tasm_task_runner_ = ui_task_runner_;
    } break;
    case MULTI_THREADS: {
      StartUIThread();
      StartJSThread();
      StartTASMThread(enable_multi_tasm_thread);
      StartLayoutThread(enable_multi_layout_thread);
    } break;
    default:
      break;
  }
}

fml::RefPtr<fml::TaskRunner> TaskRunnerManufactor::GetJSRunner() {
  static base::NoDestructor<fml::Thread> js_thread(
      fml::Thread::ThreadConfig("Lynx_JS", fml::Thread::ThreadPriority::HIGH));
  return js_thread->GetTaskRunner();
}

fml::RefPtr<fml::TaskRunner> TaskRunnerManufactor::GetTASMTaskRunner() {
  return tasm_task_runner_;
}

fml::RefPtr<fml::TaskRunner> TaskRunnerManufactor::GetLayoutTaskRunner() {
  return layout_task_runner_;
}

fml::RefPtr<fml::TaskRunner> TaskRunnerManufactor::GetUITaskRunner() {
  return ui_task_runner_;
}

fml::RefPtr<fml::TaskRunner> TaskRunnerManufactor::GetJSTaskRunner() {
  return js_task_runner_;
}

fml::RefPtr<fml::TaskRunner> TaskRunnerManufactor::GetGPUTaskRunner() {
  return gpu_task_runner_;
}

ThreadStrategyForRendering
TaskRunnerManufactor::GetThreadStrategyForRendering() {
  return thread_strategy_;
}

void TaskRunnerManufactor::StartUIThread() {
  ui_task_runner_ = UIThread::GetRunner();
}

void TaskRunnerManufactor::StartTASMThread(bool enable_multi_tasm_thread) {
  if (enable_multi_tasm_thread) {
    tasm_thread_ = std::make_unique<fml::Thread>(
        fml::Thread::ThreadConfig("Lynx_TASM" + std::to_string(label_),
                                  fml::Thread::ThreadPriority::HIGH));
    tasm_task_runner_ = tasm_thread_->GetTaskRunner();
  } else {
    static base::NoDestructor<fml::Thread> tasm_thread(
        fml::Thread::ThreadConfig("Lynx_TASM",
                                  fml::Thread::ThreadPriority::HIGH));
    tasm_task_runner_ = tasm_thread->GetTaskRunner();
  }
}

void TaskRunnerManufactor::StartLayoutThread(bool enable_multi_layout_thread) {
  if (enable_multi_layout_thread) {
    layout_thread_ = std::make_unique<fml::Thread>(
        fml::Thread::ThreadConfig("Lynx_Layout" + std::to_string(label_),
                                  fml::Thread::ThreadPriority::HIGH));
    layout_task_runner_ = layout_thread_->GetTaskRunner();
  } else {
    static base::NoDestructor<fml::Thread> layout_thread(
        fml::Thread::ThreadConfig("Lynx_Layout",
                                  fml::Thread::ThreadPriority::HIGH));
    layout_task_runner_ = layout_thread->GetTaskRunner();
  }
}

void TaskRunnerManufactor::StartJSThread() {
#if LYNX_ENABLE_FROZEN_MODE
  js_task_runner_ = ui_task_runner_;
#else
  js_task_runner_ = GetJSRunner();
#endif
}

void TaskRunnerManufactor::StartGPUThread() {
  static base::NoDestructor<fml::Thread> gpu_thread(fml::Thread::ThreadConfig(
      "Lynx_GPU", fml::Thread::ThreadPriority::NORMAL));
  gpu_task_runner_ = gpu_thread->GetTaskRunner();
}

fml::Thread TaskRunnerManufactor::CreateJSWorkerThread(
    const std::string& worker_name) {
  std::string thread_name = std::string("Lynx_JS_Worker-") + worker_name;
  return fml::Thread(thread_name);
}

}  // namespace base
}  // namespace lynx
