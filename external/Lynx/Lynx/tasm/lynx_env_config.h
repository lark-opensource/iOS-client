// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_LYNX_ENV_CONFIG_H_
#define LYNX_TASM_LYNX_ENV_CONFIG_H_

#include <memory>
#include <string>

#include "starlight/layout/layout_global.h"
#include "starlight/types/layout_unit.h"
#include "tasm/config.h"

namespace lynx {
namespace tasm {

class LynxEnvConfig {
 public:
  LynxEnvConfig(int32_t width, int32_t height);
  ~LynxEnvConfig() = default;

  int32_t ScreenWidth() const { return screen_width_; }
  int32_t ScreenHeight() const { return screen_height_; }
  const starlight::LayoutUnit& ViewportWidth() const { return viewport_width_; }
  const starlight::LayoutUnit& ViewportHeight() const {
    return viewport_height_;
  }
  void UpdateViewport(float width, SLMeasureMode width_mode_, float height,
                      SLMeasureMode height_mode) {
    viewport_width_ = width_mode_ == SLMeasureModeDefinite
                          ? starlight::LayoutUnit(width)
                          : starlight::LayoutUnit();
    viewport_height_ = height_mode == SLMeasureModeDefinite
                           ? starlight::LayoutUnit(height)
                           : starlight::LayoutUnit();
  }
  void UpdateScreenSize(int32_t width, int32_t height);
  float FontScale() const { return font_scale_; }
  bool FontScaleSpOnly() const { return font_scale_sp_only_; }
  void SetFontScale(float font_scale) { font_scale_ = font_scale; }
  void SetFontScaleSpOnly(bool font_scale_sp_only) {
    font_scale_sp_only_ = font_scale_sp_only;
  }

  float PageDefaultFontSize() const {
    return (font_scale_sp_only_ ? 1.f : FontScale()) *
           Config::DefaultFontSize();
  }

 private:
  int32_t screen_width_;
  int32_t screen_height_;
  starlight::LayoutUnit viewport_width_;
  starlight::LayoutUnit viewport_height_;
  float font_scale_ = 1.f;
  bool font_scale_sp_only_ = false;
};

}  // namespace tasm
};  // namespace lynx

#endif  // LYNX_TASM_LYNX_ENV_CONFIG_H_
