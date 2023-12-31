// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_LYNX_RUNTIME_ACTOR_HOLDER_H_
#define LYNX_SHELL_LYNX_RUNTIME_ACTOR_HOLDER_H_

#include <list>
#include <memory>
#include <mutex>
#include <unordered_map>

#include "base/no_destructor.h"
#include "jsbridge/runtime/lynx_runtime.h"
#include "shell/lynx_actor.h"
namespace lynx {

namespace shell {

/*
 * When LynxShell::Destroy() be called, lynx_runtime actor in lynx_shell will be
 * put in this holder. This holder will hold lynx_runtime actor until ths JSB
 * task called in onDestroy() done.
 */
class LynxRuntimeActorHolder {
  friend class base::NoDestructor<LynxRuntimeActorHolder>;

 public:
  ~LynxRuntimeActorHolder() = default;
  LynxRuntimeActorHolder(const LynxRuntimeActorHolder&) = delete;
  LynxRuntimeActorHolder& operator=(const LynxRuntimeActorHolder&) = delete;
  LynxRuntimeActorHolder(LynxRuntimeActorHolder&&) = delete;
  LynxRuntimeActorHolder& operator=(LynxRuntimeActorHolder&&) = delete;

  static LynxRuntimeActorHolder* GetInstance() {
    static base::NoDestructor<LynxRuntimeActorHolder> sLynxRuntimeActorHolder;
    return sLynxRuntimeActorHolder.get();
  }

  using LynxRuntimeActor = std::shared_ptr<LynxActor<runtime::LynxRuntime>>;

  void Hold(LynxRuntimeActor);

  void PostDelayedRelease(int64_t);

  void Release(int64_t runtime_id);

 private:
  LynxRuntimeActorHolder()
      : js_runner_(base::TaskRunnerManufactor::GetJSRunner()) {}

  void ReleaseInternal(int64_t runtime_id);

  fml::RefPtr<fml::TaskRunner> js_runner_;

  std::mutex mutex_;

  std::unordered_map<int64_t, LynxRuntimeActor> runtime_actor_container_;

  static constexpr int64_t kReleaseDelayedTime = 2000;  // ms
};

}  // namespace shell
}  // namespace lynx
#endif  // LYNX_SHELL_LYNX_RUNTIME_ACTOR_HOLDER_H_
