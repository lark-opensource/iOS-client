// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_BASE_THREAD_ASSERT_H_
#define ANIMAX_BASE_THREAD_ASSERT_H_

#include <cstdint>

namespace lynx {
namespace animax {
class ThreadAssert final {
 public:
  enum class Type : uint8_t {
    kUnknown = 0,
    kGPU,
    kJS,
  };
  static void Init(const Type type);
  static void Assert(const Type type);

 private:
  static Type *Get();
};
}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_BASE_THREAD_ASSERT_H_
