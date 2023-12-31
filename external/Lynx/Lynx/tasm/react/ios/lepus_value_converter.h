// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_IOS_LEPUS_VALUE_CONVERTER_H_
#define LYNX_TASM_REACT_IOS_LEPUS_VALUE_CONVERTER_H_

#include "lepus/value-inl.h"

namespace lynx {
namespace tasm {

extern id convertLepusValueToNSObject(const lepus_value &value);

}
}  // namespace lynx

#endif  // LYNX_TASM_REACT_IOS_LEPUS_VALUE_CONVERTER_H_
