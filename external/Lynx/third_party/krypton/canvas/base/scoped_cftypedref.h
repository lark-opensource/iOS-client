//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_BASE_SCOPED_CFTYPEDREF_H_
#define CANVAS_BASE_SCOPED_CFTYPEDREF_H_

#include <CoreFoundation/CoreFoundation.h>

namespace lynx {
namespace canvas {

template <typename CFT>
class ScopedCFTypeRef {
 public:
  ScopedCFTypeRef() : ref_(nullptr) {}

  ScopedCFTypeRef(CFT ref, bool has_ownership) : ref_(ref) {
    if (!has_ownership) {
      CFRetain(ref_);
    }
  }

  ScopedCFTypeRef(ScopedCFTypeRef<CFT> &&other) {
    ref_ = other.ref_;
    other.ref_ = nullptr;
  }

  ScopedCFTypeRef &operator=(ScopedCFTypeRef<CFT> &&other) {
    ref_ = other.ref_;
    other.ref_ = nullptr;
    return *this;
  }

  operator CFT() const { return ref_; }

  ~ScopedCFTypeRef() {
    if (ref_) {
      CFRelease(ref_);
    }
  }

 private:
  CFT ref_;

  ScopedCFTypeRef(const ScopedCFTypeRef<CFT> &) = delete;
  ScopedCFTypeRef &operator=(const ScopedCFTypeRef<CFT> &) = delete;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_BASE_SCOPED_CFTYPEDREF_H_
