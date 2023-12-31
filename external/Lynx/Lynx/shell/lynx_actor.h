// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_LYNX_ACTOR_H_
#define LYNX_SHELL_LYNX_ACTOR_H_

#include <memory>
#include <string>
#include <utility>

#include "third_party/fml/task_runner.h"

namespace lynx {
namespace shell {

template <typename C, typename T, typename Enable = void>
class LynxActorMixin {
 protected:
  void BeforeInvoked() {}

  void AfterInvoked() {}
};

// actor for each thread
template <typename T>
class LynxActor : public LynxActorMixin<LynxActor<T>, T>,
                  public std::enable_shared_from_this<LynxActor<T>> {
 public:
  LynxActor(std::unique_ptr<T> impl, fml::RefPtr<fml::TaskRunner> runner,
            bool enable = true)
      : impl_(std::move(impl)), runner_(std::move(runner)), enable_(enable) {}
  ~LynxActor() { DCHECK(impl_ == nullptr); }

  template <typename F>
  void Act(F&& func) {
    if (!enable_) {
      return;
    }
    if (runner_->RunsTasksOnCurrentThread()) {
      Invoke(std::forward<F>(func));
    } else {
      runner_->PostTask([self = this->shared_from_this(),
                         func = std::forward<F>(func)]() mutable {
        self->Invoke(std::forward<F>(func));
      });
    }
  }

  template <typename F>
  void ActAsync(F&& func) {
    if (!enable_) {
      return;
    }

    runner_->PostTask([self = this->shared_from_this(),
                       func = std::forward<F>(func)]() mutable {
      self->Invoke(std::forward<F>(func));
    });
  }

  template <typename F, typename = std::enable_if_t<!std::is_void<
                            std::result_of_t<F(std::unique_ptr<T>&)>>::value>>
  auto ActSync(F&& func) {
    std::result_of_t<F(std::unique_ptr<T>&)> result;
    ActSync([&result, func = std::forward<F>(func)](auto& impl) mutable {
      result = func(impl);
    });
    return result;
  }

  template <typename F, typename = std::enable_if_t<std::is_void<
                            std::result_of_t<F(std::unique_ptr<T>&)>>::value>>
  void ActSync(F&& func) {
    if (!enable_) {
      return;
    }
    runner_->PostSyncTask([this, func = std::forward<F>(func)]() mutable {
      Invoke(std::forward<F>(func));
    });
  }

  // TODO(heshan):now use for LynxRuntime, will remove,
  // now need for devtool...
  T* Impl() { return impl_.get(); }
  // TODO(lipin): now use for LayoutMediator,maybe remove later
  bool CanRunNow() { return runner_->RunsTasksOnCurrentThread(); }

 private:
  template <typename F>
  void Invoke(F&& func) {
    LynxActorMixin<LynxActor<T>, T>::BeforeInvoked();

    if (impl_ != nullptr) {
      func(impl_);
    }

    LynxActorMixin<LynxActor<T>, T>::AfterInvoked();
  }

  std::unique_ptr<T> impl_;

  fml::RefPtr<fml::TaskRunner> runner_;

  bool enable_ = true;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_LYNX_ACTOR_H_
