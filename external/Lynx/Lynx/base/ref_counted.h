// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LYNX_BASE_REF_COUNTED_H_
#define LYNX_BASE_REF_COUNTED_H_

#include <stddef.h>

#include <cassert>
#include <iosfwd>
#include <type_traits>
#include <utility>

#include "base/atomic_ref_count.h"
#include "base/log/logging.h"

namespace lynx {
namespace base {

template <class T>
class scoped_refptr;

template <typename T>
scoped_refptr<T> AdoptRef(T* t);

enum AdoptRefTag { kAdoptRefTag };

class RefCountedThreadSafeBase {
 public:
  bool HasOneRef() const { return ref_count_.IsOne(); }
  int SubtleRefCountForDebug() const {
    return ref_count_.SubtleRefCountForDebug();
  }

 protected:
  RefCountedThreadSafeBase() : ref_count_(1) {}

  virtual ~RefCountedThreadSafeBase() = default;

  bool Release() const { return ReleaseImpl(); }
  void AddRef() const { AddRefImpl(); }

 private:
  template <typename U>
  friend scoped_refptr<U> base::AdoptRef(U*);

  void Adopted() const {}

  void AddRefImpl() const { ref_count_.Increment(); }

  bool ReleaseImpl() const {
    if (!ref_count_.Decrement()) {
      return true;
    }
    return false;
  }

  mutable AtomicRefCount ref_count_{0};

  RefCountedThreadSafeBase(const RefCountedThreadSafeBase&) = delete;
  RefCountedThreadSafeBase& operator=(const RefCountedThreadSafeBase&) = delete;
};

class RefCountedThreadSafeStorage : public RefCountedThreadSafeBase {
 public:
  explicit RefCountedThreadSafeStorage() : RefCountedThreadSafeBase() {}
  ~RefCountedThreadSafeStorage() override = default;

  void AddRef() const { RefCountedThreadSafeBase::AddRef(); }

  void Release() const {
    if (RefCountedThreadSafeBase::Release()) {
      // ANALYZER_SKIP_THIS_PATH();
      ReleaseSelf();
    }
  }

  virtual void ReleaseSelf() const = 0;
};
// Creates a scoped_refptr from a raw pointer without incrementing the reference
// count. Use this only for a newly created object whose reference count starts
// from 1 instead of 0.
template <typename T>
scoped_refptr<T> AdoptRef(T* obj) {
  DCHECK(obj);
  DCHECK(obj->HasOneRef());
  obj->Adopted();
  return scoped_refptr<T>(obj, kAdoptRefTag);
}

template <typename T>
scoped_refptr<T> AdoptRefIfNeeded(T* obj) {
  return AdoptRef(obj);
}

// Constructs an instance of T, which is a ref counted type, and wraps the
// object into a scoped_refptr.
template <typename T, typename... Args>
scoped_refptr<T> MakeRefCounted(Args&&... args) {
  T* obj = new T(std::forward<Args>(args)...);
  return AdoptRefIfNeeded(obj);
}

template <class T>
class scoped_refptr {
 public:
  typedef T element_type;

  scoped_refptr() : ptr_(nullptr) {}

  scoped_refptr(T* p) : ptr_(p) {
    if (ptr_) AddRef(ptr_);
  }

  // Copy constructor.
  scoped_refptr(const scoped_refptr<T>& r) : ptr_(r.ptr_) {
    if (ptr_) AddRef(ptr_);
  }

  // Copy conversion constructor.
  template <typename U, typename = typename std::enable_if<
                            std::is_convertible<U*, T*>::value>::type>
  scoped_refptr(const scoped_refptr<U>& r) : ptr_(r.Get()) {
    if (ptr_) AddRef(ptr_);
  }

  // Move constructor. This is required in addition to the conversion
  // constructor below in order for clang to warn about pessimizing moves.
  scoped_refptr(scoped_refptr&& r) : ptr_(r.Get()) { r.ptr_ = nullptr; }

  // Move conversion constructor.
  template <typename U, typename = typename std::enable_if<
                            std::is_convertible<U*, T*>::value>::type>
  scoped_refptr(scoped_refptr<U>&& r) : ptr_(r.Get()) {
    r.ptr_ = nullptr;
  }

  ~scoped_refptr() {
    if (ptr_) Release(ptr_);
  }

  T* Get() const { return ptr_; }

  T& operator*() const {
    DCHECK(ptr_ != nullptr);
    return *ptr_;
  }

  T* operator->() const {
    DCHECK(ptr_ != nullptr);
    return ptr_;
  }

  scoped_refptr<T>& operator=(T* p) {
    // AddRef first so that self assignment should work
    if (p) AddRef(p);
    T* old_ptr = ptr_;
    ptr_ = p;
    if (old_ptr) Release(old_ptr);
    return *this;
  }

  scoped_refptr<T>& operator=(const scoped_refptr<T>& r) {
    return *this = r.ptr_;
  }

  template <typename U>
  scoped_refptr<T>& operator=(const scoped_refptr<U>& r) {
    return *this = r.Get();
  }

  scoped_refptr<T>& operator=(scoped_refptr<T>&& r) {
    scoped_refptr<T> tmp(std::move(r));
    tmp.swap(*this);
    return *this;
  }

  template <typename U>
  scoped_refptr<T>& operator=(scoped_refptr<U>&& r) {
    // We swap with a temporary variable to guarantee that |ptr_| is released
    // immediately. A naive implementation which swaps |this| and |r| would
    // unintentionally extend the lifetime of |ptr_| to at least the lifetime of
    // |r|.

    scoped_refptr<T> tmp(std::move(r));

    tmp.swap(*this);

    return *this;
  }

  void swap(scoped_refptr<T>& r) {
    T* tmp = ptr_;
    ptr_ = r.ptr_;
    r.ptr_ = tmp;
  }

  explicit operator bool() const { return ptr_ != nullptr; }

  template <typename U>
  bool operator==(const scoped_refptr<U>& rhs) const {
    return ptr_ == rhs.Get();
  }

  template <typename U>
  bool operator!=(const scoped_refptr<U>& rhs) const {
    return !operator==(rhs);
  }

  template <typename U>
  bool operator<(const scoped_refptr<U>& rhs) const {
    return ptr_ < rhs.Get();
  }

 protected:
  T* ptr_ = nullptr;

 private:
  template <typename U>
  friend scoped_refptr<U> base::AdoptRef(U*);

  scoped_refptr(T* p, AdoptRefTag) : ptr_(p) {}

  // Friend required for move constructors that set r.ptr_ to null.
  template <typename U>
  friend class scoped_refptr;

  // Non-inline helpers to allow:
  //     class Opaque;
  //     extern template class scoped_refptr<Opaque>;
  // Otherwise the compiler will complain that Opaque is an incomplete type.
  //  void AddRef(T* ptr);
  // static void Release(T* ptr);

  // static

  static void AddRef(T* ptr) { ptr->AddRef(); }

  // static
  static void Release(T* ptr) { ptr->Release(); }
};

// Handy utility for creating a scoped_refptr<T> out of a T* explicitly without
// having to retype all the template arguments
template <typename T>
scoped_refptr<T> make_scoped_refptr(T* t) {
  return scoped_refptr<T>(t);
}

template <typename T, typename U>
bool operator==(const scoped_refptr<T>& lhs, const U* rhs) {
  return lhs.Get() == rhs;
}

template <typename T, typename U>
bool operator==(const T* lhs, const scoped_refptr<U>& rhs) {
  return lhs == rhs.Get();
}

template <typename T>
bool operator==(const scoped_refptr<T>& lhs, std::nullptr_t null) {
  return !static_cast<bool>(lhs);
}

template <typename T>
bool operator==(std::nullptr_t null, const scoped_refptr<T>& rhs) {
  return !static_cast<bool>(rhs);
}

template <typename T, typename U>
bool operator!=(const scoped_refptr<T>& lhs, const U* rhs) {
  return !operator==(lhs, rhs);
}

template <typename T, typename U>
bool operator!=(const T* lhs, const scoped_refptr<U>& rhs) {
  return !operator==(lhs, rhs);
}

template <typename T>
bool operator!=(const scoped_refptr<T>& lhs, std::nullptr_t null) {
  return !operator==(lhs, null);
}

template <typename T>
bool operator!=(std::nullptr_t null, const scoped_refptr<T>& rhs) {
  return !operator==(null, rhs);
}

template <typename T>
std::ostream& operator<<(std::ostream& out, const scoped_refptr<T>& p) {
  return out << p.Get();
}

}  // namespace base
}  // namespace lynx

namespace std {
template <class T>
struct hash<lynx::base::scoped_refptr<T>> {
  std::size_t operator()(const lynx::base::scoped_refptr<T>& k) const {
    std::hash<void*> hash_init;
    return hash_init(k.Get());
  }
};
}  // namespace std

#endif  // LYNX_BASE_REF_COUNTED_H_
