#ifndef DEVTOOL_QJS_INSPECTOR_HANDLE_H
#define DEVTOOL_QJS_INSPECTOR_HANDLE_H
#include <jsb/runtime/task_runner.h>

#include <memory>
#include <mutex>
#include <queue>
#include <string>

#include "basic/threading/condition.h"
#include "basic/threading/lock.h"

#ifdef __cplusplus
extern "C" {
#endif

#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

using MessageQueue = std::queue<std::string>;

namespace vmsdk {
namespace devtool {
class InspectorImpl;

namespace qjs {
class QjsInspectorHandle {
 public:
  static void SetPauseAtEntry(bool enable);

  QjsInspectorHandle(LEPUSRuntime *rt, InspectorImpl *inspector_impl);

  void DispatchMessage(const std::string &message,
                       std::shared_ptr<runtime::TaskRunner> taskRunner);

  void ContextCreated(LEPUSContext *qjs_context_);

  void ContextDestroyed();

  InspectorImpl *GetInspector() { return inspector_impl_; }

  void QuitPause();

  void Pause();

 private:
  void SendResponse(const std::string &response);

  InspectorImpl *inspector_impl_;
  LEPUSRuntime *rt_;
  LEPUSContext *ctx_;
  std::unique_ptr<MessageQueue> message_queue_;
  general::Lock lock_;
  general::Condition condition_;

  bool running_nested_loop_ = false;
  bool waiting_for_message_ = false;
};
}  // namespace qjs
}  // namespace devtool
}  // namespace vmsdk
#endif  // DEVTOOL_QJS_INSPECTOR_HANDLE_H
