// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_TYPES_LAYOUT_ATTRIBUTE_H_
#define LYNX_STARLIGHT_TYPES_LAYOUT_ATTRIBUTE_H_

#include <string>
#include <unordered_map>

#include "lepus/value.h"

namespace lynx {
namespace starlight {

enum class LayoutAttribute {
  kScroll,
  kColumnCount,
  kListCompType,
};

using AttributesMap = std::unordered_map<LayoutAttribute, lepus::Value>;

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_TYPES_LAYOUT_ATTRIBUTE_H_
