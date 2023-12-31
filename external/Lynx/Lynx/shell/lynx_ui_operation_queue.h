// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_LYNX_UI_OPERATION_QUEUE_H_
#define LYNX_SHELL_LYNX_UI_OPERATION_QUEUE_H_

#include <atomic>
#include <functional>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "base/closure.h"

namespace lynx {

namespace shell {

using UIOperation = base::closure;
using ErrorCallback = base::MoveOnlyClosure<void, int32_t, const std::string &>;

enum class UIOperationStatus : uint32_t {
  INIT = 0,
  TASM_FINISH,
  LAYOUT_FINISH,
  ALL_FINISH
};

class LynxUIOperationQueue {
 public:
  LynxUIOperationQueue() = default;
  virtual ~LynxUIOperationQueue() = default;

  virtual void EnqueueUIOperation(UIOperation operation);
  void Destroy();
  virtual void UpdateStatus(UIOperationStatus status) {}
  virtual void MarkDirty() {}
  virtual void ForceFlush();
  virtual void Flush();
  virtual void SetEnableFlush(bool enable_flush);
  void SetErrorCallback(ErrorCallback callback) {
    error_callback_ = std::move(callback);
  };
  virtual uint32_t GetNativeUpdateDataOrder() { return 0; }
  virtual uint32_t UpdateNativeUpdateDataOrder() { return 0; }
  virtual bool IsInFlush() { return false; }

 protected:
  void ConsumeOperations(std::vector<UIOperation> operations);

  std::vector<UIOperation> operations_;
  std::atomic_bool destroyed_{false};
  bool enable_flush_{true};
  ErrorCallback error_callback_;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_LYNX_UI_OPERATION_QUEUE_H_
