// Copyright 2023 The Lynx Authors. All rights reserved.

#include "base/threading/thread_merger.h"

#include "base/trace_event/trace_event.h"
#include "third_party/fml/message_loop_task_queues.h"
#include "third_party/fml/synchronization/waitable_event.h"

namespace lynx {
namespace base {

ThreadMerger::ThreadMerger(fml::TaskRunner* owner, fml::TaskRunner* subsumed)
    : owner_(owner), subsumed_(subsumed) {
  TRACE_EVENT("lynx", "ThreadMerger.create");
  DCHECK(owner_);
  DCHECK(subsumed_);

  if (owner_ == subsumed_) {
    return;
  }

  // ensure on owner's thread.
  DCHECK(owner_->RunsTasksOnCurrentThread());

  fml::AutoResetWaitableEvent arwe;
  subsumed_->PostEmergencyTask([owner_id = owner_->GetTaskQueueId(),
                                subsumed_id = subsumed_->GetTaskQueueId(),
                                &arwe]() {
    fml::MessageLoopTaskQueues::GetInstance()->Merge(owner_id, subsumed_id);
    arwe.Signal();
  });
  arwe.Wait();
}

ThreadMerger::~ThreadMerger() {
  TRACE_EVENT("lynx", "ThreadMerger.release");
  if (owner_ == subsumed_) {
    return;
  }

  // ensure on owner's thread.
  DCHECK(owner_->RunsTasksOnCurrentThread());

  fml::MessageLoopTaskQueues::GetInstance()->Unmerge(
      owner_->GetTaskQueueId(), subsumed_->GetTaskQueueId());
}

ThreadMerger::ThreadMerger(ThreadMerger&& other)
    : owner_(other.owner_), subsumed_(other.subsumed_) {
  other.owner_ = nullptr;
  other.subsumed_ = nullptr;
}

ThreadMerger& ThreadMerger::operator=(ThreadMerger&& other) {
  owner_ = other.owner_;
  subsumed_ = other.subsumed_;
  other.owner_ = nullptr;
  other.subsumed_ = nullptr;
  return *this;
}

}  // namespace base
}  // namespace lynx
