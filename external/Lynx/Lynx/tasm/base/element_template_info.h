// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_BASE_ELEMENT_TEMPLATE_INFO_H_
#define LYNX_TASM_BASE_ELEMENT_TEMPLATE_INFO_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "css/css_property.h"
#include "lepus/value.h"
#include "tasm/template_binary.h"

namespace lynx {
namespace tasm {

// Event Info
struct ElementEventInfo {
  // event type
  std::string type_{};
  // event name
  std::string name_{};
  // event value
  std::string value_{};
};

// Element Info
struct ElementInfo {
  bool is_component_{false};

  // If the element is built-in type, the tag_enum_ will not be
  // ElementBuiltInTagEnum::ELEMENT_OTHER.
  ElementBuiltInTagEnum tag_enum_{ElementBuiltInTagEnum::ELEMENT_OTHER};

  // Element's tag selector
  std::string tag_;
  // Element's id selector
  std::string id_selector_;
  // Element's class selector
  std::vector<std::string> class_selector_;
  // Element's inline style
  std::unordered_map<CSSPropertyID, std::string> inline_styles_;
  // Element's attribute
  std::unordered_map<std::string, lepus::Value> attrs_;
  // Element's dataset
  lepus::Value data_set_{};
  // Element's events
  std::vector<ElementEventInfo> events_;

  // Flag used to mark whether there is a parsed style
  bool has_parser_style_{false};
  std::string parser_style_key_;
  StyleMap parser_style_map_{};

  // Element's children info
  std::vector<std::shared_ptr<ElementInfo>> children_;

  // config
  lepus::Value config_{};
};

struct ElementTemplateInfo {
  bool exist_{false};
  std::string key_;
  std::vector<std::shared_ptr<ElementInfo>> elements_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_BASE_ELEMENT_TEMPLATE_INFO_H_
