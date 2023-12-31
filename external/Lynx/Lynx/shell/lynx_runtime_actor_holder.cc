// Copyright 2021 The Lynx Authors. All rights reserved.

#include "shell/lynx_runtime_actor_holder.h"

#include "base/log/logging.h"

namespace lynx {
namespace shell {

void LynxRuntimeActorHolder::Hold(LynxRuntimeActor lynx_runtime_actor) {
  // This function must run in js thread!
  DCHECK(js_runner_->RunsTasksOnCurrentThread());
  {
    std::lock_guard<std::mutex> lock(mutex_);
    runtime_actor_container_.emplace(lynx_runtime_actor->Impl()->GetRuntimeId(),
                                     lynx_runtime_actor);
  }
}

void LynxRuntimeActorHolder::PostDelayedRelease(int64_t runtime_id) {
  // This function must run in js thread!
  DCHECK(js_runner_->RunsTasksOnCurrentThread());
  js_runner_->PostDelayedTask(
      [this, runtime_id]() { ReleaseInternal(runtime_id); },
      fml::TimeDelta::FromMilliseconds(kReleaseDelayedTime));
}

void LynxRuntimeActorHolder::Release(int64_t runtime_id) {
  // This function must run in js thread!
  DCHECK(js_runner_->RunsTasksOnCurrentThread());
  ReleaseInternal(runtime_id);
}

void LynxRuntimeActorHolder::ReleaseInternal(int64_t runtime_id) {
  // This function must run in js thread!
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = runtime_actor_container_.find(runtime_id);
  if (it != runtime_actor_container_.end()) {
    (it->second)->Act([](auto& runtime) { runtime = nullptr; });
    runtime_actor_container_.erase(runtime_id);
  }
}

}  // namespace shell
}  // namespace lynx
