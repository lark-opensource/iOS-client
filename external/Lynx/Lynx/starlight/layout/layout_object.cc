// Copyright 2017 The Lynx Authors. All rights reserved.

#include "starlight/layout/layout_object.h"

#include <algorithm>
#include <cmath>
#include <unordered_set>

#include "base/lynx_env.h"
#include "base/trace_event/trace_event.h"
#include "starlight/layout/box_info.h"
#include "starlight/layout/flex_layout_algorithm.h"
#include "starlight/layout/grid_layout_algorithm.h"
#include "starlight/layout/layout_algorithm.h"
#include "starlight/layout/linear_layout_algorithm.h"
#include "starlight/layout/property_resolving_utils.h"
#include "starlight/layout/relative_layout_algorithm.h"
#include "starlight/layout/staggered_grid_layout_algorithm.h"
#include "starlight/style/css_style_utils.h"
#include "starlight/style/default_css_style.h"
#include "starlight/types/measure_context.h"
#include "tasm/lynx_env_config.h"
#include "tasm/lynx_trace_event.h"

namespace lynx {
namespace starlight {

namespace {
inline float GetBoundLeftOffsetFromPaddingBound(const LayoutObject& target,
                                                BoundType bound_type) {
  float result = 0.f;
  switch (bound_type) {
    case BoundType::kMargin:
      result -= target.GetLayoutMarginLeft();
    case BoundType::kBorder:
      result -= target.GetLayoutBorderLeftWidth();
      break;
    case BoundType::kContent:
      result = target.GetLayoutPaddingLeft();
      break;
    case BoundType::kPadding:
    default:
      break;
  }
  return result;
}

float GetBoundTopOffsetFromPaddingBound(const LayoutObject& target,
                                        BoundType bound_type) {
  float result = 0.f;
  switch (bound_type) {
    case BoundType::kMargin:
      result -= target.GetLayoutMarginTop();
    case BoundType::kBorder:
      result -= target.GetLayoutBorderTopWidth();
      break;
    case BoundType::kContent:
      result = target.GetLayoutPaddingTop();
      break;
    case BoundType::kPadding:
    default:
      break;
  }
  return result;
}
inline float GetBoundLeftOffsetFromBorderBound(const LayoutObject& target,
                                               BoundType bound_type) {
  return GetBoundLeftOffsetFromPaddingBound(target, bound_type) +
         target.GetLayoutBorderLeftWidth();
}

inline float GetBoundTopOffsetFromBorderBound(const LayoutObject& target,
                                              BoundType bound_type) {
  return GetBoundTopOffsetFromPaddingBound(target, bound_type) +
         target.GetLayoutBorderTopWidth();
}

inline uint64_t GetMillisecondsSinceEpoch() {
  return std::chrono::duration_cast<std::chrono::milliseconds>(
             std::chrono::system_clock::now().time_since_epoch())
      .count();
}

}  // namespace

LayoutObject::LayoutObject(const LayoutConfigs& config,
                           const tasm::LynxEnvConfig& envs,
                           const starlight::ComputedCSSStyle& init_style)
    : screen_width_(envs.ScreenWidth()),
      measure_func_(nullptr),
      request_layout_func_(nullptr),
      alignment_func_(nullptr),
      offset_top_(0),
      offset_left_(0),
      offset_width_(0),
      offset_height_(0),
      offset_baseline_(0),
      algorithm_(nullptr),
      pos_left_(0),
      pos_right_(0),
      pos_top_(0),
      pos_bottom_(0),
      css_style_(),
      is_dirty_(false),
      current_node_has_new_layout_(false),
      is_first_layout_(true),
      baseline_flag_(false),
      configs_(config) {
  box_info_ = std::make_unique<BoxInfo>();
  css_style_ = std::make_unique<ComputedCSSStyle>(init_style);
  css_style_->SetFontScaleOnlyEffectiveOnSp(config.font_scale_sp_only_);
  css_style_->SetScreenWidth(screen_width_);
  css_style_->SetFontScale(envs.FontScale());
  css_style_->SetViewportWidth(envs.ViewportWidth());
  css_style_->SetViewportHeight(envs.ViewportHeight());
  css_style_->SetCssAlignLegacyWithW3c(config.css_align_with_legacy_w3c_);
}

LayoutObject::~LayoutObject() {
  if (algorithm_) delete algorithm_;
}

void LayoutObject::SetContext(void* context) { context_ = context; }
void* LayoutObject::GetContext() const { return context_; }

void LayoutObject::SetSLMeasureFunc(SLMeasureFunc measure_func) {
  if (!measure_func) {
    measure_func_ = nullptr;
    return;
  }
  measure_func_ = measure_func;
}

SLMeasureFunc LayoutObject::GetSLMeasureFunc() const { return measure_func_; }

void LayoutObject::SetSLRequestLayoutFunc(
    SLRequestLayoutFunc request_layout_func) {
  request_layout_func_ = request_layout_func;
}

void LayoutObject::SetSLAlignmentFunc(SLAlignmentFunc alignment_func) {
  if (!alignment_func) {
    alignment_func_ = nullptr;
    return;
  }
  alignment_func_ = alignment_func;
}

SLAlignmentFunc LayoutObject::GetSLAlignmentFunc() const {
  return alignment_func_;
}

bool LayoutObject::SetStyle(tasm::CSSPropertyID key,
                            const tasm::CSSValue& value) {
  static std::unordered_set<tasm::CSSPropertyID> box_info_props = {
      tasm::kPropertyIDMinWidth,     tasm::kPropertyIDMinHeight,
      tasm::kPropertyIDMaxWidth,     tasm::kPropertyIDMaxHeight,
      tasm::kPropertyIDPadding,      tasm::kPropertyIDPaddingTop,
      tasm::kPropertyIDPaddingRight, tasm::kPropertyIDPaddingBottom,
      tasm::kPropertyIDPaddingLeft,  tasm::kPropertyIDMargin,
      tasm::kPropertyIDMarginTop,    tasm::kPropertyIDMarginRight,
      tasm::kPropertyIDMarginBottom, tasm::kPropertyIDMarginLeft,
  };
  if (css_style_->SetValue(key, value)) {
    if (box_info_props.find(key) != box_info_props.end()) {
      box_info_->SetBoxInfoPropsModified();
    }
    MarkDirty();
    return true;
  }
  return false;
}

bool LayoutObject::SetAttribute(LayoutAttribute key,
                                const lepus::Value& value) {
  lepus::Value old_value = lepus::Value();
  if (attr_map_.find(key) != attr_map_.end()) {
    old_value = attr_map_[key];
  }
  attr_map_[key] = value;
  bool changed = !old_value.IsEqual(value);
  if (changed) {
    MarkDirty();
  }
  return changed;
}

void LayoutObject::RemoveAlgorithm() {
  if (algorithm_) {
    delete algorithm_;
    algorithm_ = nullptr;
  }
}

void LayoutObject::RemoveAlgorithmRecursive() {
  RemoveAlgorithm();
  LayoutObject* child = static_cast<LayoutObject*>(FirstChild());
  while (child) {
    child->RemoveAlgorithmRecursive();
    child = static_cast<LayoutObject*>(child->Next());
  }
}

void LayoutObject::RoundToPixelGrid(const float container_absolute_left,
                                    const float container_absolute_top,
                                    const float container_rounded_left,
                                    const float container_rounded_top,
                                    bool ancestors_have_new_layout) {
  const float absolute_left =
      container_absolute_left +
      GetBoundLeftFrom(BoundType::kBorder, BoundType::kBorder);
  float absolute_top = container_absolute_top +
                       GetBoundTopFrom(BoundType::kBorder, BoundType::kBorder);
  bool layout_changed_since_root = ancestors_have_new_layout ||
                                   is_first_layout_ ||
                                   current_node_has_new_layout_;
  current_node_has_new_layout_ = false;

  if (parent() && static_cast<LayoutObject*>(parent())->IsList()) {
    // The top of list item is decided by platform layout, the top here will
    // never be used. Reset it to 0 to achieve unified layout result.
    absolute_top = 0.f;
  }
  float rounded_absolute_top =
      CSSStyleUtils::RoundValueToPixelGrid(absolute_top);
  float rounded_absolute_left =
      CSSStyleUtils::RoundValueToPixelGrid(absolute_left);

  if (layout_changed_since_root) {
    const float absolute_right = absolute_left + offset_width_;
    const float absolute_bottom = absolute_top + offset_height_;

    float rounded_absolute_right =
        CSSStyleUtils::RoundValueToPixelGrid(absolute_right);
    float rounded_absolute_bottom =
        CSSStyleUtils::RoundValueToPixelGrid(absolute_bottom);

    LayoutResultForRendering new_layout_result;
    /*以下round过程中,对text结点需要不减小它的size,防止导致文字的折行*/
    new_layout_result.offset_.SetX(rounded_absolute_left -
                                   container_rounded_left);
    new_layout_result.offset_.SetY(rounded_absolute_top -
                                   container_rounded_top);

    float rounded_width = CSSStyleUtils::RoundValueToPixelGrid(absolute_right) -
                          rounded_absolute_left;
    float rounded_height =
        CSSStyleUtils::RoundValueToPixelGrid(absolute_bottom) -
        rounded_absolute_top;
    new_layout_result.size_.width_ = rounded_width;
    new_layout_result.size_.height_ = rounded_height;

    new_layout_result.border_[kLeft] =
        CSSStyleUtils::RoundValueToPixelGrid(GetLayoutBorderLeftWidth());
    new_layout_result.border_[kRight] =
        CSSStyleUtils::RoundValueToPixelGrid(GetLayoutBorderRightWidth());
    new_layout_result.border_[kTop] =
        CSSStyleUtils::RoundValueToPixelGrid(GetLayoutBorderTopWidth());
    new_layout_result.border_[kBottom] =
        CSSStyleUtils::RoundValueToPixelGrid(GetLayoutBorderBottomWidth());

    const float content_left = CSSStyleUtils::RoundValueToPixelGrid(
        (absolute_left + GetLayoutPaddingLeft() + GetLayoutBorderLeftWidth()));
    const float content_top = CSSStyleUtils::RoundValueToPixelGrid(
        (absolute_top + GetLayoutPaddingTop() + GetLayoutBorderTopWidth()));
    const float content_right = CSSStyleUtils::RoundValueToPixelGrid(
        (absolute_right - GetLayoutPaddingRight() -
         GetLayoutBorderRightWidth()));
    const float content_bottom = CSSStyleUtils::RoundValueToPixelGrid(
        (absolute_bottom - GetLayoutPaddingBottom() -
         GetLayoutBorderBottomWidth()));

    new_layout_result.padding_[kLeft] =
        content_left - rounded_absolute_left - new_layout_result.border_[kLeft];
    new_layout_result.padding_[kTop] =
        content_top - rounded_absolute_top - new_layout_result.border_[kTop];
    new_layout_result.padding_[kRight] = rounded_absolute_right -
                                         content_right -
                                         new_layout_result.border_[kRight];
    new_layout_result.padding_[kBottom] = rounded_absolute_bottom -
                                          content_bottom -
                                          new_layout_result.border_[kBottom];

    new_layout_result.margin_[kLeft] = GetLayoutMarginLeft();
    new_layout_result.margin_[kTop] = GetLayoutMarginTop();
    new_layout_result.margin_[kRight] = GetLayoutMarginRight();
    new_layout_result.margin_[kBottom] = GetLayoutMarginBottom();

    if (IsSticky()) {
      new_layout_result.sticky_pos_[kLeft] =
          CSSStyleUtils::RoundValueToPixelGrid(pos_left() +
                                               container_absolute_left) -
          container_rounded_left;
      new_layout_result.sticky_pos_[kRight] =
          rounded_absolute_right -
          CSSStyleUtils::RoundValueToPixelGrid(absolute_right - pos_right());
      new_layout_result.sticky_pos_[kTop] =
          CSSStyleUtils::RoundValueToPixelGrid(pos_top() +
                                               container_absolute_top) -
          container_rounded_top;
      new_layout_result.sticky_pos_[kBottom] =
          rounded_absolute_bottom -
          CSSStyleUtils::RoundValueToPixelGrid(absolute_bottom - pos_bottom());
    }

    // if is first layout or has new layout result or has MeasureFunc && dirty,
    // mark and continue visit child
    if (SetNewLayoutResult(new_layout_result) || is_first_layout_ ||
        (GetSLMeasureFunc() && IsDirty())) {
      MarkHasNewLayout();
    }
  }

  if (is_dirty_ || layout_changed_since_root) {
    LayoutObject* child = static_cast<LayoutObject*>(FirstChild());
    while (child) {
      child->RoundToPixelGrid(absolute_left, absolute_top,
                              rounded_absolute_left, rounded_absolute_top,
                              layout_changed_since_root);
      child = static_cast<LayoutObject*>(child->Next());
    }
  }
}

bool LayoutObject::SetNewLayoutResult(LayoutResultForRendering new_result) {
  auto IsLayoutResultDiff = [](DirectionValue<float>& old_direction_values,
                               DirectionValue<float>& new_direction_values) {
    for (int i = 0; i < kDirectionCount; i++) {
      if (!base::FloatsEqual(old_direction_values[i],
                             new_direction_values[i])) {
        return true;
      }
    }

    return false;
  };
  if (!base::FloatsEqual(layout_result_.size_.width_,
                         new_result.size_.width_) ||
      !base::FloatsEqual(layout_result_.size_.height_,
                         new_result.size_.height_) ||
      !base::FloatsEqual(layout_result_.offset_.X(), new_result.offset_.X()) ||
      !base::FloatsEqual(layout_result_.offset_.Y(), new_result.offset_.Y()) ||
      IsLayoutResultDiff(layout_result_.padding_, new_result.padding_) ||
      IsLayoutResultDiff(layout_result_.border_, new_result.border_) ||
      IsLayoutResultDiff(layout_result_.margin_, new_result.margin_) ||
      IsLayoutResultDiff(layout_result_.sticky_pos_, new_result.sticky_pos_)) {
    layout_result_ = new_result;
    return true;
  }

  return false;
}

BoxInfo* LayoutObject::GetBoxInfo() const { return box_info_.get(); }

void LayoutObject::ReLayout(int left, int top, int right, int bottom) {
  if (!measured_position_.Equal(left, top, right, bottom)) {
    MarkDirty();
  }
  if (IsDirty()) {
    offset_width_ = right - left;
    offset_height_ = bottom - top;
    SLMeasureMode width_mode = SLMeasureModeDefinite,
                  height_mode = SLMeasureModeDefinite;
    if (offset_width_ < 0 || offset_width_ > 10E6) {
      offset_width_ = 0;
      width_mode = SLMeasureModeIndefinite;
    }
    if (offset_height_ < 0 || offset_height_ > 10E6) {
      offset_height_ = 0;
      height_mode = SLMeasureModeIndefinite;
    }

    LayoutUnit indefinite_unit;

    auto max_width = NLengthToLayoutUnit(css_style_->GetMaxWidth(),
                                         IsSLDefiniteMode(width_mode)
                                             ? LayoutUnit(offset_width_)
                                             : indefinite_unit);
    auto max_height = NLengthToLayoutUnit(css_style_->GetMaxHeight(),
                                          IsSLDefiniteMode(height_mode)
                                              ? LayoutUnit(offset_height_)
                                              : indefinite_unit);

    if (max_width.IsDefinite() &&
        css_style_->GetMaxWidth() != DefaultCSSStyle::SL_DEFAULT_MAX_WIDTH()) {
      offset_width_ = max_width.ToFloat();
      width_mode = SLMeasureModeAtMost;
    }

    if (max_height.IsDefinite() &&
        css_style_->GetMaxHeight() !=
            DefaultCSSStyle::SL_DEFAULT_MAX_HEIGHT()) {
      offset_height_ = max_height.ToFloat();
      height_mode = SLMeasureModeAtMost;
    }
    auto width = NLengthToLayoutUnit(css_style_->GetWidth(),
                                     IsSLDefiniteMode(width_mode)
                                         ? LayoutUnit(offset_width_)
                                         : indefinite_unit);
    auto height = NLengthToLayoutUnit(css_style_->GetHeight(),
                                      IsSLDefiniteMode(height_mode)
                                          ? LayoutUnit(offset_height_)
                                          : indefinite_unit);

    if (width.IsDefinite()) {
      offset_width_ = width.ToFloat();
      width_mode = SLMeasureModeDefinite;
    }

    if (height.IsDefinite()) {
      offset_height_ = height.ToFloat();
      height_mode = SLMeasureModeDefinite;
    }
    // TODO(zhixuan): refactor it later....
    Constraints constraints;
    constraints[kHorizontal] = OneSideConstraint(offset_width_, width_mode);
    constraints[kVertical] = OneSideConstraint(offset_height_, height_mode);

    box_info_->InitializeBoxInfo(constraints, *this, GetLayoutConfigs());
    MarkHasNewLayout();
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "UpdateMeasure");
    UpdateMeasure(constraints, true);
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "UpdateAlignment");
    UpdateAlignment();
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "RemoveAlgorithmRecursive");
    RemoveAlgorithmRecursive();
    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
    TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY, "RoundToPixelGrid");
    RoundToPixelGrid(offset_left_, offset_top_, 0.f, 0.f, false);

    TRACE_EVENT_END(LYNX_TRACE_CATEGORY);
  }
}

// TODO(liting): Hack update.delete this when css refactoring
void LayoutObject::UpdateLynxEnv(const tasm::LynxEnvConfig& config) {
  screen_width_ = config.ScreenWidth();
  if (css_style_) {
    css_style_->SetScreenWidth(config.ScreenWidth());
    css_style_->SetViewportWidth(config.ViewportWidth());
    css_style_->SetViewportHeight(config.ViewportHeight());
    css_style_->SetFontScale(config.FontScale());
  }

  Node* child = FirstChild();
  while (child != nullptr) {
    // recursive tree
    static_cast<LayoutObject*>(child)->UpdateLynxEnv(config);
    child = child->Next();
  }
}

void LayoutObject::MarkDirtyAndRequestLayout() {
  MarkDirtyInternal(true);
  current_node_has_new_layout_ = true;
}

void LayoutObject::MarkDirty() {
  MarkDirtyInternal(false);
  current_node_has_new_layout_ = true;
}

void LayoutObject::ClearCache() {
  cache_manager_.ResetCache();
  inflow_sub_tree_in_sync_with_last_measurement_ = false;
}

void LayoutObject::MarkDirtyInternal(bool request_layout) {
  if (!IsDirty()) {
    is_dirty_ = true;
    if (request_layout && request_layout_func_) {
      request_layout_func_(context_);
    }
    ClearCache();
    LayoutObject* parent = static_cast<LayoutObject*>(parent_);
    if (parent != nullptr && !parent->IsDirty()) {
      parent->MarkDirtyInternal(request_layout);
    }
  }
}

void LayoutObject::MarkChildrenDirtyWithoutTriggerLayout() {
  int child_size = GetChildCount();
  for (int i = 0; i < child_size; ++i) {
    auto* child = static_cast<LayoutObject*>(Find(i));
    child->MarkDirty();
  }
}

void LayoutObject::MarkDirtyWithoutResetCache() {
  if (!IsDirty()) {
    // This function is used within layout stage.
    // dirty function should not be triggered here
    is_dirty_ = true;
    LayoutObject* parent = static_cast<LayoutObject*>(parent_);
    if (parent != nullptr && !parent->IsDirty()) {
      parent->MarkDirtyWithoutResetCache();
    }
  }
}

bool LayoutObject::IsDirty() { return is_dirty_; }

void LayoutObject::MarkUpdated() {
  current_node_has_new_layout_ = false;
  is_dirty_ = false;
  is_first_layout_ = false;
}

void LayoutObject::MarkHasNewLayout() {
  current_node_has_new_layout_ = true;
  MarkDirtyWithoutResetCache();
}

bool LayoutObject::GetHasNewLayout() const {
  return current_node_has_new_layout_;
}

void LayoutObject::SetBorderBoundTopFromParentPaddingBound(float offset_top) {
  if (!base::FloatsEqual(offset_top_, offset_top)) {
    MarkHasNewLayout();
    offset_top_ = offset_top;
  }
}
void LayoutObject::SetBorderBoundLeftFromParentPaddingBound(float offset_left) {
  if (!base::FloatsEqual(offset_left_, offset_left)) {
    MarkHasNewLayout();
    offset_left_ = offset_left;
  }
}
void LayoutObject::SetBorderBoundWidth(float offset_width) {
  if (!base::FloatsEqual(offset_width_, offset_width)) {
    MarkHasNewLayout();
    offset_width_ = offset_width;
  }
}
void LayoutObject::SetBorderBoundHeight(float offset_height) {
  if (!base::FloatsEqual(offset_height_, offset_height)) {
    MarkHasNewLayout();
    offset_height_ = offset_height;
  }
}

void LayoutObject::SetBaseline(float offset_baseline) {
  if (!base::FloatsEqual(offset_baseline_, offset_baseline)) {
    MarkHasNewLayout();
    offset_baseline_ = offset_baseline;
  }
}

float LayoutObject::ClampExactHeight(float height) const {
  height = std::max(height, box_info_->min_size_[kVertical]);
  height = std::min(height, box_info_->max_size_[kVertical]);
  return std::max(GetPaddingAndBorderVertical(), height);
}

float LayoutObject::ClampExactWidth(float width) const {
  width = std::max(width, box_info_->min_size_[kHorizontal]);
  width = std::min(width, box_info_->max_size_[kHorizontal]);
  return std::max(GetPaddingAndBorderHorizontal(), width);
}

bool LayoutObject::FetchEarlyReturnResultForMeasure(
    const Constraints& constraints, bool is_trying, FloatSize& result) {
  const auto cache = cache_manager_.FindAvailableCacheEntry(constraints, *this);

  if (cache.cache_) {
    // Matching cache is found

    if (!is_trying &&
        ((!IsInflowSubTreeInSyncWithLastMeasurement() && !measure_func_) ||
         !cache.is_cache_in_sync_with_current_state)) {
      // When not trying and current subtree is not in sync with the result
      // of given constraints, the subtree have to be re-layout
      // to make sure the whole subtree is in sync
      return false;
    } else {
      result.width_ = cache.cache_->border_bound_width_;
      result.height_ = cache.cache_->border_bound_height_;
      if (measure_func_) {
        inflow_sub_tree_in_sync_with_last_measurement_ =
            cache.is_cache_in_sync_with_current_state;
      } else {
        inflow_sub_tree_in_sync_with_last_measurement_ =
            cache.is_cache_in_sync_with_current_state &&
            IsInflowSubTreeInSyncWithLastMeasurement();
      }
      DCHECK(is_trying || inflow_sub_tree_in_sync_with_last_measurement_);
      return true;
    }
  }

  if (constraints[kHorizontal].Mode() == SLMeasureModeDefinite &&
      constraints[kVertical].Mode() == SLMeasureModeDefinite && is_trying) {
    result.height_ = constraints[kVertical].Size();
    result.width_ = constraints[kHorizontal].Size();
    inflow_sub_tree_in_sync_with_last_measurement_ = false;
    return true;
  }
  return false;
}

bool LayoutObject::DoesLayoutDependOnHorizontalPercentBase() {
  if (BoxInfo().IsDependentOnHorizontalPercentBase()) {
    return true;
  }

  if (measure_func_) {
    if (GetLayoutConfigs().IsFullQuirksMode()) {
      if (css_style_->GetMinWidth() !=
          DefaultCSSStyle::SL_DEFAULT_MIN_WIDTH()) {
        return true;
      }
      if (css_style_->GetMaxWidth() !=
          DefaultCSSStyle::SL_DEFAULT_MAX_WIDTH()) {
        return true;
      }
    }
  } else {
    const auto display = css_style_->GetDisplay(configs_, attr_map());
    if (display == DisplayType::kLinear) {
      if (css_style_->GetLinearOrientation() ==
          LinearOrientationType::kVertical) {
        return true;
      }
      if (css_style_->GetLinearOrientation() ==
          LinearOrientationType::kVerticalReverse) {
        return true;
      }
    } else if (display == DisplayType::kFlex) {
      if (css_style_->GetFlexDirection() == FlexDirectionType::kColumn) {
        return true;
      }
      if (css_style_->GetFlexDirection() == FlexDirectionType::kColumnReverse) {
        return true;
      }
    } else if (display == DisplayType::kRelative) {
      return true;
    }

    for (Node* node = FirstChild(); node != nullptr; node = node->Next()) {
      const auto* css = static_cast<LayoutObject*>(node)->GetCSSStyle();
      const auto LengthAffected = [](const NLength& len) {
        return len.IsPercent() || len.IsCalc();
      };
      if (LengthAffected(css->GetWidth())) {
        return true;
      }
      if (LengthAffected(css->GetMinWidth())) {
        return true;
      }
      if (LengthAffected(css->GetMaxWidth())) {
        return true;
      }
      if (LengthAffected(css->GetPaddingTop())) {
        return true;
      }
      if (LengthAffected(css->GetPaddingLeft())) {
        return true;
      }
      if (LengthAffected(css->GetPaddingBottom())) {
        return true;
      }
      if (LengthAffected(css->GetPaddingRight())) {
        return true;
      }
      if (LengthAffected(css->GetMarginTop())) {
        return true;
      }
      if (LengthAffected(css->GetMarginLeft())) {
        return true;
      }
      if (LengthAffected(css->GetMarginBottom())) {
        return true;
      }
      if (LengthAffected(css->GetMarginRight())) {
        return true;
      }
    }
  }
  return false;
}

bool LayoutObject::DoesLayoutDependOnVerticalPercentBase() {
  // Check if css size properties contains percentage
  if (BoxInfo().IsDependentOnVerticalPercentBase()) {
    return true;
  }

  if (measure_func_) {
    if (css_style_->GetMinHeight() !=
        DefaultCSSStyle::SL_DEFAULT_MIN_HEIGHT()) {
      return true;
    }
    if (css_style_->GetMaxHeight() !=
        DefaultCSSStyle::SL_DEFAULT_MAX_HEIGHT()) {
      return true;
    }
  } else {
    const auto display = css_style_->GetDisplay(configs_, attr_map());
    if (display == DisplayType::kLinear) {
      if (css_style_->GetLinearOrientation() ==
          LinearOrientationType::kHorizontal) {
        return true;
      }
      if (css_style_->GetLinearOrientation() ==
          LinearOrientationType::kHorizontalReverse) {
        return true;
      }
    } else if (display == DisplayType::kFlex) {
      if (css_style_->GetFlexDirection() == FlexDirectionType::kRow) {
        return true;
      }
      if (css_style_->GetFlexDirection() == FlexDirectionType::kRowReverse) {
        return true;
      }
    } else if (display == DisplayType::kRelative) {
      return true;
    }

    for (Node* node = FirstChild(); node != nullptr; node = node->Next()) {
      const auto* css = static_cast<LayoutObject*>(node)->GetCSSStyle();
      const auto LengthAffected = [](const NLength& len) {
        return len.IsPercent() || len.IsCalc();
      };
      if (LengthAffected(css->GetHeight())) {
        return true;
      }
      if (LengthAffected(css->GetMinHeight())) {
        return true;
      }
      if (LengthAffected(css->GetMaxHeight())) {
        return true;
      }
    }
  }
  return false;
}

FloatSize LayoutObject::UpdateMeasureByPlatform(const Constraints& constraints,
                                                bool final_measure) {
  Constraints item_constraints =
      property_utils::GenerateDefaultConstraints(*this, constraints);
  box_info_->InitializeBoxInfo(item_constraints, *this, GetLayoutConfigs());
  // Should margins be applied via native?
  FloatSize size = UpdateMeasure(item_constraints, final_measure);
  return size;
}

void LayoutObject::AlignmentByPlatform(float offset_top, float offset_left) {
  offset_top_ = offset_top;
  offset_left_ = offset_left;
  UpdateAlignment();
}

FloatSize LayoutObject::UpdateMeasure(const Constraints& given_constraints,
                                      bool final_measure) {
  uint64_t start_layout_time = GetMillisecondsSinceEpoch();

  Constraints constraints = given_constraints;
  property_utils::ApplyMinMaxToConstraints(constraints, *this);

  final_measure_ = final_measure;

  FloatSize result;
  if (FetchEarlyReturnResultForMeasure(constraints, !final_measure, result)) {
    result.baseline_ = GetBaseline();
    RecordLayoutPerf(start_layout_time, true, final_measure);
    return result;
  }

  const auto ReturnCurrentSizeAndInsertToCache =
      [this, &constraints, start_layout_time, final_measure]() {
        FloatSize size;
        cache_manager_.InsertCacheEntry(constraints, GetBorderBoundWidth(),
                                        GetBorderBoundHeight());
        size.width_ = GetBorderBoundWidth();
        size.height_ = GetBorderBoundHeight();
        size.baseline_ = GetBaseline();
        RecordLayoutPerf(start_layout_time, false, final_measure);
        return size;
      };

  if (measure_func_) {
    UpdateMeasureWithMeasureFunc(constraints, final_measure);
    inflow_sub_tree_in_sync_with_last_measurement_ = true;
    return ReturnCurrentSizeAndInsertToCache();
  }

  /* IF THE NODE HAS NO CHILD, WE DO NOT NEED TO CREATE THE LAYOUT ALGORITHM*/
  if (!GetChildCount()) {
    UpdateMeasureWithLeafNode(constraints);
    inflow_sub_tree_in_sync_with_last_measurement_ = true;
    return ReturnCurrentSizeAndInsertToCache();
  }

  if (!algorithm_) {
    const auto type = css_style_->GetDisplay(configs_, attr_map());
    if (type == DisplayType::kNone) {
      return ReturnCurrentSizeAndInsertToCache();
    }

    if (type == DisplayType::kFlex) {
      algorithm_ = new FlexLayoutAlgorithm(this);
    } else if (type == DisplayType::kLinear) {
      if (attr_map_.find(LayoutAttribute::kColumnCount) != attr_map_.end()) {
        algorithm_ = new StaggeredGridLayoutAlgorithm(this);
      } else {
        algorithm_ = new LinearLayoutAlgorithm(this);
      }
    } else if (type == DisplayType::kRelative) {
      algorithm_ = new RelativeLayoutAlgorithm(this);
    } else if (type == DisplayType::kGrid) {
      algorithm_ = new GridLayoutAlgorithm(this);
    }

    LynxFatal(algorithm_, LYNX_ERROR_CODE_LAYOUT,
              "Layout algorithm cannot be initialized.");

    algorithm_->Initialize(constraints);
  } else {
    algorithm_->Update(constraints);
    // TODO:使用cache时对boxdata和flexinfo处理
  }
  inflow_sub_tree_in_sync_with_last_measurement_ = true;

  FloatSize size = algorithm_->SizeDetermination();
  inflow_sub_tree_in_sync_with_last_measurement_ =
      algorithm_->IsInflowSubTreeInSync();

  SetBorderBoundWidth(size.width_);
  SetBorderBoundHeight(size.height_);

  if (GetBaselineFlag()) {
    algorithm_->SetContainerBaseline();
  }

  return ReturnCurrentSizeAndInsertToCache();
}

void LayoutObject::UpdateMeasureWithMeasureFunc(const Constraints& constraints,
                                                bool final_measure) {
  // Adapter code will be a little bit dirty but fine. It is unavoidable
  // anyways.
  float width = 0.f, height = 0.f;
  if (!IsSLIndefiniteMode(constraints[kHorizontal].Mode())) {
    width = ClampExactWidth(constraints[kHorizontal].Size());
  }
  if (!IsSLIndefiniteMode(constraints[kVertical].Mode())) {
    height = ClampExactHeight(constraints[kVertical].Size());
  }

  SLMeasureMode width_mode = constraints[kHorizontal].Mode();
  SLMeasureMode height_mode = constraints[kVertical].Mode();

  float inner_width = std::max(GetInnerWidthFromBorderBoxWidth(width), 0.0f);
  float inner_height =
      std::max(GetInnerHeightFromBorderBoxHeight(height), 0.0f);

  // prevent width from being affected by float.
  if (base::FloatsEqual(std::ceil(inner_width), inner_width)) {
    inner_width = std::ceil(inner_width);
  }

  if (base::FloatsEqual(std::floor(inner_width), inner_width)) {
    inner_width = std::floor(inner_width);
  }

  Constraints inner_constraints;
  inner_constraints[kHorizontal] = OneSideConstraint(inner_width, width_mode);
  inner_constraints[kVertical] = OneSideConstraint(inner_height, height_mode);

  FloatSize size = measure_func_(context_, inner_constraints, final_measure);

  if (GetBaselineFlag()) {
    SetBaseline(size.baseline_);
  }

  // To avoid unexpected line break
  if (width_mode == SLMeasureModeDefinite) {
    size.width_ = inner_width;
  } else {
    size.width_ = std::ceil(size.width_ *
                            ComputedCSSStyle::PHYSICAL_PIXELS_PER_LAYOUT_UNIT) /
                  ComputedCSSStyle::PHYSICAL_PIXELS_PER_LAYOUT_UNIT;
  }
  if (height_mode == SLMeasureModeDefinite) {
    size.height_ = inner_height;
  } else {
    size.height_ =
        std::ceil(size.height_ *
                  ComputedCSSStyle::PHYSICAL_PIXELS_PER_LAYOUT_UNIT) /
        ComputedCSSStyle::PHYSICAL_PIXELS_PER_LAYOUT_UNIT;
  }

  float layout_width =
      ClampExactWidth(size.width_ + GetPaddingAndBorderHorizontal());
  float layout_height =
      ClampExactHeight(size.height_ + GetPaddingAndBorderVertical());
  inner_width = std::max(GetInnerWidthFromBorderBoxWidth(layout_width), 0.0f);
  inner_height =
      std::max(GetInnerHeightFromBorderBoxHeight(layout_height), 0.0f);

  // Fix like 'text-align: right' display when measure_func_ is affected by
  // min/max size
  if (!GetLayoutConfigs().IsFullQuirksMode() &&
      (!base::FloatsEqual(inner_width, size.width_) ||
       !base::FloatsEqual(inner_height, size.height_))) {
    inner_constraints[kHorizontal] = OneSideConstraint::Definite(inner_width);
    inner_constraints[kVertical] = OneSideConstraint::Definite(inner_height);
    measure_func_(context_, inner_constraints, final_measure);
  }

  SetBorderBoundWidth(layout_width);
  SetBorderBoundHeight(layout_height);

  /* NO LAYOUT ALGORITHM AND NO ALIGNMENT TO CALL, SO UP TO DATE HERE*/
  //  UpToDate();
}

void LayoutObject::UpdateMeasureWithLeafNode(const Constraints& constraints) {
  /*LAYOUT OBJECT WITH ZERO CHILD DOES NOT CALL FOR A LAYOUT ALGORITHM
   * IT CAN DETERMINE ITS SIZE IMMEDIATELY*/
  float width_to_set = IsSLDefiniteMode(constraints[kHorizontal].Mode())
                           ? constraints[kHorizontal].Size()
                           : 0;
  float height_to_set = IsSLDefiniteMode(constraints[kVertical].Mode())
                            ? constraints[kVertical].Size()
                            : 0;
  SetBorderBoundWidth(ClampExactWidth(width_to_set));
  SetBorderBoundHeight(ClampExactHeight(height_to_set));
}

void LayoutObject::UpdateAlignment() {
  double border_box_offset_left = GetBorderBoundLeftFromParentPaddingBound();
  double border_box_offset_top = GetBorderBoundTopFromParentPaddingBound();

  if (!measured_position_.Reset(border_box_offset_left, border_box_offset_top,
                                border_box_offset_left + offset_width_,
                                border_box_offset_top + offset_height_) &&
      !IsDirty()) {
    return;
  }
  if (alignment_func_) {
    alignment_func_(context_);
    return;
  }

  if (algorithm_) {
    algorithm_->Alignment();
  }
}

void LayoutObject::UpdateSize(float width, float height) {
  if (base::FloatsEqual(width, offset_width_) &&
      base::FloatsEqual(height, offset_height_))
    return;
  offset_width_ = width;
  offset_height_ = height;
  MarkHasNewLayout();
}

void LayoutObject::HideLayoutObject() {
  SetBorderBoundTopFromParentPaddingBound(0);
  SetBorderBoundWidth(0);
  SetBorderBoundHeight(0);
  SetBorderBoundLeftFromParentPaddingBound(0);
  measured_position_.Reset(0, 0, 0, 0);
  MarkHasNewLayout();
  for (int i = 0; i < GetChildCount(); ++i) {
    LayoutObject* child = static_cast<LayoutObject*>(Find(i));
    child->HideLayoutObject();
  }
  // When hiding layout, insert an empty cache with negative constraints
  // area, to mark the last cached measurement is not in sync with the current
  // state of the layout object.
  Constraints constraints;
  constraints[kHorizontal] = constraints[kVertical] =
      OneSideConstraint::Definite(-1.f);
  cache_manager_.InsertCacheEntry(constraints, 0.f, 0.f);
}

void LayoutObject::LayoutDisplayNone() { HideLayoutObject(); }

void LayoutObject::RecordLayoutPerf(uint64_t start_time, bool has_cache,
                                    bool final_measure) {
  if (base::LynxEnv::GetInstance().IsLayoutPerformanceEnabled()) {
    uint64_t end_time = GetMillisecondsSinceEpoch();
    LayoutPref layout_pref;
    layout_pref.perf_id_ = static_cast<int32_t>(layout_perf_list_.size());
    layout_pref.start_time_ = start_time;
    layout_pref.end_time_ = end_time;
    layout_pref.duration_time_ = end_time - start_time;
    layout_pref.has_cache_ = has_cache;
    layout_pref.is_final_measure_ = final_measure;
    layout_perf_list_.push_back(std::move(layout_pref));
  }
}

std::vector<double> LayoutObject::GetBoxModel() {
  std::vector<double> res;
  res.push_back(offset_width_ - GetLayoutPaddingLeft() -
                GetLayoutPaddingRight() - GetLayoutBorderLeftWidth() -
                GetLayoutBorderRightWidth());
  res.push_back(offset_height_ - GetLayoutPaddingTop() -
                GetLayoutPaddingBottom() - GetLayoutBorderTopWidth() -
                GetLayoutBorderBottomWidth());

  float temp_root_x = 0;
  float temp_root_y = 0;
  auto temp_parent = parent_;
  while (temp_parent != nullptr) {
    temp_root_x += static_cast<LayoutObject*>(temp_parent)
                       ->GetBorderBoundLeftFromParentPaddingBound();
    temp_root_y += static_cast<LayoutObject*>(temp_parent)
                       ->GetBorderBoundTopFromParentPaddingBound();
    temp_parent = static_cast<LayoutObject*>(temp_parent)->parent_;
  }
  // content
  res.push_back(temp_root_x + GetBorderBoundLeftFromParentPaddingBound() +
                GetLayoutPaddingLeft() + GetLayoutBorderLeftWidth());
  res.push_back(temp_root_y + GetBorderBoundTopFromParentPaddingBound() +
                GetLayoutPaddingTop() + GetLayoutBorderTopWidth());
  res.push_back(temp_root_x + GetBorderBoundLeftFromParentPaddingBound() +
                offset_width_ - GetLayoutPaddingRight() -
                GetLayoutBorderRightWidth());
  res.push_back(temp_root_y + GetBorderBoundTopFromParentPaddingBound() +
                GetLayoutPaddingTop() + GetLayoutBorderTopWidth());
  res.push_back(temp_root_x + GetBorderBoundLeftFromParentPaddingBound() +
                offset_width_ - GetLayoutPaddingRight() -
                GetLayoutBorderRightWidth());
  res.push_back(temp_root_y + GetBorderBoundTopFromParentPaddingBound() +
                offset_height_ - GetLayoutPaddingBottom() -
                GetLayoutBorderBottomWidth());
  res.push_back(temp_root_x + GetBorderBoundLeftFromParentPaddingBound() +
                GetLayoutPaddingLeft() + GetLayoutBorderLeftWidth());
  res.push_back(temp_root_y + GetBorderBoundTopFromParentPaddingBound() +
                offset_height_ - GetLayoutPaddingBottom() -
                GetLayoutBorderBottomWidth());

  // padding
  res.push_back(res[2] - GetLayoutPaddingLeft());
  res.push_back(res[3] - GetLayoutPaddingTop());
  res.push_back(res[4] + GetLayoutPaddingRight());
  res.push_back(res[5] - GetLayoutPaddingTop());
  res.push_back(res[6] + GetLayoutPaddingRight());
  res.push_back(res[7] + GetLayoutPaddingBottom());
  res.push_back(res[8] - GetLayoutPaddingLeft());
  res.push_back(res[9] + GetLayoutPaddingBottom());

  // border
  res.push_back(res[10] - GetLayoutBorderLeftWidth());
  res.push_back(res[11] - GetLayoutBorderTopWidth());
  res.push_back(res[12] + GetLayoutBorderRightWidth());
  res.push_back(res[13] - GetLayoutBorderTopWidth());
  res.push_back(res[14] + GetLayoutBorderRightWidth());
  res.push_back(res[15] + GetLayoutBorderBottomWidth());
  res.push_back(res[16] - GetLayoutBorderLeftWidth());
  res.push_back(res[17] + GetLayoutBorderBottomWidth());

  // margin
  res.push_back(res[18] - GetLayoutMarginLeft());
  res.push_back(res[19] - GetLayoutMarginTop());
  res.push_back(res[20] + GetLayoutMarginRight());
  res.push_back(res[21] - GetLayoutMarginTop());
  res.push_back(res[22] + GetLayoutMarginRight());
  res.push_back(res[23] + GetLayoutMarginBottom());
  res.push_back(res[24] - GetLayoutMarginLeft());
  res.push_back(res[25] + GetLayoutMarginBottom());

  return res;
}

float LayoutObject::GetInnerWidthFromBorderBoxWidth(float width) const {
  return width - GetPaddingAndBorderHorizontal();
}
float LayoutObject::GetInnerHeightFromBorderBoxHeight(float height) const {
  return height - GetPaddingAndBorderVertical();
}

float LayoutObject::GetOuterWidthFromBorderBoxWidth(float width) const {
  return width + GetLayoutMarginLeft() + GetLayoutMarginRight();
}

float LayoutObject::GetOuterHeightFromBorderBoxHeight(float height) const {
  return height + GetLayoutMarginTop() + GetLayoutMarginBottom();
}

float LayoutObject::GetPaddingAndBorderHorizontal() const {
  return GetLayoutPaddingLeft() + GetLayoutPaddingRight() +
         css_style_->GetBorderFinalWidthHorizontal();
}

float LayoutObject::GetPaddingAndBorderVertical() const {
  return GetLayoutPaddingTop() + GetLayoutPaddingBottom() +
         css_style_->GetBorderFinalWidthVertical();
}

float LayoutObject::GetBorderBoxWidthFromInnerWidth(float inner_width) const {
  return inner_width + GetPaddingAndBorderHorizontal();
}
float LayoutObject::GetBorderBoxHeightFromInnerHeight(
    float inner_height) const {
  return inner_height + GetPaddingAndBorderVertical();
}

void LayoutObject::Reset(LayoutObject* node) {
  // Remove all children. Need to set child's prev & next to nullptr
  while (FirstChild()) {
    RemoveChild(static_cast<ContainerNode*>(FirstChild()));
  }
  measured_position_.Reset(0, 0, 0, 0);
  SetSLMeasureFunc(nullptr);
  SetContext(nullptr);
  SetBorderBoundWidth(node->GetBorderBoundWidth());
  SetBorderBoundHeight(node->GetBorderBoundHeight());
  SetBorderBoundLeftFromParentPaddingBound(
      node->GetBorderBoundLeftFromParentPaddingBound());
  SetBorderBoundTopFromParentPaddingBound(
      node->GetBorderBoundTopFromParentPaddingBound());

  RemoveAlgorithm();
  css_style_->Reset();
  is_dirty_ = false;
}

float LayoutObject::GetLayoutPaddingLeft() const {
  return box_info_->padding_[kLeft];
}
float LayoutObject::GetLayoutPaddingTop() const {
  return box_info_->padding_[kTop];
}
float LayoutObject::GetLayoutPaddingRight() const {
  return box_info_->padding_[kRight];
}
float LayoutObject::GetLayoutPaddingBottom() const {
  return box_info_->padding_[kBottom];
}
float LayoutObject::GetLayoutMarginLeft() const {
  return box_info_->margin_[kLeft];
}
float LayoutObject::GetLayoutMarginTop() const {
  return box_info_->margin_[kTop];
}
float LayoutObject::GetLayoutMarginRight() const {
  return box_info_->margin_[kRight];
}
float LayoutObject::GetLayoutMarginBottom() const {
  return box_info_->margin_[kBottom];
}
float LayoutObject::GetLayoutBorderLeftWidth() const {
  return css_style_->GetBorderFinalLeftWidth();
}
float LayoutObject::GetLayoutBorderTopWidth() const {
  return css_style_->GetBorderFinalTopWidth();
}
float LayoutObject::GetLayoutBorderRightWidth() const {
  return css_style_->GetBorderFinalRightWidth();
}
float LayoutObject::GetLayoutBorderBottomWidth() const {
  return css_style_->GetBorderFinalBottomWidth();
}

float LayoutObject::GetContentBoundWidth() const {
  return GetBorderBoundWidth() - GetPaddingAndBorderHorizontal();
}
float LayoutObject::GetContentBoundHeight() const {
  return GetBorderBoundHeight() - GetPaddingAndBorderVertical();
}

float LayoutObject::GetMarginBoundWidth() const {
  return GetBorderBoundWidth() + GetLayoutMarginLeft() + GetLayoutMarginRight();
}
float LayoutObject::GetMarginBoundHeight() const {
  return GetBorderBoundHeight() + GetLayoutMarginTop() +
         GetLayoutMarginBottom();
}

float LayoutObject::GetPaddingBoundWidth() const {
  return GetBorderBoundWidth() - GetLayoutBorderLeftWidth() -
         GetLayoutBorderRightWidth();
}
float LayoutObject::GetPaddingBoundHeight() const {
  return GetBorderBoundHeight() - GetLayoutBorderTopWidth() -
         GetLayoutBorderBottomWidth();
}

float LayoutObject::GetBoundTypeWidth(BoundType type) const {
  switch (type) {
    case BoundType::kBorder:
      return GetBorderBoundWidth();
    case BoundType::kMargin:
      return GetMarginBoundWidth();
    case BoundType::kContent:
      return GetContentBoundWidth();
    case BoundType::kPadding:
      return GetPaddingBoundWidth();
  }

  return 0.f;
}

float LayoutObject::GetBoundTypeHeight(BoundType type) const {
  switch (type) {
    case BoundType::kBorder:
      return GetBorderBoundHeight();
    case BoundType::kMargin:
      return GetMarginBoundHeight();
    case BoundType::kContent:
      return GetContentBoundHeight();
    case BoundType::kPadding:
      return GetPaddingBoundHeight();
  }

  return 0.f;
}

void LayoutObject::UpdatePositions(float left, float top, float right,
                                   float bottom) {
  pos_left_ = left;
  pos_top_ = top;
  pos_right_ = right;
  pos_bottom_ = bottom;
}

float LayoutObject::GetBoundLeftFrom(BoundType bound_type,
                                     BoundType parent_bound_type) const {
  return offset_left_ + GetBoundLeftOffsetFromBorderBound(*this, bound_type) -
         (ParentLayoutObject() ? GetBoundLeftOffsetFromPaddingBound(
                                     *ParentLayoutObject(), parent_bound_type)
                               : 0);
}

float LayoutObject::GetBoundTopFrom(BoundType bound_type,
                                    BoundType parent_bound_type) const {
  return offset_top_ + GetBoundTopOffsetFromBorderBound(*this, bound_type) -
         (ParentLayoutObject() ? GetBoundTopOffsetFromPaddingBound(
                                     *ParentLayoutObject(), parent_bound_type)
                               : 0);
}

void LayoutObject::SetBoundLeftFrom(float value, BoundType bound_type,
                                    BoundType parent_bound_type) {
  SetBorderBoundLeftFromParentPaddingBound(
      value - GetBoundLeftOffsetFromBorderBound(*this, bound_type) +
      (ParentLayoutObject() ? GetBoundLeftOffsetFromPaddingBound(
                                  *ParentLayoutObject(), parent_bound_type)
                            : 0));
}

void LayoutObject::SetBoundTopFrom(float value, BoundType bound_type,
                                   BoundType parent_bound_type) {
  SetBorderBoundTopFromParentPaddingBound(
      value - GetBoundTopOffsetFromBorderBound(*this, bound_type) +
      (ParentLayoutObject() ? GetBoundTopOffsetFromPaddingBound(
                                  *ParentLayoutObject(), parent_bound_type)
                            : 0));
}

void LayoutObject::SetBoundRightFrom(float value, BoundType bound_type,
                                     BoundType parent_bound_type) {
  float left_offset =
      ParentLayoutObject()
          ? (ParentLayoutObject()->GetBoundTypeWidth(parent_bound_type) -
             GetBoundTypeWidth(bound_type) - value)
          : 0;
  SetBoundLeftFrom(left_offset, bound_type, parent_bound_type);
}

void LayoutObject::SetBoundBottomFrom(float value, BoundType bound_type,
                                      BoundType parent_bound_type) {
  float top_offset =
      ParentLayoutObject()
          ? (ParentLayoutObject()->GetBoundTypeHeight(parent_bound_type) -
             GetBoundTypeHeight(bound_type) - value)
          : 0;
  SetBoundTopFrom(top_offset, bound_type, parent_bound_type);
}

#if ENABLE_ARK_REPLAY
void LayoutObject::GetLayoutTreeRecursive(
    rapidjson::Writer<rapidjson::StringBuffer>& writer) {
  std::vector<double> box_model = GetBoxModel();
  writer.StartObject();
  writer.Key("width");
  writer.Double(RoundToLayoutAccuracy(box_model[0]));
  writer.Key("height");
  writer.Double(RoundToLayoutAccuracy(box_model[1]));

  writer.Key("offset_top");
  writer.Double(RoundToLayoutAccuracy(offset_top_));
  writer.Key("offset_left");
  writer.Double(RoundToLayoutAccuracy(offset_left_));
  // content
  writer.Key("content");
  writer.StartArray();
  for (int i = 2; i <= 9; ++i) {
    writer.Double(RoundToLayoutAccuracy(box_model[i]));
  }
  writer.EndArray();
  // padding
  writer.Key("padding");
  writer.StartArray();
  for (int i = 10; i <= 17; ++i) {
    writer.Double(RoundToLayoutAccuracy(box_model[i]));
  }
  writer.EndArray();
  // border
  writer.Key("border");
  writer.StartArray();
  for (int i = 18; i <= 25; ++i) {
    writer.Double(RoundToLayoutAccuracy(box_model[i]));
  }
  writer.EndArray();
  // margin
  writer.Key("margin");
  writer.StartArray();
  for (int i = 26; i <= 33; ++i) {
    writer.Double(RoundToLayoutAccuracy(box_model[i]));
  }
  writer.EndArray();
  // children
  int child_size = GetChildCount();
  if (child_size > 0) {
    writer.Key("children");
    writer.StartArray();
    for (int i = 0; i < child_size; ++i) {
      auto* child = static_cast<SLNode*>(Find(i));
      child->GetLayoutTreeRecursive(writer);
    }
    writer.EndArray();
  }
  writer.EndObject();
}

const std::string LayoutObject::GetLayoutTree() {
  rapidjson::StringBuffer strBuf;
  rapidjson::Writer<rapidjson::StringBuffer> writer(strBuf);

  this->GetLayoutTreeRecursive(writer);
  return strBuf.GetString();
}
#endif
}  // namespace starlight
}  // namespace lynx
