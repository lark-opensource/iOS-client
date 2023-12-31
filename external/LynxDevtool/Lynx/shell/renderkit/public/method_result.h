// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_METHOD_RESULT_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_METHOD_RESULT_H_
#include <vector>

#include "lynx_export.h"

namespace lynx {
class EncodableValue;
using EncodableList = std::vector<EncodableValue>;

// called on any given instance.
class LYNX_EXPORT MethodResult {
 public:
  MethodResult() = default;
  virtual ~MethodResult() = default;
  // Prevent copying.
  MethodResult(MethodResult const&) = delete;
  MethodResult& operator=(MethodResult const&) = delete;
  virtual void Result(const EncodableList& result) = 0;
};

}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_METHOD_RESULT_H_
