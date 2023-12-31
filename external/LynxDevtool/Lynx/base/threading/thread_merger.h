// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_THREADING_THREAD_MERGER_H_
#define LYNX_BASE_THREADING_THREAD_MERGER_H_

#include "third_party/fml/task_runner.h"

namespace lynx {
namespace base {

class ThreadMerger {
 public:
  ThreadMerger(fml::TaskRunner* owner, fml::TaskRunner* subsumed);
  ~ThreadMerger();

  ThreadMerger(const ThreadMerger&) = delete;
  ThreadMerger& operator=(const ThreadMerger&) = delete;
  ThreadMerger(ThreadMerger&&);
  ThreadMerger& operator=(ThreadMerger&&);

 private:
  fml::TaskRunner* owner_;

  fml::TaskRunner* subsumed_;
};

}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_THREADING_THREAD_MERGER_H_
