// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_UPVALUE_H_
#define LYNX_LEPUS_UPVALUE_H_

#include "base/ref_counted_ptr.h"
#include "lepus/lepus_string.h"

namespace lynx {
namespace lepus {
struct UpvalueInfo {
  lynx::base::scoped_refptr<StringImpl> name_;
  long register_;
  bool in_parent_vars_;

  UpvalueInfo(lynx::base::scoped_refptr<StringImpl> name, long register_id,
              bool in_parent_vars)
      : name_(name), register_(register_id), in_parent_vars_(in_parent_vars) {
    // name_->AddRef();
  }

  ~UpvalueInfo() {
    // name_->Release();
  }
};
}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_UPVALUE_H_
