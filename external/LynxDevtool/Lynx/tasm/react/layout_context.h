// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_LAYOUT_CONTEXT_H_
#define LYNX_TASM_REACT_LAYOUT_CONTEXT_H_

#include <memory>
#include <queue>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

#include "base/closure.h"
#include "config/config.h"
#include "tasm/lynx_env_config.h"
#include "tasm/react/dynamic_css_styles_manager.h"
#include "tasm/react/layout_node.h"
#include "tasm/react/platform_extra_bundle.h"
#include "tasm/react/prop_bundle.h"

namespace lynx {
namespace tasm {

struct Viewport {
  float width;
  float height;
  int width_mode;
  int height_mode;

  inline void UpdateViewport(float width, int width_mode, float height,
                             int height_mode) {
    this->width = width;
    this->height = height;
    this->width_mode = width_mode;
    this->height_mode = height_mode;
  }
};

struct CalculatedViewport {
  float width = 0;
  float height = 0;
};

using RequestLayoutCallback = base::MoveOnlyClosure<void>;

class HierarchyObserver;
class LayoutContext : public std::enable_shared_from_this<LayoutContext> {
 public:
  class Delegate {
   public:
    Delegate() {}
    virtual ~Delegate() {}
    virtual void OnLayoutUpdate(int tag, float x, float y, float width,
                                float height,
                                const std::array<float, 4>& paddings,
                                const std::array<float, 4>& margins,
                                const std::array<float, 4>& borders,
                                const std::array<float, 4>* sticky_positions,
                                float max_height) = 0;
    void OnLayoutAfter(const PipelineOptions& options) {
      OnLayoutAfter(options, nullptr, false);
    };
    virtual void OnLayoutAfter(
        const PipelineOptions& options,
        std::unique_ptr<PlatformExtraBundleHolder> holder, bool has_layout) = 0;
    virtual void OnNodeLayoutAfter(int32_t id) = 0;
    virtual void PostPlatformExtraBundle(
        int32_t id, std::unique_ptr<tasm::PlatformExtraBundle> bundle) = 0;
    virtual void OnLayoutFinish(base::MoveOnlyClosure<void> callback) = 0;
    virtual void OnAnimatedNodeReady(int tag) = 0;
    virtual void OnCalculatedViewportChanged(const CalculatedViewport& viewport,
                                             int tag) = 0;
    virtual void SetTiming(tasm::Timing timing) = 0;
    virtual void Report(
        std::vector<std::unique_ptr<tasm::PropBundle>> stack) = 0;
    virtual void OnFirstMeaningfulLayout() = 0;
  };

  class PlatformImpl {
   public:
    virtual ~PlatformImpl() {}
    virtual int CreateLayoutNode(int id, intptr_t layout_node_ptr,
                                 const std::string& tag, PropBundle* props,
                                 bool is_parent_inline_container) = 0;
    virtual void UpdateLayoutNode(int id, PropBundle* props) = 0;
    virtual void InsertLayoutNode(int parent, int child, int index) = 0;
    virtual void RemoveLayoutNode(int parent, int child, int index) = 0;
    virtual void MoveLayoutNode(int parent, int child, int from_index,
                                int to_index) = 0;
    virtual void DestroyLayoutNodes(const std::vector<int>& ids) = 0;
    virtual void ScheduleLayout(base::closure callback) = 0;
    virtual void OnLayoutBefore(int id) = 0;
    virtual void OnLayout(int id, float left, float top, float width,
                          float height) = 0;
    virtual void OnLayoutFinish() = 0;
    virtual void Destroy() = 0;

    virtual void OnUpdateDataWithoutChange() = 0;
    virtual void SetFontFaces(const CSSFontFaceTokenMap& fontfaces) = 0;
    virtual void UpdateRootSize(float width, float height) {}
    virtual std::unique_ptr<PlatformExtraBundle> GetPlatformExtraBundle(
        int32_t id) {
      return std::unique_ptr<PlatformExtraBundle>();
    }
    virtual std::unique_ptr<PlatformExtraBundleHolder>
    ReleasePlatformBundleHolder() {
      return std::unique_ptr<PlatformExtraBundleHolder>();
    }
  };

  LayoutContext(std::unique_ptr<Delegate> delegate,
                std::unique_ptr<PlatformImpl> platform_impl, int32_t trace_id);
  virtual ~LayoutContext();

  typedef const std::shared_ptr<LayoutNode>& SPLayoutNode;
  void UpdateLayoutNodeProps(SPLayoutNode node,
                             const std::shared_ptr<PropBundle>& props);
  void UpdateLayoutNodeFontSize(SPLayoutNode node, double cur_node_font_size,
                                double root_node_font_size, double font_scale);
  void UpdateLayoutNodeStyle(SPLayoutNode node, CSSPropertyID css_id,
                             const tasm::CSSValue& value);
  void ResetLayoutNodeStyle(SPLayoutNode node, CSSPropertyID css_id);
  void UpdateLayoutNodeAttribute(SPLayoutNode node,
                                 starlight::LayoutAttribute key,
                                 const lepus::Value& value);
  void ResetLayoutNodeAttribute(SPLayoutNode node,
                                starlight::LayoutAttribute key);
  void InsertLayoutNode(SPLayoutNode parent, SPLayoutNode child, int index);
  void RemoveLayoutNode(SPLayoutNode parent, SPLayoutNode child, int index,
                        bool destroy = true);
  void MoveLayoutNode(SPLayoutNode parent, SPLayoutNode child, int from_index,
                      int to_index);
  void InsertLayoutNodeBefore(SPLayoutNode parent, SPLayoutNode child,
                              SPLayoutNode ref_node);
  void RemoveLayoutNode(SPLayoutNode parent, SPLayoutNode child);
  void DestroyLayoutNode(SPLayoutNode node);
  void DispatchLayoutUpdates(const PipelineOptions& options);
  void DispatchLayoutHasBaseline();

  void SetEnableLayout();

  void SetFontFaces(const CSSFontFaceTokenMap& fontfaces);

  // FIXME(zhixuan): This is a temporary solution to safe guard the memory
  // of the native layout node that attached to the platform node.
  void RegisterPlatformAttachedLayoutNode(SPLayoutNode node);

  // Thread safe
  void Layout(const PipelineOptions& options);
  void UpdateViewport(float width, int width_mode, float height,
                      int height_mode, bool need_layout = true);

  // Thread unsafe
  void SetRoot(std::shared_ptr<LayoutNode> root);

  inline LayoutNode* root() { return root_.get(); }

  inline void SetHierarchyObserver(
      const std::weak_ptr<HierarchyObserver>& hierarchy_observer) {
    hierarchy_observer_ = hierarchy_observer;
  }

  inline int root_id() { return root_->id(); }

  inline const Viewport& GetViewPort() const { return viewport_; }

  void MarkNodeAnimated(SPLayoutNode node, bool animated);
  void OnUpdateDataWithoutChange();
  void UpdateLynxEnvForLayoutThread(LynxEnvConfig env);

  void UpdateLayoutInfo(LayoutNode* node);

  void OnAnimatedNodeReady(LayoutNode* node);
  void SetRequestLayoutCallback(RequestLayoutCallback callback) {
    request_layout_callback_ = std::move(callback);
  }

  std::weak_ptr<PlatformImpl> GetWeakPlatformImpl() const {
    return std::weak_ptr<PlatformImpl>(platform_impl_);
  }

  // report all tracker events to native facade.
  void Report(std::vector<std::unique_ptr<tasm::PropBundle>> stack);

 private:
  class CircularLayoutDependencyDetector {
   public:
    static constexpr int64_t kTimeWindow = 60000;  // 1min
    static constexpr int64_t kContinuousViewportUpdateMaxGap = 50;
    void DetectCircularLayoutDependency();

   private:
    bool in_error_state_ = false;
    int64_t continuous_viewport_update_start_time_ = -1;
    int64_t last_viewport_update_time_ = -1;
  };
  CircularLayoutDependencyDetector circular_layout_detector_;

  // Should be call on the thread that layout engine work on
  void RequestLayout(const PipelineOptions& options = {});
  void DispatchLayoutBeforeRecursively(LayoutNode* node);
  void LayoutRecursively(LayoutNode* node);
  void LayoutRecursivelyForInlineVIew(LayoutNode* node);
  void DestroyPlatformNodesIfNeeded();
  void TryPostLayoutMetrics(bool first_perf);
  bool SetViewportSizeToRootNode();
  int GetIndexForChild(SPLayoutNode parent, SPLayoutNode child);

  std::shared_ptr<PlatformImpl> platform_impl_;
  std::unique_ptr<Delegate> delegate_;
  std::shared_ptr<LayoutNode> root_;
  bool layout_wanted_;
  bool has_viewport_ready_;
  bool enable_layout_;
  bool has_layout_required_;
  Viewport viewport_;
  std::weak_ptr<HierarchyObserver> hierarchy_observer_;
  // Help to record those platform node that have been removed during diff so
  // that we can trigger destroy operation on platform
  std::unordered_set<int> destroyed_platform_nodes_;
  // Keep the Shared LayoutNode, release it after platform destroy actually
  // executed
  std::vector<std::shared_ptr<LayoutNode>> pending_destroyed_layout_nodes_;
  int32_t trace_id_ = 0;
  bool has_first_page_layout_ = false;

  std::unordered_map<int, std::shared_ptr<LayoutNode>>
      platform_attached_nodes_registry_;

  CalculatedViewport calculated_viewport_;

  RequestLayoutCallback request_layout_callback_;

  LayoutContext(const LayoutContext&) = delete;
  LayoutContext& operator=(const LayoutContext&) = delete;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_LAYOUT_CONTEXT_H_
