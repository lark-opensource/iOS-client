// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_REACT_IOS_PAINTING_CONTEXT_DARWIN_H_
#define LYNX_TASM_REACT_IOS_PAINTING_CONTEXT_DARWIN_H_

#import <Foundation/Foundation.h>

#import <atomic>
#include <memory>

#include <string>
#include <vector>
#import "LynxUIOwner.h"
#include "shell/dynamic_ui_operation_queue.h"
#include "tasm/react/painting_context.h"
#include "tasm/react/prop_bundle.h"

#include "config/config.h"
#if ENABLE_ARK_REPLAY
#include "lepus/json_parser.h"
#endif
namespace lynx {
namespace tasm {

class PaintingContextDarwin : public PaintingContext::PlatformImpl {
 public:
  PaintingContextDarwin(LynxUIOwner* owner, bool enable_flush);
  ~PaintingContextDarwin() override;
  virtual void SetUIOperationQueue(
      const std::shared_ptr<shell::DynamicUIOperationQueue>& queue) override;
  void CreatePaintingNode(int sign, PropBundle* painting_data, bool flatten) override;
  void InsertPaintingNode(int parent, int child, int index) override;
  void RemovePaintingNode(int parent, int child, int index) override;
  void DestroyPaintingNode(int parent, int child, int index) override;
  void SetKeyframes(PropBundle* keyframes_data) override;
  void UpdatePaintingNode(int id, bool tend_to_flatten, PropBundle* painting_data) override;
  void ListReusePaintingNode(int id, const lepus::String& item_key) override;
  void UpdateLayout(int sign, float x, float y, float width, float height, const float* paddings,
                    const float* margins, const float* borders, const float* flatten_bounds,
                    const float* sticky, float max_height) override;
  void OnAnimatedNodeReady(int tag) override;
  void OnNodeReady(int tag) override;
  void UpdatePlatformExtraBundle(int32_t signature, PlatformExtraBundle* bundle) override;

  void Flush() override;
  void HandleValidate(int tag) override {
    // TODO(liujilong): Implement.
  }

  void FinishTasmOperation(const PipelineOptions& options) override;
  std::vector<float> getBoundingClientOrigin(int id) override;
  std::vector<float> getTransformValue(int id,
                                       std::vector<float> pad_border_margin_layout) override;
  void ScrollIntoView(int id) override;
  std::vector<float> getWindowSize(int id) override;
  std::vector<float> GetRectToWindow(int id) override;
  std::vector<int> getVisibleOverlayView() override;
  void MarkUIOperationQueueFlushTiming(tasm::TimingKey key, const std::string& flag) override;
  void UpdateEventInfo(bool has_touch_pseudo) override;

  std::vector<float> GetRectToLynxView(int64_t id) override;
  std::vector<float> ScrollBy(int64_t id, float width, float height) override;
  void Invoke(int64_t id, const std::string& method, const lepus::Value& params,
              const std::function<void(int32_t code, const lepus::Value& data)>& callback) override;
  int GetCurrentIndex(int idx) override;
  bool IsViewVisible(int idx) override;
  bool IsTagVirtual(const std::string& tag_name) override;

  // LayoutDidFinish is called only LayoutRecursively is actually executed
  // FinishLayoutOperation on the other hand, is always being called, and it is called before
  // LayoutDidFinish
  // TODO(heshan):merge to FinishLayoutOperation...
  void LayoutDidFinish();
  void FinishLayoutOperation(const PipelineOptions& options) override;
  void SetNeedMarkDrawEndTiming(bool is_first_screen, const std::string& timing_flag) override;

  void SetEnableFlush(bool enable_flush);
  void ForceFlush();
  bool IsLayoutFinish();
  void ResetLayoutStatus();

  void UpdateNodeReadyPatching() override;
#if ENABLE_ARK_REPLAY
  static lepus::Value GetUITreeRecursive(LynxUI* ui);
  std::string GetUITree() {
    LynxUI* root = (LynxUI*)[uiOwner rootUI];
    return lepus::lepusValueToJSONString(GetUITreeRecursive(root));
  }
#endif
 private:
  __weak LynxUIOwner* uiOwner;
  bool enable_flush_;
  std::shared_ptr<shell::DynamicUIOperationQueue> queue_;
  std::atomic<bool> is_layout_finish_ = {false};
  std::vector<int> patching_node_ready_ids_;

  template <typename F>
  void Enqueue(F&& func);

  PaintingContextDarwin(const PaintingContextDarwin&) = delete;
  PaintingContextDarwin& operator=(const PaintingContextDarwin&) = delete;
};
}  // namespace tasm
}  // namespace lynx
#endif  // LYNX_TASM_REACT_IOS_PAINTING_CONTEXT_DARWIN_H_
