// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_DYNAMIC_CSS_STYLES_MANAGER_H_
#define LYNX_TASM_REACT_DYNAMIC_CSS_STYLES_MANAGER_H_

#include <array>
#include <functional>
#include <map>
#include <optional>
#include <set>
#include <unordered_set>
#include <utility>

#include "css/css_property.h"
#include "css/css_value.h"
#include "starlight/style/computed_css_style.h"
#include "starlight/style/default_css_style.h"
#include "starlight/types/layout_configs.h"
#include "starlight/types/measure_context.h"
#include "tasm/react/dynamic_css_configs.h"
#include "tasm/react/dynamic_direction_styles_manager.h"

namespace lynx {
namespace tasm {

struct PseudoPlaceHolderStyles {
  std::optional<CSSValue> font_size_;
  std::optional<CSSValue> color_;
  std::optional<CSSValue> font_weight_;
  std::optional<CSSValue> font_family_;
};

class Element;
class LayoutNode;

struct PropertiesResolvingStatus {
  // per page status
  struct PageStatus {
    float root_font_size_ = Config::DefaultFontSize();
    float font_scale_ = Config::DefaultFontScale();
    starlight::LayoutUnit viewport_width_;
    starlight::LayoutUnit viewport_height_;
    float screen_width_ = 0.f;
  };

  PageStatus page_status_;

  // per element status
  float computed_font_size_ = Config::DefaultFontSize();
  starlight::DirectionType direction_type_ =
      starlight::DefaultCSSStyle::SL_DEFAULT_DIRECTION;

  void ApplyPageStatus(const PropertiesResolvingStatus& status) {
    page_status_ = status.page_status_;
  }
};

class DynamicCSSStylesManager {
 private:
  enum StyleDynamicType : uint32_t {
    kEmType = 0,
    kRemType = 1,
    kScreenMetricsType = 2,
    kDirectionStyleType = 3,
    kFontScaleType = 4,
    kViewportType = 5,
    kDynamicTypeCount = 6
  };

 public:
  DynamicCSSStylesManager(Element* element, const DynamicCSSConfigs& configs);

  enum StyleUpdateFlag : uint32_t {
    kUpdateEm = 1 << kEmType,
    kUpdateRem = 1 << kRemType,
    kUpdateScreenMetrics = 1 << kScreenMetricsType,
    kUpdateDirectionStyle = 1 << kDirectionStyleType,
    kUpdateFontScale = 1 << kFontScaleType,
    kUpdateViewport = 1 << kViewportType,
  };

  static constexpr uint32_t kNoUpdate = 0;

  using StyleUpdateFlags = uint32_t;

  static const std::unordered_set<CSSPropertyID>& GetInheritableProps();

  static bool CheckIsDirectionAwareStyle(CSSPropertyID css_id);

  static CSSPropertyID ResolveDirectionAwarePropertyID(
      CSSPropertyID id, starlight::DirectionType direction);

  static std::pair<CSSPropertyID, IsLogic> ResolveLogicPropertyID(
      CSSPropertyID id);
  static CSSPropertyID ResolveDirectionRelatedPropertyID(
      CSSPropertyID id, starlight::DirectionType direction,
      IsLogic is_logic_style);
  static void UpdateDirectionAwareDefaultStyles(
      Element* element, starlight::DirectionType direction);

  void SetInitialResolvingStatus(const PropertiesResolvingStatus& status) {
    resolving_data_ = status;
  }
  void AdoptStyle(CSSPropertyID id, const tasm::CSSValue& value);

  void SetPlaceHolderStyle(const PseudoPlaceHolderStyles& styles);

  void UpdateFontSizeStyle(const tasm::CSSValue* value);
  void UpdateDirectionStyle(const tasm::CSSValue& value);

  void UpdateWithResolvingStatus(const PropertiesResolvingStatus& status);

  void MarkDirty() {
    force_reapply_inheritance_ = true;
    // To apply dirty flag to the node to be inserted
    dirty_ = false;
    MarkDirtyInternal();
  }

  // Weird function to keep old buggy behvior;
  void SetViewportSizeWhenInitialize(const LynxEnvConfig& config);

 private:
  void MarkDirtyInternal();
  void ClearDirtyFlags() {
    font_size_need_update_ = false;
    direction_need_update_ = false;
    force_reapply_inheritance_ = false;
    dirty_ = false;
  }

  using FlagsMap = std::map<CSSPropertyID, StyleUpdateFlags>;
  using ValueStorage = std::map<CSSPropertyID, CSSValue>;
  struct InheritablePropsState {
    CSSValue value_;
    bool dirty_;
  };

  class InheritedProps {
   public:
    InheritedProps() = default;
    InheritedProps(InheritedProps&& other) = default;
    InheritedProps& operator=(InheritedProps&&) = default;
    InheritedProps(
        std::map<CSSPropertyID, InheritablePropsState>&& to_be_inherited)
        : data_(std::forward<std::map<CSSPropertyID, InheritablePropsState>>(
              to_be_inherited)) {}
    void Inherit(const InheritedProps& to_be_inherited) {
      inherited_ = &(to_be_inherited.Get());
    }

    const std::map<CSSPropertyID, InheritablePropsState>& Get() const {
      if (inherited_) {
        return *inherited_;
      } else {
        return data_;
      }
    }

   private:
    std::map<CSSPropertyID, InheritablePropsState> data_;
    const std::map<CSSPropertyID, InheritablePropsState>* inherited_ = nullptr;
  };

  bool IsInheritable(CSSPropertyID id) const;

  void UpdateWithResolvingStatus(const PropertiesResolvingStatus& status,
                                 const InheritedProps& props,
                                 bool inherited_need_update,
                                 bool force_apply_inheritance);
  std::pair<bool, InheritedProps> ApplyInheritance(
      const InheritedProps& props, bool was_dirty, StyleUpdateFlags env_changes,
      bool force_apply_inheritance);

  void ApplyDirection(const PropertiesResolvingStatus& status,
                      StyleUpdateFlags& current_updates,
                      PropertiesResolvingStatus& next_resolving_data);

  void ApplyFontSizeUpdateResolvingData(
      const PropertiesResolvingStatus& status,
      StyleUpdateFlags& current_updates,
      PropertiesResolvingStatus& next_resolving_data);

  void UpdatePlaceHolderStyle(StyleUpdateFlags current_updates);

  void ForEachFlagDo(
      StyleUpdateFlags flags,
      const base::MoveOnlyClosure<void, std::map<CSSPropertyID, CSSValue>&>&
          func);
  void ResetAllDirectionAwareProperty();
  void SetStyeToElement(CSSPropertyID id, const CSSValue& css_value,
                        bool force_update = false);
  void ResetStyeToElement(CSSPropertyID id);

  // Assuming each of the field will contains only a few styles
  FlagsMap flag_maps_;
  std::map<CSSPropertyID, std::pair<CSSValue, StyleUpdateFlags>> must_updates_;
  std::array<ValueStorage, kDynamicTypeCount> value_storage_;
  std::map<CSSPropertyID, InheritablePropsState> inheritable_props_;
  PropertiesResolvingStatus resolving_data_;
  Element* element_;
  CSSValue font_size_ = CSSValue::Empty();
  StyleUpdateFlags font_size_flags_ = kNoUpdate;
  bool font_size_need_update_ = false;
  bool dirty_ = true;
  const DynamicCSSConfigs& configs_;

  // direction aware style
  bool direction_need_update_ = false;
  CSSValue direction_ = CSSValue::Empty();
  PseudoPlaceHolderStyles placeholder_styles_;
  bool force_reapply_inheritance_ = true;

  // The code sucks. I hate it. Screw all the buggy behavior we have to
  // keep!!!!!!
  starlight::LayoutUnit vwbase_for_font_size_to_align_with_legacy_bug_;
  starlight::LayoutUnit vhbase_for_font_size_to_align_with_legacy_bug_;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_DYNAMIC_CSS_STYLES_MANAGER_H_
