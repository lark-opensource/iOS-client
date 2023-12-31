// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_VALUE_INL_H_
#define LYNX_LEPUS_VALUE_INL_H_

#include <cstring>
#include <string>
#include <vector>

#include "base/ref_counted.h"
#include "lepus/marco.h"
#include "lepus/value.h"

typedef lynx::lepus::Value lepus_value;

namespace lynx {
namespace lepus {
Value& Value::operator=(const Value& value) {
  Copy(value);
  return *this;
}

Value& Value::operator=(Value&& value) noexcept {
  if (this == &value) return *this;

  FreeValue();
  type_ = value.type_;
  val_uint64_t_ = value.val_uint64_t_;
  cell_ = value.cell_;

  value.type_ = Value_Nil;
  value.val_uint64_t_ = 0;
  value.cell_ = nullptr;
  return *this;
}

CFunction Value::Function() const {
  if (likely(type_ == Value_CFunction)) {
    return reinterpret_cast<CFunction>(Ptr());
  }
  return nullptr;
}

void Value::SetNil() {
  FreeValue();
  type_ = Value_Nil;
  val_ptr_ = nullptr;
}

void Value::SetUndefined() {
  FreeValue();
  this->type_ = Value_Undefined;
  this->val_ptr_ = nullptr;
}
}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_VALUE_INL_H_
