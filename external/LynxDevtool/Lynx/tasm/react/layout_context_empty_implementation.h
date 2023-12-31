// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_LAYOUT_CONTEXT_EMPTY_IMPLEMENTATION_H_
#define LYNX_TASM_REACT_LAYOUT_CONTEXT_EMPTY_IMPLEMENTATION_H_

#include <memory>
#include <string>
#include <vector>

#include "tasm/react/layout_context.h"

namespace lynx {
namespace tasm {

class DelegateEmptyImpl : public LayoutContext::Delegate {
 public:
  virtual void OnLayoutUpdate(int tag, float x, float y, float width,
                              float height,
                              const std::array<float, 4>& paddings,
                              const std::array<float, 4>& margins,
                              const std::array<float, 4>& borders,
                              const std::array<float, 4>* sticky_positions,
                              float max_height) override {}
  virtual void OnLayoutAfter(const PipelineOptions& options,
                             std::unique_ptr<PlatformExtraBundleHolder> holder,
                             bool has_layout) override {}
  virtual void OnNodeLayoutAfter(int32_t id) override {}
  virtual void PostPlatformExtraBundle(
      int32_t id, std::unique_ptr<tasm::PlatformExtraBundle> bundle) override {}
  virtual void OnLayoutFinish(base::MoveOnlyClosure<void> callback) override {}
  virtual void OnAnimatedNodeReady(int tag) override {}
  virtual void OnCalculatedViewportChanged(const CalculatedViewport& viewport,
                                           int tag) override {}
  virtual void SetTiming(tasm::Timing timing) override {}
  virtual void OnFirstMeaningfulLayout() override {}
};

class PlatformImplEmptyImpl : public LayoutContext::PlatformImpl {
 public:
  virtual int CreateLayoutNode(int sign, intptr_t layout_node_ptr,
                               const std::string& tag, PropBundle* props,
                               bool is_parent_inline_container) override {
    return 1;
  }
  virtual void UpdateLayoutNode(int sign, PropBundle* props) override {}
  virtual void InsertLayoutNode(int parent, int child, int index) override {}
  virtual void RemoveLayoutNode(int parent, int child, int index) override {}
  virtual void MoveLayoutNode(int parent, int child, int from_index,
                              int to_index) override {}
  virtual void DestroyLayoutNodes(const std::vector<int>& ids) override {}
  virtual void ScheduleLayout(base::closure callback) override {}
  virtual void OnLayoutBefore(int sign) override {}
  virtual void OnLayout(int sign, float left, float top, float width,
                        float height) override {}
  virtual void OnLayoutFinish() override {}
  virtual void Destroy() override {}
  virtual void SetFontFaces(const CSSFontFaceTokenMap&) override {}
  virtual void OnUpdateDataWithoutChange() override {}
};

}  // namespace tasm
}  // namespace lynx
#endif  // LYNX_TASM_REACT_LAYOUT_CONTEXT_EMPTY_IMPLEMENTATION_H_
