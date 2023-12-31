// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_REF_COUNTED_PTR_H_
#define VMSDK_BASE_REF_COUNTED_PTR_H_

#include <stddef.h>

#include <utility>

#include "basic/atomic_ref_count.h"

namespace vmsdk {
namespace general {
template <class T>
class RefCountPtr {
 public:
  RefCountPtr() : ref_count_(0) {}
  virtual ~RefCountPtr() {}

  void AddRef() { ref_count_.Increment(); }

  void Release() {
    if (!ref_count_.Decrement()) {
      delete static_cast<T *>(this);
    }
  }

 private:
  mutable AtomicRefCount ref_count_;
  RefCountPtr(const RefCountPtr &) = delete;
  RefCountPtr &operator=(const RefCountPtr &) = delete;
};

template <class T>
class ScopedRefPtr {
 public:
  using type_name = T;

  ScopedRefPtr() : ptr_(NULL) {}
  explicit ScopedRefPtr(T *ptr) : ptr_(ptr) {
    if (ptr_) {
      ptr_->AddRef();
    }
  }

  // Copy constructor.
  ScopedRefPtr(const ScopedRefPtr<T> &r) : ptr_(r.ptr_) {
    if (ptr_) ptr_->AddRef();
  }

  // Copy conversion constructor.
  template <typename U>
  ScopedRefPtr(const ScopedRefPtr<U> &r) : ptr_(r.Get()) {
    if (ptr_) ptr_->AddRef();
  }

  // Move constructor. This is required in addition to the conversion
  // constructor below in order for clang to warn about pessimizing moves.
  ScopedRefPtr(ScopedRefPtr &&r) : ptr_(r.Get()) { r.ptr_ = nullptr; }

  // Move conversion constructor.
  template <typename U>
  ScopedRefPtr(ScopedRefPtr<U> &&r) : ptr_(r.Get()) {
    r.ptr_ = nullptr;
  }

  ~ScopedRefPtr() {
    if (ptr_) {
      ptr_->Release();
    }
  }

  ScopedRefPtr<T> &operator=(T *ptr) {
    if (ptr) {
      ptr->AddRef();
    }

    T *old_ptr = ptr_;

    ptr_ = ptr;

    if (old_ptr) {
      old_ptr->Release();
    }

    return *this;
  }

  ScopedRefPtr<T> &operator=(const ScopedRefPtr<T> &other) {
    return *this = other.ptr_;
  }

  template <typename U>
  ScopedRefPtr<T> &operator=(const ScopedRefPtr<U> &r) {
    return *this = r.Get();
  }

  ScopedRefPtr<T> &operator=(ScopedRefPtr<T> &&r) {
    ScopedRefPtr<T>(std::move(r)).Swap(*this);
    return *this;
  }

  template <typename U>
  ScopedRefPtr<T> &operator=(ScopedRefPtr<U> &&r) {
    ScopedRefPtr<T>(std::move(r)).Swap(*this);
    return *this;
  }

  void Swap(T **pp) {
    T *p = ptr_;
    ptr_ = *pp;
    *pp = p;
  }

  void Release() {
    if (ptr_) {
      ptr_->Release();
      ptr_ = nullptr;
    }
  }

  void Swap(ScopedRefPtr<T> &r) { Swap(&r.ptr_); }

  T *Get() const { return ptr_; }

  T &operator*() const { return *ptr_; }

  T *operator->() const { return ptr_; }

  template <typename U>
  bool operator==(const ScopedRefPtr<U> &rhs) const {
    return ptr_ == rhs.Get();
  }

  template <typename U>
  bool operator!=(const ScopedRefPtr<U> &rhs) const {
    return !operator==(rhs);
  }

  template <typename U>
  bool operator<(const ScopedRefPtr<U> &rhs) const {
    return ptr_ < rhs.Get();
  }

 private:
  T *ptr_;
};

}  // namespace general
}  // namespace vmsdk

#endif  // VMSDK_BASE_REF_COUNTED_PTR_H_
