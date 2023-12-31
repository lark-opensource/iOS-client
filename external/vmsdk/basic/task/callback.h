// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_TASK_CALLBACK_H_
#define VMSDK_BASE_TASK_CALLBACK_H_

#if GNU_SUPPORT || !OS_ANDROID
#include <stddef.h>

#include <tuple>
#include <type_traits>
#endif

#include <functional>
#include <memory>
#include <utility>

#include "basic/compiler_specific.h"

namespace vmsdk {
namespace general {

class Closure {
 public:
  Closure() : group_id_(0) {}
  Closure(uintptr_t group_id) : group_id_(group_id) {}

  virtual ~Closure() {}
  virtual void Run() {}
  uintptr_t GetGroupId() { return group_id_; }

 private:
  uintptr_t group_id_;
};

template <typename F>
class FunctionCallback2 : public Closure {
 public:
  FunctionCallback2(F &&func) : func_(std::move(func)) {}
  virtual ~FunctionCallback2() {}
  virtual void Run() override { func_(); }

 private:
  F func_;
};

class FunctionCallback : public Closure {
 public:
  FunctionCallback(std::function<void()> func) : func_(std::move(func)) {}
  FunctionCallback(std::function<void()> func, uintptr_t group_id)
      : Closure(group_id), func_(std::move(func)) {}
  virtual ~FunctionCallback() {}
  virtual void Run() override {
    if (func_) {
      func_();
    }
  }

 private:
  std::function<void()> func_;
};

template <typename F>
static ALLOW_UNUSED_TYPE Closure *Bind2(F &&func) {
  return new FunctionCallback2<F>(std::move(func));
}

static ALLOW_UNUSED_TYPE Closure *Bind(std::function<void()> func,
                                       uintptr_t group_id = 0) {
  return new FunctionCallback(std::move(func), group_id);
}

class CompletionCallback {
 public:
  virtual ~CompletionCallback() = default;

  virtual void Run(int arg) {}
  virtual bool IsNull() { return false; }
};

template <typename Type>
class CompletionOnceCallback : public CompletionCallback {
 public:
  typedef void (Type::*CallbackFunc)(int);

  CompletionOnceCallback() : callback_func_(nullptr), ptr_(nullptr) {}
  CompletionOnceCallback(CallbackFunc func, Type *ptr)
      : callback_func_(func), ptr_(ptr) {}

  virtual ~CompletionOnceCallback() override = default;

  void Run(int arg) override { (ptr_->*callback_func_)(arg); }

  bool IsNull() override { return ptr_ != nullptr; }

 private:
  CallbackFunc callback_func_;
  Type *ptr_;
};

template <typename Type>
class CompletionOnceCallback1 : public CompletionCallback {
 public:
  typedef void (Type::*CallbackFunc)(int, int);

  CompletionOnceCallback1() : callback_func_(nullptr), ptr_(nullptr) {}
  CompletionOnceCallback1(CallbackFunc func, Type *ptr, int arg1)
      : callback_func_(func), ptr_(ptr), arg1_(arg1) {}

  virtual ~CompletionOnceCallback1() override = default;

  void Run(int arg) override { (ptr_->*callback_func_)(arg1_, arg); }

  bool IsNull() override { return ptr_ != nullptr; }

 private:
  CallbackFunc callback_func_;
  Type *ptr_;
  int arg1_;
  std::unique_ptr<Closure> callback_;
};

}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_TASK_CALLBACK_H_
