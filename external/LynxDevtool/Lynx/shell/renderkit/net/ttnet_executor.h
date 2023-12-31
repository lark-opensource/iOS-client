// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_NET_TTNET_EXECUTOR_H_
#define LYNX_SHELL_RENDERKIT_NET_TTNET_EXECUTOR_H_

// to be used outside of Chromium infrastructure,
// and as such has to rely on STL directly instead of //base alternatives.
#include <condition_variable>
#include <memory>
#include <mutex>
#include <queue>
#include <thread>

#include "third_party/fml/thread.h"
#include "third_party/ttnet/include/cronet_c.h"
namespace lynx {
// implementation of Cronet_Executor interface using static
// methods to map C API into instance of C++ class.
class TtnetExecutor {
 public:
  explicit TtnetExecutor();

  ~TtnetExecutor();
  // Gets Cronet_ExecutorPtr implemented by |this|.
  Cronet_Executor* GetExecutor() const { return executor_; }

 private:
  // Adds |runnable| to |task_queue_| to execute on |executor_thread_|.
  void Execute(Cronet_Runnable* runnable);

  // Implementation of Cronet_Executor methods.
  static void Execute(Cronet_Executor* self, Cronet_Runnable* runnable);
  fml::Thread net_thread_;
  Cronet_Executor* const executor_ = nullptr;
};
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_NET_TTNET_EXECUTOR_H_
