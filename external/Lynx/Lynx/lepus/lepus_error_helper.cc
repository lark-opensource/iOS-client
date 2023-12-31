// Copyright 2023 The Lynx Authors. All rights reserved.
#include "lepus/lepus_error_helper.h"

namespace lynx {
namespace lepus {
std::string LepusErrorHelper::GetErrorStack(LEPUSContext* ctx,
                                            LEPUSValue& value) {
  std::string err;
  if (LEPUS_IsError(ctx, value) || LEPUS_IsException(value)) {
    LEPUSValue val = LEPUS_GetPropertyStr(ctx, value, "stack");
    if (!LEPUS_IsUndefined(val)) {
      const char* stack = LEPUS_ToCString(ctx, val);
      if (stack) {
        err.append(stack);
      }
      LEPUS_FreeCString(ctx, stack);
    }
    LEPUS_FreeValue(ctx, val);
  }
  return err;
}

std::string LepusErrorHelper::GetErrorMessage(LEPUSContext* ctx,
                                              LEPUSValue& exception_value) {
  auto str = LEPUS_ToCString(ctx, exception_value);
  std::string error_msg;
  if (str) {
    error_msg.append(str);
  }
  LEPUS_FreeCString(ctx, str);
  return error_msg;
}
}  // namespace lepus
}  // namespace lynx
