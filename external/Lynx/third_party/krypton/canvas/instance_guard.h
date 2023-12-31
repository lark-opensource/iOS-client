// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_INSTANCE_GUARD_H_
#define CANVAS_INSTANCE_GUARD_H_

#include <memory>

/**
 * Used to monitor Object has released or not
 */
template <class T>
class InstanceGuard {
 public:
  InstanceGuard(T* ptr) : ptr_(ptr) {}
  static std::shared_ptr<InstanceGuard> CreateSharedGuard(T* ptr) {
    return std::make_shared<InstanceGuard>(ptr);
  }
  T* Get() { return ptr_; }

 private:
  T* ptr_;
};

#endif  // CANVAS_INSTANCE_GUARD_H_
