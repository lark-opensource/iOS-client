// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_COMPONENT_ATTRIBUTES_H_
#define LYNX_TASM_COMPONENT_ATTRIBUTES_H_

#include <set>
#include <string>

#include "base/no_destructor.h"

namespace lynx {
namespace tasm {

class ComponentAttributes {
 public:
  static const std::set<std::string>& GetAttrNames();
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_COMPONENT_ATTRIBUTES_H_
