// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_PAINTING_CONTEXT_H_
#define LYNX_TASM_REACT_PAINTING_CONTEXT_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "css/css_font_face_token.h"
#include "css/css_fragment.h"
#include "css/css_keyframes_token.h"
#include "shell/dynamic_ui_operation_queue.h"
#include "tasm/react/pipeline_option.h"
#include "tasm/react/platform_extra_bundle.h"
#include "tasm/react/prop_bundle.h"
#include "tasm/timing.h"

namespace lynx {
namespace tasm {

class LayoutNode;

class PaintingContext {
 public:
  class PlatformImpl {
   public:
    virtual ~PlatformImpl() {}
    virtual void SetUIOperationQueue(
        const std::shared_ptr<shell::DynamicUIOperationQueue>& queue){};
    virtual void CreatePaintingNode(int id, PropBundle* painting_data,
                                    bool flatten) = 0;
    virtual void InsertPaintingNode(int parent, int child, int index) = 0;
    virtual void RemovePaintingNode(int parent, int child, int index) = 0;
    virtual void DestroyPaintingNode(int parent, int child, int index) = 0;
    virtual void UpdatePaintingNode(int id, bool tend_to_flatten,
                                    PropBundle* painting_data) = 0;
    virtual void ListReusePaintingNode(int id, const lepus::String& item_key){};
    virtual void UpdateLayout(int tag, float x, float y, float width,
                              float height, const float* paddings,
                              const float* margins, const float* borders,
                              const float* bounds, const float* sticky,
                              float max_height) = 0;
    virtual void UpdateFlattenStatus(int id, bool flatten) {}
    virtual void OnCollectExtraUpdates(int32_t id) {}
    virtual void UpdatePlatformExtraBundle(int32_t id,
                                           PlatformExtraBundle* bundle) {}
    virtual void SetKeyframes(PropBundle* keyframes_data) = 0;

    virtual void Flush() = 0;
    virtual void FlushImmediately() { Flush(); };
    virtual void HandleValidate(int tag) = 0;
    virtual void FinishTasmOperation(const PipelineOptions& options) = 0;
    virtual void FinishLayoutOperation(const PipelineOptions& options) = 0;

    virtual void SetNeedMarkDrawEndTiming(bool is_first_screen,
                                          const std::string& timing_flag) = 0;

    virtual std::vector<float> getBoundingClientOrigin(int id) = 0;
    virtual std::vector<float> getTransformValue(
        int id, std::vector<float> pad_border_margin_layout) = 0;
    virtual std::vector<float> getWindowSize(int id) = 0;
    virtual std::vector<float> GetRectToWindow(int id) = 0;
    virtual std::vector<int> getVisibleOverlayView() = 0;
    virtual void ScrollIntoView(int id) = 0;

    virtual std::vector<float> GetRectToLynxView(int64_t id) = 0;
    virtual std::vector<float> ScrollBy(int64_t id, float width,
                                        float height) = 0;
    virtual void Invoke(
        int64_t id, const std::string& method, const lepus::Value& params,
        const std::function<void(int32_t code, const lepus::Value& data)>&
            callback) = 0;
    virtual int GetCurrentIndex(int idx) = 0;
    virtual bool IsViewVisible(int idx) = 0;

    virtual bool IsTagVirtual(const std::string& tag_name) = 0;

    virtual void OnAnimatedNodeReady(int tag) = 0;

    virtual void MarkUIOperationQueueFlushTiming(tasm::TimingKey key,
                                                 const std::string& flag) = 0;

    virtual void OnNodeReady(int tag) {}

    virtual void UpdateLayoutPatching() {}
    virtual void SetEnabledPatching(bool enabled) {}
    virtual void OnFirstMeaningfulLayout() {}

    virtual void UpdateNodeReadyPatching() {}
    virtual void SetEnableVsyncAlignedFlush(bool enabled) {}

#if ENABLE_RENDERKIT
    virtual void SetFontFaces(const CSSFontFaceTokenMap& fontfaces) {}
#endif
    virtual void getAbsolutePosition(int id, float* position) {}
    virtual void UpdateEventInfo(bool has_touch_pseudo) {}

    virtual int GetNodeForLocation(int x, int y) { return -1; };
  };

  PaintingContext(std::unique_ptr<PlatformImpl> platform_impl)
      : platform_impl_(std::move(platform_impl)) {}
  virtual ~PaintingContext() {}

  PlatformImpl* impl() { return platform_impl_.get(); }

  inline void GetAbsolutePosition(int id, float* position) {
    platform_impl_->getAbsolutePosition(id, position);
  }

  inline void CreatePaintingNode(int id, PropBundle* painting_data,
                                 bool flatten) {
    platform_impl_->CreatePaintingNode(id, painting_data, flatten);
  }

  inline void InsertPaintingNode(int parent, int child, int index) {
    platform_impl_->InsertPaintingNode(parent, child, index);
  }

  inline void RemovePaintingNode(int parent, int child, int index) {
    platform_impl_->RemovePaintingNode(parent, child, index);
  }

  inline void DestroyPaintingNode(int parent, int child, int index) {
    platform_impl_->DestroyPaintingNode(parent, child, index);
  }

  inline void UpdatePaintingNode(int id, bool tend_to_flatten,
                                 PropBundle* painting_data) {
    platform_impl_->UpdatePaintingNode(id, tend_to_flatten, painting_data);
  }

  inline void ListReusePaintingNode(int id, const lepus::String& item_key) {
    platform_impl_->ListReusePaintingNode(id, item_key);
  }

  inline void UpdateLayout(int tag, float x, float y, float width, float height,
                           const float* paddings, const float* margins,
                           const float* borders, const float* bounds,
                           const float* sticky, float max_height) {
    platform_impl_->UpdateLayout(tag, x, y, width, height, paddings, margins,
                                 borders, bounds, sticky, max_height);
  }

  inline void UpdateFlattenStatus(int id, bool flatten) {
    platform_impl_->UpdateFlattenStatus(id, flatten);
  }

  inline void SetKeyframes(PropBundle* keyframes_data) {
    platform_impl_->SetKeyframes(keyframes_data);
  }

  inline void FinishTasmOperation(const PipelineOptions& options) {
    platform_impl_->FinishTasmOperation(options);
  }

  inline void FinishLayoutOperation(const PipelineOptions& options) {
    if (has_first_screen_) {
      platform_impl_->FinishLayoutOperation(options);
    }
    // timing
    // Pass the opions to the tasm thread through the tasm queue, and mount
    // them on the PaintingContext. The UI Flush stage reads the opions from
    // the PaintingContext for collecting timing, and clears the opions at the
    // end.
    if (options_for_timing_.has_patched) {
      if (options_for_timing_.is_first_screen) {
        MarkUIOperationQueueFlushTiming(
            tasm::TimingKey::SETUP_UI_OPERATION_FLUSH_END, "");
      } else if (!options_for_timing_.timing_flag.empty()) {
        MarkUIOperationQueueFlushTiming(
            tasm::TimingKey::UPDATE_UI_OPERATION_FLUSH_END,
            options_for_timing_.timing_flag);
      }
      platform_impl_->SetNeedMarkDrawEndTiming(
          options_for_timing_.is_first_screen, options_for_timing_.timing_flag);
    }
    {
      TRACE_EVENT(
          LYNX_TRACE_CATEGORY, "PaintingContext.CleanOptionsForTiming",
          [&options = options_for_timing_](lynx::perfetto::EventContext ctx) {
            options.UpdateTraceDebugInfo(ctx.event());
          });
      // clean
      UpdateOptionsForTiming({});
    }
  }

  inline void OnAnimatedNodeReady(int tag) {
    platform_impl_->OnAnimatedNodeReady(tag);
  }

  inline void OnNodeReady(int tag) { platform_impl_->OnNodeReady(tag); }

  inline void UpdateLayoutPatching() { platform_impl_->UpdateLayoutPatching(); }
  inline void SetEnabledPatching(bool enabled) {
    platform_impl_->SetEnabledPatching(enabled);
  }

  inline void UpdateNodeReadyPatching() {
    platform_impl_->UpdateNodeReadyPatching();
  }
  void OnCollectExtraUpdates(int32_t id) {
    platform_impl_->OnCollectExtraUpdates(id);
  }

  void UpdatePlatformExtraBundle(int32_t id, PlatformExtraBundle* bundle) {
    platform_impl_->UpdatePlatformExtraBundle(id, bundle);
  }

  inline void Flush() { platform_impl_->Flush(); }

  inline void FlushImmediately() { platform_impl_->FlushImmediately(); }

  inline void HandleValidate(int tag) { platform_impl_->HandleValidate(tag); }

  inline std::vector<float> getBoundingClientOrigin(int id) {
    return platform_impl_->getBoundingClientOrigin(id);
  }

  inline std::vector<float> getTransformValue(
      int id, std::vector<float> pad_border_margin_layout) {
    return platform_impl_->getTransformValue(id, pad_border_margin_layout);
  }

  inline std::vector<float> getWindowSize(int id) {
    return platform_impl_->getWindowSize(id);
  }

  inline std::vector<float> GetRectToWindow(int id) {
    return platform_impl_->GetRectToWindow(id);
  }

  inline std::vector<int> getVisibleOverlayView() {
    return platform_impl_->getVisibleOverlayView();
  }

  inline void MarkUIOperationQueueFlushTiming(tasm::TimingKey key,
                                              const std::string& flag) {
    if (key >= tasm::TimingKey::SETUP_DIVIDE && flag.empty()) {
      return;
    }
    platform_impl_->MarkUIOperationQueueFlushTiming(key, flag);
  }

  inline int GetCurrentIndex(int id) {
    return platform_impl_->GetCurrentIndex(id);
  }

  inline bool IsViewVisible(int id) {
    return platform_impl_->IsViewVisible(id);
  }

  inline bool IsTagVirtual(const std::string& tag_name) {
    return platform_impl_->IsTagVirtual(tag_name);
  }

  inline std::vector<float> GetRectToLynxView(int64_t id) {
    return platform_impl_->GetRectToLynxView(id);
  }

  inline std::vector<float> ScrollBy(int64_t id, float width, float height) {
    return platform_impl_->ScrollBy(id, width, height);
  }

  inline void Invoke(
      int64_t id, const std::string& method, const lepus::Value& params,
      const std::function<void(int32_t code, const lepus::Value& data)>&
          callback) {
    return platform_impl_->Invoke(id, method, params, callback);
  }

  inline void OnFirstMeaningfulLayout() {
    platform_impl_->OnFirstMeaningfulLayout();
  }

  inline void UpdateEventInfo(bool has_touch_pseudo) {
    platform_impl_->UpdateEventInfo(has_touch_pseudo);
  }

  inline void SetEnableVsyncAlignedFlush(bool enabled) {
    platform_impl_->SetEnableVsyncAlignedFlush(enabled);
  }

#if ENABLE_RENDERKIT

  inline void SetFontFaces(const CSSFontFaceTokenMap& fontfaces) {
    platform_impl_->SetFontFaces(fontfaces);
  }
#endif

  void OnFirstScreen() { has_first_screen_ = true; }

  inline int GetNodeForLocation(int x, int y) {
    return platform_impl_->GetNodeForLocation(x, y);
  }

  inline void ScrollIntoView(int id) { platform_impl_->ScrollIntoView(id); }

  // Pass the opions to the tasm thread through the tasm queue, and mount them
  // on the PaintingContext. The UI Flush stage reads the opions from the
  // PaintingContext for collecting timing, and clears the opions at the end.
  void UpdateOptionsForTiming(const PipelineOptions& options) {
    options_for_timing_ = options;
  }

 private:
  std::unique_ptr<PlatformImpl> platform_impl_;

  PaintingContext(const PaintingContext&) = delete;
  PaintingContext& operator=(const PaintingContext&) = delete;

  bool has_first_screen_ = false;
  // Pass the opions to the tasm thread through the tasm queue, and mount them
  // on the PaintingContext. The UI Flush stage reads the opions from the
  // PaintingContext for collecting timing, and clears the opions at the end.
  PipelineOptions options_for_timing_;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_PAINTING_CONTEXT_H_
