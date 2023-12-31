// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_LAYOUT_NODE_H_
#define LYNX_TASM_REACT_LAYOUT_NODE_H_

#include <list>
#include <memory>
#include <set>
#include <vector>

#include "css/css_property.h"
#include "lepus/string_util.h"
#include "starlight/layout/layout_global.h"
#include "starlight/layout/layout_object.h"
#include "starlight/types/layout_measurefunc.h"
#include "starlight/types/layout_performance.h"
namespace lynx {
namespace tasm {

class LayoutContext;

// FIXME(zhixuan): Layout type flags is a mess now, we should refactor it
enum LayoutNodeType {
  // Common node will not have corresponding platform layout node
  COMMON = 1,
  // The layout of virtual node will be handle by its parent which has custom
  // layout instead of layout engine
  VIRTUAL = 1 << 1,
  // Node has custom layout
  CUSTOM = 1 << 2,
  // Children of this node will not be layouted.
  LIST = 1 << 4,
  // Node is inline and should be measured by native
  INLINE = 1 << 5,
  // Node has platform attached
  PLATFORM_NODE_ATTACHED = 1 << 6,
};

enum ConsumptionStatus { LAYOUT_ONLY = 0, LAYOUT_WANTED = 1, SKIP = 2 };

class MeasureFunc {
 public:
  virtual ~MeasureFunc() = default;
  virtual FloatSize Measure(const starlight::Constraints& constraints,
                            bool final_measure, bool baseline_flag) = 0;
  virtual void Alignment() = 0;
};

class LayoutNode {
 public:
  explicit LayoutNode(int id, const starlight::LayoutConfigs& layout_configs,
                      const tasm::LynxEnvConfig& envs,
                      const starlight::ComputedCSSStyle& init_style);
  virtual ~LayoutNode();

  static ConsumptionStatus ConsumptionTest(CSSPropertyID id);
  inline static bool IsLayoutOnly(CSSPropertyID id) {
    return ConsumptionTest(id) == LAYOUT_ONLY;
  }
  inline static bool IsLayoutWanted(CSSPropertyID id) {
    return ConsumptionTest(id) == LAYOUT_WANTED;
  }

  // interface of  inline view
  FloatSize UpdateMeasureByPlatform(const starlight::Constraints& constraints,
                                    bool final_measure);
  void AlignmentByPlatform(float offset_top, float offset_left);

  void SetLayoutHasBaselineRecursively(
      const std::shared_ptr<LayoutNode>& parent);
  void CalculateLayout();
  void SetMeasureFunc(std::unique_ptr<MeasureFunc> measure_func);
  void InsertNode(const std::shared_ptr<LayoutNode>& child, int index = -1);
  void RemoveNode(const std::shared_ptr<LayoutNode>& child, unsigned int index);
  void MoveNode(const std::shared_ptr<LayoutNode>& child, int from_index,
                unsigned int to_index);
  void ConsumeFontSize(double cur_node_font_size, double root_node_font_size,
                       double font_scale);
  void ConsumeStyle(CSSPropertyID id, const tasm::CSSValue& value,
                    bool reset = false);
  void ConsumeAttribute(const starlight::LayoutAttribute key,
                        const lepus::Value& value, bool reset = false);

  inline LayoutNode* parent() const { return parent_; }
  inline SLNode* slnode() const { return sl_node_.get(); }
  inline const std::list<std::shared_ptr<LayoutNode>>& children() {
    return children_;
  }
  inline bool is_virtual() { return type_ & LayoutNodeType::VIRTUAL; }
  inline bool is_common() { return type_ & LayoutNodeType::COMMON; }
  inline bool is_custom() { return type_ & LayoutNodeType::CUSTOM; }
  inline bool is_list() { return type_ & LayoutNodeType::LIST; }
  inline bool is_inline_view() { return type_ & LayoutNodeType::INLINE; };
  inline bool is_platformed_node_attached() {
    return type_ & LayoutNodeType::PLATFORM_NODE_ATTACHED;
  }
  inline MeasureFunc* measure_func() { return measure_func_.get(); };
  inline int id() { return id_; }
  void set_type(LayoutNodeType type);
  void SetParentIsInlineContainer(bool is_parent_inline_view_container) {
    is_parent_inline_view_container_ = is_parent_inline_view_container;
  }
  bool IsParentInlineContainer() { return is_parent_inline_view_container_; }
  bool IsDirty();
  void MarkDirty();
  void MarkDirtyAndRequestLayout();
  void CleanDirty();
  void MarkUpdated();
  LayoutNode* FindNonVirtualNode();
  LayoutNode* FindNextNonVirtualChild(size_t before_index) const;
  std::vector<starlight::LayoutPref> GetLayoutPerfList() {
    return slnode()->GetAndClearLayoutPerfList();
  }

  /**
   *  if layout_node should notify platform node layout finished.
   *  example: when node has animation or transform.That may need layout info to
   * render or do animation even layout info not change.
   */
  bool IsAnimated() { return animated_; }

  void MarkIsAnimated(bool animated) {
    animated_ = animated;
    if (animated_) {
      MarkDirty();
    }
  }

  void SetTag(lepus::String tag);

 protected:
  bool is_dirty_ = false;
  LayoutNodeType type_;
  std::unique_ptr<SLNode> sl_node_;
  std::list<std::shared_ptr<LayoutNode>> children_;
  LayoutNode* parent_ = nullptr;
  std::unique_ptr<MeasureFunc> measure_func_;

  lepus::String tag_;
  bool is_parent_inline_view_container_{false};

 private:
  int id_;
  bool animated_{false};

  LayoutNode(const LayoutNode&) = delete;
  LayoutNode& operator=(const LayoutNode&) = delete;
  void MarkDirtyInternal(bool request_layout);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_LAYOUT_NODE_H_
