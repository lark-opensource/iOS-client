// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_LAYOUT_OBJECT_H_
#define LYNX_STARLIGHT_LAYOUT_LAYOUT_OBJECT_H_

#include <assert.h>

#include <array>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "base/position.h"
#include "config/config.h"
#include "lepus/lepus_string.h"
#include "lepus/value-inl.h"
#include "lepus/value.h"
#include "starlight/layout/cache_manager.h"
#include "starlight/layout/container_node.h"
#include "starlight/layout/layout_global.h"
#include "starlight/style/computed_css_style.h"
#include "starlight/types/layout_measurefunc.h"
#include "starlight/types/layout_performance.h"
#include "starlight/types/layout_types.h"

#if ENABLE_ARK_REPLAY
#include "third_party/rapidjson/prettywriter.h"
#include "third_party/rapidjson/stringbuffer.h"
#endif

namespace lynx {
namespace starlight {
class BoxInfo;
class LayoutAlgorithm;

enum class BoundType { kContent, kPadding, kBorder, kMargin };

class LayoutObject : public ContainerNode {
 public:
  LayoutObject(const LayoutConfigs& config, const tasm::LynxEnvConfig& envs,
               const starlight::ComputedCSSStyle& init_style);
  virtual ~LayoutObject();

  void Reset(LayoutObject* node);

  inline const LayoutConfigs& GetLayoutConfigs() const { return configs_; }
  void SetContext(void* context);
  void* GetContext() const;
  void SetSLMeasureFunc(SLMeasureFunc measure_func);
  SLMeasureFunc GetSLMeasureFunc() const;
  void SetSLRequestLayoutFunc(SLRequestLayoutFunc request_layout_func);
  void SetSLAlignmentFunc(SLAlignmentFunc alignment_func);
  SLAlignmentFunc GetSLAlignmentFunc() const;

  FloatSize UpdateMeasureByPlatform(const Constraints& constraints,
                                    bool final_measure);
  void AlignmentByPlatform(float offset_top, float offset_left);

  void MarkDirtyRecursion();

  virtual void MarkDirtyAndRequestLayout();
  virtual void MarkDirty();
  void MarkChildrenDirtyWithoutTriggerLayout();
  bool IsDirty();

  void MarkUpdated();
  bool GetHasNewLayout() const;

  bool GetFinalMeasure() const { return final_measure_; }

  const ComputedCSSStyle* GetCSSStyle() const { return css_style_.get(); }
  ComputedCSSStyle* GetCSSMutableStyle() { return css_style_.get(); }
  void set_css_style(ComputedCSSStyle& css_style) {
    css_style_.reset(&css_style);
  }
  virtual bool SetStyle(tasm::CSSPropertyID key, const tasm::CSSValue& value);
  virtual bool SetAttribute(const LayoutAttribute key,
                            const lepus::Value& value);
  inline AttributesMap& attr_map() { return attr_map_; }

  const base::Position& measured_position() { return measured_position_; }

  bool DoesLayoutDependOnHorizontalPercentBase();
  bool DoesLayoutDependOnVerticalPercentBase();

  const LayoutResultForRendering& GetLayoutResult() const {
    return layout_result_;
  }
  bool IsList() { return is_list_; }

  // Position is with respect to top-left of parent's padding bound by default
  void SetBorderBoundTopFromParentPaddingBound(float top);
  void SetBorderBoundLeftFromParentPaddingBound(float left);
  // Position is with respect to top-left of parent's padding bound by default
  void SetBorderBoundWidth(float width);
  void SetBorderBoundHeight(float height);
  void SetBaseline(float baseline);
  inline void SetBaselineFlag(bool flag) { baseline_flag_ = flag; }

  inline float GetBorderBoundTopFromParentPaddingBound() const {
    return offset_top_;
  }
  inline float GetBorderBoundLeftFromParentPaddingBound() const {
    return offset_left_;
  }
  LayoutObject* ParentLayoutObject() {
    return static_cast<LayoutObject*>(parent_);
  }
  const LayoutObject* ParentLayoutObject() const {
    return static_cast<const LayoutObject*>(parent_);
  }
  inline float GetBorderBoundWidth() const { return offset_width_; }
  inline float GetBorderBoundHeight() const { return offset_height_; }
  inline float GetBaseline() const {
    return HasBaseline() ? offset_baseline_ : offset_height_;
  }
  inline bool GetBaselineFlag() const { return baseline_flag_; }
  float GetContentBoundWidth() const;
  float GetContentBoundHeight() const;
  float GetMarginBoundWidth() const;
  float GetMarginBoundHeight() const;
  float GetPaddingBoundWidth() const;
  float GetPaddingBoundHeight() const;
  float GetBoundTypeWidth(BoundType type) const;
  float GetBoundTypeHeight(BoundType type) const;

  inline bool HasBaseline() const { return !base::IsZero(offset_baseline_); }

  // Return the top/left offset of requested bound from specified parent bound
  // param bound_type: the type of bound that the offset is referred to
  // param parent_bound_type: type of parent bound from which the offset is
  // calculated.
  //
  // For example, if input is (BoundType:kBorder, BoundType:kContent)
  // The functions will return the top/left offset from parent content bound to
  // current border bound
  float GetBoundTopFrom(BoundType bound_type,
                        BoundType parent_bound_type) const;
  float GetBoundLeftFrom(BoundType bound_type,
                         BoundType parent_bound_type) const;

  // Set the top/left offset of requested bound from specified parent bound
  // param value: the value of offset to set
  // param bound_type: the type of bound that the offset is referred to
  // param parent_bound_type: type of parent bound from which the offset is
  // calculated.
  //
  // For example, if input is (30.f, BoundType:kBorder, BoundType:kContent)
  // The offset from parent content bound to top/left of current border will be
  // set to 30.f
  void SetBoundTopFrom(float value, BoundType bound_type,
                       BoundType parent_bound_type);
  void SetBoundLeftFrom(float value, BoundType bound_type,
                        BoundType parent_bound_type);
  void SetBoundRightFrom(float value, BoundType bound_type,
                         BoundType parent_bound_type);
  void SetBoundBottomFrom(float value, BoundType bound_type,
                          BoundType parent_bound_type);

  void ClearCache();

#define LAYOUT_OBJECT_GET_RESULT(name) \
  BASE_EXPORT_FOR_DEVTOOL float GetLayout##name() const;
  LAYOUT_OBJECT_GET_RESULT(PaddingLeft)
  LAYOUT_OBJECT_GET_RESULT(PaddingTop)
  LAYOUT_OBJECT_GET_RESULT(PaddingRight)
  LAYOUT_OBJECT_GET_RESULT(PaddingBottom)
  LAYOUT_OBJECT_GET_RESULT(MarginLeft)
  LAYOUT_OBJECT_GET_RESULT(MarginRight)
  LAYOUT_OBJECT_GET_RESULT(MarginTop)
  LAYOUT_OBJECT_GET_RESULT(MarginBottom)
  LAYOUT_OBJECT_GET_RESULT(BorderLeftWidth)
  LAYOUT_OBJECT_GET_RESULT(BorderTopWidth)
  LAYOUT_OBJECT_GET_RESULT(BorderRightWidth)
  LAYOUT_OBJECT_GET_RESULT(BorderBottomWidth)
#undef LAYOUT_OBJECT_GET_RESULT

  BoxInfo* GetBoxInfo() const;

  float ClampExactWidth(float width) const;
  float ClampExactHeight(float height) const;

  float GetInnerWidthFromBorderBoxWidth(float width) const;
  float GetInnerHeightFromBorderBoxHeight(float height) const;
  float GetOuterWidthFromBorderBoxWidth(float width) const;
  float GetOuterHeightFromBorderBoxHeight(float height) const;

  float GetBorderBoxWidthFromInnerWidth(float inner_width) const;
  float GetBorderBoxHeightFromInnerHeight(float inner_height) const;

  void ReLayout(int left, int top, int right, int bottom);
  virtual FloatSize UpdateMeasure(const Constraints& constraints,
                                  bool final_measure);
  virtual void UpdateAlignment();
  void LayoutDisplayNone();
  std::vector<double> GetBoxModel();

  inline float pos_left() const { return pos_left_; }
  inline float pos_right() const { return pos_right_; }
  inline float pos_top() const { return pos_top_; }
  inline float pos_bottom() const { return pos_bottom_; }

  bool IsSticky() const {
    return css_style_->GetPosition() == PositionType::kSticky;
  }
  void UpdatePositions(float left, float top, float right, float bottom);

  float GetPaddingAndBorderHorizontal() const;
  float GetPaddingAndBorderVertical() const;

  void MarkList() { is_list_ = true; }
  bool IsAbsoluteInContentBound() const {
    return configs_.is_absolute_in_content_bound_;
  }

  // TODO(liting): Hack!!.Delete this when css refactoring
  float ScreenWidth() const { return screen_width_; }
  void UpdateLynxEnv(const tasm::LynxEnvConfig& config);

  bool IsInflowSubTreeInSyncWithLastMeasurement() const {
    return inflow_sub_tree_in_sync_with_last_measurement_;
  }

  std::vector<LayoutPref> GetAndClearLayoutPerfList() {
    return std::move(layout_perf_list_);
  }

  void SetTag(lepus::String tag) { tag_ = tag; }

  lepus::String GetTag() const { return tag_; }

#if ENABLE_ARK_REPLAY
  void GetLayoutTreeRecursive(
      rapidjson::Writer<rapidjson::StringBuffer>& writer);

  const std::string GetLayoutTree();
  double RoundToLayoutAccuracy(float value) {
    double result = std::round(value * 100) / 100.0;
    // The result may be -0.0 or 0.0,
    // the two values behave as equal in numerical comparisons.
    // In this case, to ensure consistent printing, return 0 uniformly.
    if (base::FloatsEqual(result, 0.0)) {
      result = 0.0;
    }
    return result;
  }
#endif
 protected:
  void MarkDirtyWithoutResetCache();
  void MarkHasNewLayout();
  void MarkDirtyInternal(bool request_layout);
  bool SetNewLayoutResult(LayoutResultForRendering new_result);
  void HideLayoutObject();
  void UpdateSize(float width, float height);
  void RoundToPixelGrid(const float container_absolute_left,
                        const float container_absolute_top,
                        const float container_rounded_left,
                        const float container_rounded_top,
                        bool ancestors_have_new_layout);

  void UpdateMeasureWithMeasureFunc(const Constraints& constraints,
                                    bool final_measure);

  void UpdateMeasureWithLeafNode(const Constraints& constraints);

  void RemoveAlgorithm();
  void RemoveAlgorithmRecursive();

  void RecordLayoutPerf(uint64_t start_time, bool has_cache,
                        bool final_measure);

  base::Position measured_position_;

  // TODO(liting): Hack!.delete this when css refactoring
  // init by constructor and update by UpdateScreenWidth.
  float screen_width_;

  SLMeasureFunc measure_func_;
  SLRequestLayoutFunc request_layout_func_;
  SLAlignmentFunc alignment_func_;
  void* context_ = nullptr;

  float offset_top_;
  float offset_left_;
  float offset_width_;
  float offset_height_;
  float offset_baseline_;

  std::unique_ptr<BoxInfo> box_info_;
  LayoutAlgorithm* algorithm_;

  AttributesMap attr_map_;

  float pos_left_;
  float pos_right_;
  float pos_top_;
  float pos_bottom_;

  std::unique_ptr<ComputedCSSStyle> css_style_;
  bool is_dirty_;
  bool current_node_has_new_layout_;
  bool is_first_layout_;

  bool final_measure_ = false;
  bool is_list_ = false;
  bool baseline_flag_;
  const LayoutConfigs configs_;

  lepus::String tag_;

  bool inflow_sub_tree_in_sync_with_last_measurement_ = false;

  bool FetchEarlyReturnResultForMeasure(const Constraints& constraints,
                                        bool is_trying, FloatSize& result);

  CacheManager cache_manager_;
  LayoutResultForRendering layout_result_;

  // for light house
  std::vector<LayoutPref> layout_perf_list_;
};

}  // namespace starlight

typedef starlight::LayoutObject SLNode;

}  // namespace lynx

#endif  // LYNX_STARLIGHT_LAYOUT_LAYOUT_OBJECT_H_
