// Copyright 2023 The Lynx Authors. All rights reserved.
#ifndef LYNX_LEPUS_LEPUS_ERROR_HELPER_H_
#define LYNX_LEPUS_LEPUS_ERROR_HELPER_H_

#include <iostream>
#include <string>

#include "base/log/logging.h"
#include "lepus/context.h"

namespace lynx {
namespace lepus {
class LepusErrorHelper {
 public:
  static std::string GetErrorStack(LEPUSContext* ctx, LEPUSValue& value);

  static std::string GetErrorMessage(LEPUSContext* ctx,
                                     LEPUSValue& exception_value);
};
}  // namespace lepus
}  // namespace lynx

#endif  // LYNX_LEPUS_LEPUS_ERROR_HELPER_H_
