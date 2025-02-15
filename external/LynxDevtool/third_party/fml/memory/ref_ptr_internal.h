// Copyright 2013 The Flutter Authors. All rights reserved.
// Copyright 2022 The Lynx Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_FLUTTER_FML_MEMORY_REF_PTR_INTERNAL_H_
#define THIRD_PARTY_FLUTTER_FML_MEMORY_REF_PTR_INTERNAL_H_

#include <utility>

#include "third_party/fml/macros.h"

namespace lynx {
namespace fml {

template <typename T>
class RefPtr;

template <typename T>
RefPtr<T> AdoptRef(T* ptr);

namespace internal {

// This is a wrapper class that can be friended for a particular |T|, if you
// want to make |T|'s constructor private, but still use |MakeRefCounted()|
// (below). (You can't friend partial specializations.) See |MakeRefCounted()|
// and |FML_FRIEND_MAKE_REF_COUNTED()|.
template <typename T>
class MakeRefCountedHelper final {
 public:
  template <typename... Args>
  static RefPtr<T> MakeRefCounted(Args&&... args) {
    return AdoptRef<T>(new T(std::forward<Args>(args)...));
  }
};

}  // namespace internal
}  // namespace fml
}  // namespace lynx

#endif  // THIRD_PARTY_FLUTTER_FML_MEMORY_REF_PTR_INTERNAL_H_
