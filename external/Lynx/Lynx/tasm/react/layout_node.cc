// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/react/layout_node.h"

#include <utility>

#include "starlight/style/computed_css_style.h"

namespace lynx {
namespace tasm {

#define FOREACH_LAYOUT_PROPERTY(V)    \
  V(Top, LAYOUT_ONLY)                 \
  V(Left, LAYOUT_ONLY)                \
  V(Right, LAYOUT_ONLY)               \
  V(Bottom, LAYOUT_ONLY)              \
  V(Width, LAYOUT_ONLY)               \
  V(MaxWidth, LAYOUT_ONLY)            \
  V(MinWidth, LAYOUT_ONLY)            \
  V(Height, LAYOUT_ONLY)              \
  V(MaxHeight, LAYOUT_ONLY)           \
  V(MinHeight, LAYOUT_ONLY)           \
  V(PaddingLeft, LAYOUT_ONLY)         \
  V(PaddingRight, LAYOUT_ONLY)        \
  V(PaddingTop, LAYOUT_ONLY)          \
  V(PaddingBottom, LAYOUT_ONLY)       \
  V(MarginLeft, LAYOUT_ONLY)          \
  V(MarginRight, LAYOUT_ONLY)         \
  V(MarginTop, LAYOUT_ONLY)           \
  V(MarginBottom, LAYOUT_ONLY)        \
  V(BorderLeftWidth, LAYOUT_WANTED)   \
  V(BorderRightWidth, LAYOUT_WANTED)  \
  V(BorderTopWidth, LAYOUT_WANTED)    \
  V(BorderBottomWidth, LAYOUT_WANTED) \
  V(FlexBasis, LAYOUT_ONLY)           \
  V(FlexGrow, LAYOUT_ONLY)            \
  V(FlexShrink, LAYOUT_ONLY)          \
  V(LinearWeightSum, LAYOUT_ONLY)     \
  V(LinearWeight, LAYOUT_ONLY)        \
  V(AspectRatio, LAYOUT_ONLY)         \
  V(RelativeId, LAYOUT_ONLY)          \
  V(RelativeAlignTop, LAYOUT_ONLY)    \
  V(RelativeAlignRight, LAYOUT_ONLY)  \
  V(RelativeAlignBottom, LAYOUT_ONLY) \
  V(RelativeAlignLeft, LAYOUT_ONLY)   \
  V(RelativeTopOf, LAYOUT_ONLY)       \
  V(RelativeRightOf, LAYOUT_ONLY)     \
  V(RelativeBottomOf, LAYOUT_ONLY)    \
  V(RelativeLeftOf, LAYOUT_ONLY)      \
  V(RelativeLayoutOnce, LAYOUT_ONLY)  \
  V(Order, LAYOUT_ONLY)               \
  V(Flex, LAYOUT_ONLY)                \
  V(BorderWidth, LAYOUT_WANTED)       \
  V(Padding, LAYOUT_ONLY)             \
  V(Margin, LAYOUT_ONLY)              \
  V(Border, LAYOUT_WANTED)            \
  V(BorderRight, LAYOUT_WANTED)       \
  V(BorderLeft, LAYOUT_WANTED)        \
  V(BorderTop, LAYOUT_WANTED)         \
  V(BorderBottom, LAYOUT_WANTED)      \
  V(Flex, LAYOUT_ONLY)                \
  V(FlexDirection, LAYOUT_ONLY)       \
  V(FlexWrap, LAYOUT_ONLY)            \
  V(AlignItems, LAYOUT_ONLY)          \
  V(AlignSelf, LAYOUT_ONLY)           \
  V(AlignContent, LAYOUT_ONLY)        \
  V(JustifyContent, LAYOUT_ONLY)      \
  V(LinearOrientation, LAYOUT_ONLY)   \
  V(LinearLayoutGravity, LAYOUT_ONLY) \
  V(LinearGravity, LAYOUT_ONLY)       \
  V(LinearCrossGravity, LAYOUT_ONLY)  \
  V(RelativeCenter, LAYOUT_ONLY)      \
  V(Position, LAYOUT_ONLY)            \
  V(Display, LAYOUT_ONLY)             \
  V(BoxSizing, LAYOUT_ONLY)           \
  V(Content, LAYOUT_ONLY)             \
  V(Direction, LAYOUT_WANTED)         \
  V(GridTemplateColumns, LAYOUT_ONLY) \
  V(GridTemplateRows, LAYOUT_ONLY)    \
  V(GridAutoColumns, LAYOUT_ONLY)     \
  V(GridAutoRows, LAYOUT_ONLY)        \
  V(GridColumnSpan, LAYOUT_ONLY)      \
  V(GridRowSpan, LAYOUT_ONLY)         \
  V(GridColumnStart, LAYOUT_ONLY)     \
  V(GridColumnEnd, LAYOUT_ONLY)       \
  V(GridRowStart, LAYOUT_ONLY)        \
  V(GridRowEnd, LAYOUT_ONLY)          \
  V(GridColumnGap, LAYOUT_ONLY)       \
  V(GridRowGap, LAYOUT_ONLY)          \
  V(JustifyItems, LAYOUT_ONLY)        \
  V(JustifySelf, LAYOUT_ONLY)         \
  V(GridAutoFlow, LAYOUT_ONLY)        \
  V(ListCrossAxisGap, LAYOUT_WANTED)  \
  V(LinearDirection, LAYOUT_ONLY)     \
  V(VerticalAlign, LAYOUT_WANTED)
LayoutNode::LayoutNode(int id, const starlight::LayoutConfigs& layout_configs,
                       const tasm::LynxEnvConfig& envs,
                       const starlight::ComputedCSSStyle& init_style)
    : type_(LayoutNodeType::COMMON), id_(id) {
  sl_node_ = std::make_unique<SLNode>(layout_configs, envs, init_style);
}

LayoutNode::~LayoutNode() { sl_node_ = nullptr; }

void LayoutNode::ConsumeStyle(CSSPropertyID id, const tasm::CSSValue& value,
                              bool reset) {
  if (sl_node_->GetCSSMutableStyle()->SetValue(id, value, reset)) {
    sl_node_->MarkDirty();
  }
}

void LayoutNode::ConsumeAttribute(starlight::LayoutAttribute key,
                                  const lepus::Value& value, bool reset) {
  lepus::Value new_value = reset ? lepus::Value() : value;
  if (sl_node_->SetAttribute(key, new_value)) {
    if (is_list()) {
      sl_node_->MarkChildrenDirtyWithoutTriggerLayout();
    }
    sl_node_->MarkDirty();
  }
}

void LayoutNode::ConsumeFontSize(double cur_node_font_size,
                                 double root_node_font_size,
                                 double font_scale) {
  if (sl_node_->GetCSSMutableStyle()->SetFontSize(cur_node_font_size,
                                                  root_node_font_size) ||
      sl_node_->GetCSSMutableStyle()->SetFontScale(font_scale)) {
    sl_node_->MarkDirty();
  }
}

void LayoutNode::InsertNode(const std::shared_ptr<LayoutNode>& child,
                            int index) {
  // Inline views should be bind to non-virtual parent layoutobject.
  if (is_virtual() && !child->is_virtual()) {
    LayoutNode* parent = FindNonVirtualNode();
    parent->slnode()->AppendChild(child->slnode());
  }

  if (index == -1) {
    if (!child->is_virtual() && !is_virtual()) {
      sl_node_->AppendChild(child->slnode());
    }
    MarkDirty();
    children_.push_back(child);
  } else {
    if (!child->is_virtual() && !is_virtual()) {
      LayoutNode* previous_non_virtual_child = FindNextNonVirtualChild(index);
      sl_node_->InsertChildBefore(child->slnode(),
                                  previous_non_virtual_child
                                      ? previous_non_virtual_child->slnode()
                                      : nullptr);
    }
    MarkDirty();
    auto iter = children_.begin();
    std::advance(iter, index);
    children_.insert(iter, child);
  }
  child->parent_ = this;
}

void LayoutNode::RemoveNode(const std::shared_ptr<LayoutNode>& child,
                            unsigned int index) {
  if (index >= children_.size()) return;

  // Remove inline views from non-virtual parent node.
  if (is_virtual() && !child->is_virtual()) {
    LayoutNode* parent = FindNonVirtualNode();
    parent->slnode()->RemoveChild(child->slnode());
  }

  auto iter = children_.begin();
  std::advance(iter, index);
  if (!child->is_virtual() && !is_virtual()) {
    sl_node_->RemoveChild((*iter)->slnode());
  }
  MarkDirty();
  children_.erase(iter);
  child->parent_ = nullptr;
}

void LayoutNode::MoveNode(const std::shared_ptr<LayoutNode>& child,
                          int from_index, unsigned int to_index) {
  RemoveNode(child, from_index);
  InsertNode(child, to_index);
}

void LayoutNode::SetLayoutHasBaselineRecursively(
    const std::shared_ptr<LayoutNode>& parent) {
  parent->slnode()->SetBaselineFlag(true);
  for (auto& child : parent->children()) {
    if (!child->children().empty()) {
      SetLayoutHasBaselineRecursively(child);
    } else {
      child->slnode()->SetBaselineFlag(true);
    }
  }
}

void LayoutNode::CalculateLayout() {
  sl_node_->ReLayout(0, 0, static_cast<int>(10E7), static_cast<int>(10E7));
}

LayoutNode* LayoutNode::FindNonVirtualNode() {
  if (!is_virtual()) {
    return this;
  }
  LayoutNode* temp = parent_;
  while (temp && temp->is_virtual()) {
    temp = temp->parent_;
  }
  return temp;
}

LayoutNode* LayoutNode::FindNextNonVirtualChild(
    size_t equal_or_after_index) const {
  auto iter = children_.begin();
  std::advance(iter, equal_or_after_index);
  for (auto current_index = iter; current_index != children_.end();
       ++current_index) {
    if (!(*current_index)->is_virtual()) {
      return (*current_index).get();
    }
  }
  return nullptr;
}

FloatSize LayoutNode::UpdateMeasureByPlatform(
    const starlight::Constraints& constraints, bool final_measure) {
  if (!slnode()) {
    return FloatSize{0.f, 0.f, 0.f};
  }

  // FIXME(liting): final measure always true will increase layout time.
  return slnode()->UpdateMeasureByPlatform(constraints, true);
}

void LayoutNode::AlignmentByPlatform(float offset_top, float offset_left) {
  if (!slnode()) {
    return;
  }

  slnode()->AlignmentByPlatform(offset_top, offset_left);
}

void LayoutNode::SetMeasureFunc(std::unique_ptr<MeasureFunc> measure_func) {
  measure_func_ = std::move(measure_func);

  sl_node_->SetContext(this);
  sl_node_->SetSLMeasureFunc([](void* context,
                                const starlight::Constraints& constraints,
                                bool final_measure) {
    MeasureFunc* measure = (static_cast<LayoutNode*>(context))->measure_func();
    DCHECK(measure);
    return measure->Measure(
        constraints, final_measure,
        (static_cast<LayoutNode*>(context))->slnode()->GetBaselineFlag());
  });
  sl_node_->SetSLAlignmentFunc([](void* context) {
    MeasureFunc* measure = (static_cast<LayoutNode*>(context))->measure_func();
    DCHECK(measure);
    measure->Alignment();
  });
}

ConsumptionStatus LayoutNode::ConsumptionTest(CSSPropertyID id) {
  static int kWantedProperty[kPropertyEnd];
  static bool kIsInit = false;
  if (!kIsInit) {
    kIsInit = true;
    std::fill(kWantedProperty, kWantedProperty + kPropertyEnd,
              ConsumptionStatus::SKIP);
#define DECLARE_WANTED_PROPERTY(name, type) \
  kWantedProperty[kPropertyID##name] = type;
    FOREACH_LAYOUT_PROPERTY(DECLARE_WANTED_PROPERTY)
#undef DECLARE_WANTED_PROPERTY
  }
  return static_cast<ConsumptionStatus>(kWantedProperty[id]);
}

void LayoutNode::set_type(LayoutNodeType type) {
  type_ = type;
  if (is_list()) sl_node_->MarkList();
}

bool LayoutNode::IsDirty() {
  return is_dirty_ || (slnode() && slnode()->IsDirty());
}

void LayoutNode::MarkDirty() { MarkDirtyInternal(false); }

void LayoutNode::MarkDirtyAndRequestLayout() { MarkDirtyInternal(true); }

void LayoutNode::MarkDirtyInternal(bool request_layout) {
  if (is_dirty_) {
    return;
  }
  if (!is_virtual()) {
    if (sl_node_) {
      if (request_layout) {
        sl_node_->MarkDirtyAndRequestLayout();
      } else {
        sl_node_->MarkDirty();
      }
    }
  } else {
    LayoutNode* node = FindNonVirtualNode();
    if (node && node->sl_node_) {
      if (request_layout) {
        node->sl_node_->MarkDirtyAndRequestLayout();
      } else {
        node->sl_node_->MarkDirty();
      }
    }
  }
  is_dirty_ = true;
}

void LayoutNode::MarkUpdated() {
  is_dirty_ = false;
  if (!is_virtual()) {
    sl_node_->MarkUpdated();
  }
}

void LayoutNode::SetTag(lepus::String tag) {
  tag_ = tag;
  if (sl_node_) {
    sl_node_->SetTag(tag);
  }
}

#undef FOREACH_LAYOUT_PROPERTY
}  // namespace tasm
}  // namespace lynx
