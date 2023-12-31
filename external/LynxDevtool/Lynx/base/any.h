// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_ANY_H_
#define LYNX_BASE_ANY_H_

#include <utility>

namespace lynx {
namespace base {

struct base_holder {
  base_holder() = default;
  base_holder(const base_holder&) = delete;
  base_holder& operator=(const base_holder&) = delete;
  virtual ~base_holder() {}
  virtual base_holder* clone() const = 0;
};

template <typename T>
struct holder : base_holder {
  holder(T t) : value(t) {}
  holder* clone() const override { return new holder<T>(value); }
  T value;
};

class any {
 public:
  // type erasure by this pointer
  base_holder* ptr = nullptr;

  any() {}
  ~any() { delete ptr; }

  template <typename T>
  any(T t) : ptr(new holder<T>(t)) {}

  any(const any& a) : ptr(a.ptr->clone()) {}
  any(any&& a) { std::swap(ptr, a.ptr); }

  any& operator=(any a) {
    std::swap(ptr, a.ptr);
    return *this;
  }

  template <class T>
  friend T any_cast(any& a);
};

template <class T>
T any_cast(const any& a) {
  return static_cast<holder<T>*>(a.ptr)->value;
}

}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_ANY_H_
