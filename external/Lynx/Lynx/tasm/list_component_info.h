// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_LIST_COMPONENT_INFO_H_
#define LYNX_TASM_LIST_COMPONENT_INFO_H_

#include <string>

#include "lepus/value.h"
#include "radon/radon_dispatch_option.h"

namespace lynx {
namespace tasm {

struct ListComponentInfo {
  enum class Type : uint32_t {
    DEFAULT = 0,
    HEADER = 1,
    FOOTER = 2,
    LIST_ROW = 3
  };

  constexpr static const char* const kListCompType = "list-comp-type";

  ListComponentInfo(std::string name, std::string current_entry,
                    lepus::Value data, lepus::Value properties,
                    lepus::Value ids, lepus::Value style, lepus::Value clazz,
                    lepus::Value event, lepus::Value dataset,
                    lepus::Value comp_type);

  friend bool operator==(const ListComponentInfo& lhs,
                         const ListComponentInfo& rhs);
  friend bool operator!=(const ListComponentInfo& lhs,
                         const ListComponentInfo& rhs);
  bool CanBeReusedBy(const ListComponentInfo& rhs) const;

  static bool IsRow(lepus::Value& value) {
    if (!value.IsNumber()) {
      return false;
    }
    uint32_t type = value.Number();
    return type == (uint32_t)Type::HEADER || type == (uint32_t)Type::FOOTER ||
           type == (uint32_t)Type::LIST_ROW;
  }

  bool IsEqualWithoutPropsId(const ListComponentInfo& rhs) const;

  std::string current_entry_;
  lepus::Value diff_key_;
  double estimated_height_;
  double estimated_height_px_;
  bool stick_top_;
  bool stick_bottom_;
  ListComponentDispatchOption list_component_dispatch_option_;
  std::string name_;
  lepus::Value data_;
  lepus::Value properties_;
  lepus::Value ids_;
  lepus::Value style_;
  lepus::Value clazz_;
  lepus::Value event_;
  lepus::Value dataset_;
  lepus::Value lepus_type_;
  lepus::Value lepus_name_;
  lepus::Value lepus_sticky_top_;
  lepus::Value lepus_sticky_bottom_;
  lepus::Value lepus_estimated_height_;
  lepus::Value lepus_estimated_height_px_;
  ListComponentInfo::Type type_;
  int distance_from_root_{0};
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_LIST_COMPONENT_INFO_H_
