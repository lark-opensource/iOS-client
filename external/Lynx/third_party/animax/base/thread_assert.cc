// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/base/thread_assert.h"

#include "animax/base/log.h"

namespace lynx {
namespace animax {

ThreadAssert::Type *ThreadAssert::Get() {
  static thread_local Type type;
  return &type;
}

void ThreadAssert::Init(const Type type) { *Get() = type; }

void ThreadAssert::Assert(const Type type) { DCHECK(*Get() == type); }

}  // namespace animax
}  // namespace lynx
