// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_CLOSURE_H_
#define LYNX_BASE_CLOSURE_H_

#include <cstddef>
#include <type_traits>
#include <utility>

namespace lynx {
namespace base {

template <typename Ret, typename... Args>
class ClosureBase {
 public:
  ClosureBase() = default;
  virtual ~ClosureBase() = default;
  virtual Ret operator()(Args...) = 0;

  ClosureBase(const ClosureBase&) = delete;
  ClosureBase& operator=(const ClosureBase&) = delete;
  ClosureBase(ClosureBase&&) = default;
  ClosureBase& operator=(ClosureBase&&) = default;
};

template <typename F, typename Ret, typename... Args>
class ClosureImpl : public ClosureBase<Ret, Args...> {
 public:
  explicit ClosureImpl(F&& func) : func_(std::move(func)) {}
  ~ClosureImpl() override = default;

  Ret operator()(Args... arguments) override {
    return func_(std::forward<Args>(arguments)...);
  }

  ClosureImpl(const ClosureImpl&) = delete;
  ClosureImpl& operator=(const ClosureImpl&) = delete;
  ClosureImpl(ClosureImpl&&) = default;
  ClosureImpl& operator=(ClosureImpl&&) = default;

 private:
  F func_;
};

template <typename Ret = void, typename... Args>
class MoveOnlyClosure {
 public:
  MoveOnlyClosure() : impl_(nullptr) {}
  MoveOnlyClosure(std::nullptr_t) : impl_(nullptr) {}

  template <typename F, typename = std::enable_if_t<
                            std::is_invocable_r_v<Ret, F, Args...> &&
                            !std::is_same_v<std::decay_t<F>, MoveOnlyClosure>>>
  MoveOnlyClosure(F&& func)
      : impl_(new ClosureImpl<F, Ret, Args...>(std::move(func))) {}
  ~MoveOnlyClosure() { delete impl_; }

  // Here we delete the constructor with lvalue
  // to avoid usage like:
  //   auto task = []() {};
  //   runtime_task_runner()->PostTask(task);
  // which passing a lvalue reference to construct a MoveOnlyClosure.
  //
  // This actually does not compile since ClosureImpl requires a rvalue.
  // But explicitly deletion will give more readable error message like:
  //   conversion function from '(lambda at closure_unittest.cc:165:12)' to
  //   'base::closure' (aka 'MoveOnlyClosure<>') invokes a deleted function
  //   note: 'MoveOnlyClosure<(lambda at closure_unittest.cc:165:12)>' has been
  //   explicitly marked deleted here MoveOnlyClosure(F&) = delete;
  //                                  ^
  // Without this, the error message will look like:
  //   no matching constructor for initialization of
  //   'ClosureImpl<CopyableLambda<(lambda at foo.cc:10:28)> &, void>'
  template <typename F>
  MoveOnlyClosure(F&) = delete;
  MoveOnlyClosure(const MoveOnlyClosure&) = delete;
  MoveOnlyClosure& operator=(const MoveOnlyClosure&) = delete;

  MoveOnlyClosure(MoveOnlyClosure&& other) {
    impl_ = other.impl_;
    other.impl_ = nullptr;
  }

  MoveOnlyClosure& operator=(MoveOnlyClosure&& other) {
    delete impl_;
    impl_ = other.impl_;
    other.impl_ = nullptr;
    return *this;
  }

  MoveOnlyClosure& operator=(std::nullptr_t) {
    delete impl_;
    impl_ = nullptr;
    return *this;
  }

  Ret operator()(Args... arguments) const {
    return (*impl_)(std::forward<Args>(arguments)...);
  }

  explicit operator bool() const { return impl_ != nullptr; }

  bool operator==(std::nullptr_t) const { return impl_ == nullptr; }

  bool operator!=(std::nullptr_t) const { return impl_ != nullptr; }

 private:
  ClosureBase<Ret, Args...>* impl_;
};

using closure = base::MoveOnlyClosure<>;

}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_CLOSURE_H_
