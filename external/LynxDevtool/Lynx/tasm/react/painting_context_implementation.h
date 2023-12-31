// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_PAINTING_CONTEXT_IMPLEMENTATION_H_
#define LYNX_TASM_REACT_PAINTING_CONTEXT_IMPLEMENTATION_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "css/css_font_face_token.h"
#include "css/css_fragment.h"
#include "css/css_keyframes_token.h"
#include "shell/dynamic_ui_operation_queue.h"
#include "tasm/react/painting_context.h"
#include "tasm/react/pipeline_option.h"
#include "tasm/react/platform_extra_bundle.h"
#include "tasm/react/prop_bundle.h"
#include "tasm/timing.h"

namespace lynx {
namespace tasm {

class PaintingContextPlatformImpl : public PaintingContext::PlatformImpl {
 public:
  virtual ~PaintingContextPlatformImpl() {}
  virtual void CreatePaintingNode(int id, PropBundle* painting_data,
                                  bool flatten) override {}
  virtual void InsertPaintingNode(int parent, int child, int index) override {}
  virtual void RemovePaintingNode(int parent, int child, int index) override {}
  virtual void DestroyPaintingNode(int parent, int child, int index) override {}
  virtual void UpdatePaintingNode(int id, bool tend_to_flatten,
                                  PropBundle* painting_data) override {}
  virtual void UpdateLayout(int tag, float x, float y, float width,
                            float height, const float* paddings,
                            const float* margins, const float* borders,
                            const float* bounds, const float* sticky,
                            float max_height) override {}
  virtual void SetKeyframes(PropBundle* keyframes_data) override {}
#if ENABLE_RENDERKIT
  virtual void SetFontFaces(const CSSFontFaceTokenMap& fontfaces) override {}
#endif
  virtual void Flush() override {}
  virtual void HandleValidate(int tag) override {}
  virtual void FinishTasmOperation(const PipelineOptions& options) override {}
  virtual void FinishLayoutOperation(const PipelineOptions& options) override {}

  virtual void SetNeedMarkDrawEndTiming(
      bool is_first_screen, const std::string& timing_flag) override {}

  virtual std::vector<float> getBoundingClientOrigin(int id) override {
    return floats_;
  }
  virtual std::vector<float> getTransformValue(
      int id, std::vector<float> pad_border_margin_layout) override {
    return floats_;
  }
  virtual std::vector<float> getWindowSize(int id) override { return floats_; }
  virtual std::vector<float> GetRectToWindow(int id) override {
    return floats_;
  }
  virtual std::vector<int> getVisibleOverlayView() override { return {}; }
  virtual std::vector<float> GetRectToLynxView(int64_t id) override {
    return floats_;
  }
  virtual std::vector<float> ScrollBy(int64_t id, float width,
                                      float height) override {
    return floats_;
  }
  virtual void ScrollIntoView(int id) override { return; }

  virtual void Invoke(
      int64_t id, const std::string& method, const lepus::Value& params,
      const std::function<void(int32_t code, const lepus::Value& data)>&
          callback) override {}
  virtual int GetCurrentIndex(int idx) override { return 0; }
  virtual bool IsViewVisible(int idx) override { return true; }
  virtual bool IsTagVirtual(const std::string& tag_name) override {
    return false;
  }

  virtual void OnAnimatedNodeReady(int tag) override {}
  virtual void MarkUIOperationQueueFlushTiming(
      tasm::TimingKey key, const std::string& flag) override {}

 private:
  std::vector<float> floats_;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_PAINTING_CONTEXT_IMPLEMENTATION_H_
