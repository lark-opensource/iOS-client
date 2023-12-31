// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_BASE_TASM_UTILS_H_
#define LYNX_TASM_BASE_TASM_UTILS_H_

#include "lepus/value.h"

namespace lynx {
namespace tasm {

lepus::Value GenerateSystemInfo(const lepus::Value* config);

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_BASE_TASM_UTILS_H_
