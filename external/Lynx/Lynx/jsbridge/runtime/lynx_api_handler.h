// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_RUNTIME_LYNX_API_HANDLER_H_
#define LYNX_JSBRIDGE_RUNTIME_LYNX_API_HANDLER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "config/config.h"
#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace runtime {
class LynxRuntime;

// run on js thread
class AnimationFrameTaskHandler {
 public:
  AnimationFrameTaskHandler();
  int64_t RequestAnimationFrame(piper::Function func);
  void CancelAnimationFrame(int64_t id);
  void DoFrame(int64_t time_stamp, piper::Runtime* rt);
  void Destroy();
  bool HasPendingRequest();
  void SetPostDoFrameTaskWithFunction(piper::Function func);

 private:
  class FrameTask {
   public:
    FrameTask(piper::Function func, int64_t id);
    void Execute(piper::Runtime* rt, int64_t time_stamp);
    void Cancel();

   private:
    piper::Function func_;
    bool cancelled_;
  };
  using TaskMap = std::unordered_map<int64_t, std::unique_ptr<FrameTask>>;
  TaskMap& CurrentFrameTaskMap();
  TaskMap& NextFrameTaskMap();
  int64_t current_index_;
  bool first_map_is_the_current_;
  bool doing_frame_;
  TaskMap task_map_first_;
  TaskMap task_map_second_;
  std::unique_ptr<FrameTask> post_doframe_task_;
};

// run on js thread
class LynxApiHandler {
 public:
  LynxApiHandler(LynxRuntime* rt);
  ~LynxApiHandler() = default;
  piper::Value EnableCanvasOptimization();

 private:
  LynxRuntime* const rt_;
};

}  // namespace runtime
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_RUNTIME_LYNX_API_HANDLER_H_
