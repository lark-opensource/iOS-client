// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_REF_H_
#define LYNX_KRYPTON_AURUM_REF_H_

#include "aurum/config.h"

namespace lynx {
namespace canvas {
namespace au {

template <typename T>
class Ref {
 public:
  inline Ref(Ref &ref) {
    AU_LOCK(ref.value_lock_);
    if (ref.value_) {
      Reset(ref.value_);
    }
    AU_UNLOCK(ref.value_lock_);
  }

  inline Ref() {}
  inline ~Ref() { Reset(); }
  inline T *Get() { return value_; }
  inline T *operator->() { return value_; }

  inline void Reset() {
    AU_LOCK(value_lock_);
    if (value_) {
      value_->UnRef();
    }
    value_ = nullptr;
    AU_UNLOCK(value_lock_);
  }

  inline void Reset(T *p) {
    AU_LOCK(value_lock_);
    if (value_) {
      value_->UnRef();
    }
    p->Ref();
    value_ = p;
    AU_UNLOCK(value_lock_);
  }

 private:
  T *value_ = nullptr;
  int value_lock_ = 0;
};

}  // namespace au
}  // namespace canvas
}  // namespace lynx

#endif  // LYNX_KRYPTON_AURUM_REF_H_
