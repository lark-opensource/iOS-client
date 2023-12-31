// Copyright 2020 The Lynx Authors. All rights reserved.

#include "tasm/list_component_info.h"

#include "tasm/value_utils.h"

namespace lynx {
namespace tasm {

constexpr static const char kListItemKey[] = "item-key";
constexpr static const char kListStickyTop[] = "sticky-top";
constexpr static const char kListStickyBottom[] = "sticky-bottom";
constexpr static const char kListEstimatedHeight[] = "estimated-height";
constexpr static const char kListEstimatedHeightPx[] = "estimated-height-px";
constexpr static double kListEstimatedHeightInvalid = -1.;
constexpr static const char kDistanceFromRoot[] = "distanceFromRoot";

bool operator==(const ListComponentInfo& lhs, const ListComponentInfo& rhs) {
  return (lhs.diff_key_ == rhs.diff_key_) && (lhs.name_ == rhs.name_) &&
         (lhs.ids_ == rhs.ids_) && (lhs.style_ == rhs.style_) &&
         (lhs.clazz_ == rhs.clazz_) && (lhs.event_ == rhs.event_) &&
         (lhs.data_.IsEqual(rhs.data_)) && (lhs.dataset_ == rhs.dataset_) &&
         (lhs.list_component_dispatch_option_ ==
          rhs.list_component_dispatch_option_) &&
         (lhs.IsEqualWithoutPropsId(rhs));
}

bool operator!=(const ListComponentInfo& lhs, const ListComponentInfo& rhs) {
  return !(lhs == rhs);
}

bool ListComponentInfo::IsEqualWithoutPropsId(
    const ListComponentInfo& rhs) const {
  if (properties_.GetLength() != rhs.properties_.GetLength()) {
    return false;
  }

  bool res{true};
  lepus::Value props_id{"propsId"};
  const auto& props_id_str{props_id.String()};
  ForEachLepusValue(properties_,
                    [&rhs, &res, &props_id_str](const lepus::Value& key,
                                                const lepus::Value& val) {
                      if (!res) return;

                      const auto& key_str{key.String()};

                      if ((key_str && props_id_str) &&
                          !(*(key_str.Get()) == *(props_id_str.Get())) &&
                          val != rhs.properties_.GetProperty(key_str)) {
                        res = false;
                      }
                    });

  return res;
}

ListComponentInfo::ListComponentInfo(std::string name,
                                     std::string current_entry,
                                     lepus::Value data, lepus::Value properties,
                                     lepus::Value ids, lepus::Value style,
                                     lepus::Value clazz, lepus::Value event,
                                     lepus::Value dataset,
                                     lepus::Value comp_type)
    : current_entry_(current_entry),
      diff_key_{lepus::StringImpl::Create(name)},
      estimated_height_{kListEstimatedHeightInvalid},
      estimated_height_px_{kListEstimatedHeightInvalid},
      name_(name),
      data_(data),
      properties_(properties),
      ids_(ids),
      style_(style),
      clazz_(clazz),
      event_(event),
      dataset_(dataset),
      lepus_name_{lepus::StringImpl::Create(name)} {
  // extract the item-key from props if available
  // otherwise, use component name as item-key
  if (properties.Contains(kListItemKey)) {
    auto item_key = properties.GetProperty(kListItemKey);
    if (item_key.IsString() && !item_key.String()->empty()) {
      diff_key_ = item_key;
    }
  }

  if (properties.Contains(kListEstimatedHeight)) {
    auto estimated_height = properties.GetProperty(kListEstimatedHeight);
    if (estimated_height.IsNumber()) {
      estimated_height_ = estimated_height.Number();
    }
  }
  if (properties.Contains(kListEstimatedHeightPx)) {
    auto estimated_height_px = properties.GetProperty(kListEstimatedHeightPx);
    if (estimated_height_px.IsNumber()) {
      estimated_height_px_ = estimated_height_px.Number();
    }
  }

  if (comp_type.String()->IsEqual("header")) {
    type_ = ListComponentInfo::Type::HEADER;
  } else if (comp_type.String()->IsEqual("footer")) {
    type_ = ListComponentInfo::Type::FOOTER;
  } else if (comp_type.String()->IsEqual("list-row")) {
    type_ = ListComponentInfo::Type::LIST_ROW;
  } else {
    type_ = ListComponentInfo::Type::DEFAULT;
  }
  lepus_type_ = lepus::Value(static_cast<int32_t>(type_));

  // check the "sticky" props for non-DEFAULT items
  stick_top_ = false;
  stick_bottom_ = false;
  if (type_ != ListComponentInfo::Type::DEFAULT) {
    if (properties_.Contains(kListStickyTop)) {
      auto value = properties_.GetProperty(kListStickyTop);
      stick_top_ = value.IsTrue();
    }
    if (properties_.Contains(kListStickyBottom)) {
      auto value = properties_.GetProperty(kListStickyBottom);
      stick_bottom_ = value.IsTrue();
    }
  }

  if (properties.Contains(kDistanceFromRoot)) {
    distance_from_root_ = properties_.GetProperty(kDistanceFromRoot).Number();
  }

  lepus_estimated_height_ = lepus::Value(estimated_height_);
  lepus_estimated_height_px_ = lepus::Value(estimated_height_px_);
  lepus_sticky_top_ = lepus::Value(stick_top_);
  lepus_sticky_bottom_ = lepus::Value(stick_bottom_);
}

bool ListComponentInfo::CanBeReusedBy(const ListComponentInfo& rhs) const {
  return diff_key_ == rhs.diff_key_;
}
}  // namespace tasm
}  // namespace lynx
