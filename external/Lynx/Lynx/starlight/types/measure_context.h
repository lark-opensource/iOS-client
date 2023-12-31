// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_TYPES_MEASURE_CONTEXT_H_
#define LYNX_STARLIGHT_TYPES_MEASURE_CONTEXT_H_

#include "starlight/layout/layout_global.h"
#include "starlight/types/layout_constraints.h"
#include "tasm/config.h"

// TODO(liting):move to .cc
#include "starlight/types/nlength.h"

namespace lynx {
namespace tasm {
class LynxEnvConfig;
struct PropertiesResolvingStatus;
}  // namespace tasm

namespace starlight {

class CssMeasureContext {
 public:
  CssMeasureContext(const tasm::LynxEnvConfig& config, float root_font_size,
                    float cur_font_size);
  CssMeasureContext(float screen_width, float layouts_unit_per_px,
                    float physical_pixels_per_layout_unit, float root_font_size,
                    float cur_font_size, const LayoutUnit& viewport_width_,
                    const LayoutUnit& viewport_height_);
  ~CssMeasureContext() {}
  float screen_width_;
  float layouts_unit_per_px_;
  float physical_pixels_per_layout_unit_;
  float root_node_font_size_;
  float cur_node_font_size_;
  float font_scale_ = tasm::Config::DefaultFontScale();
  LayoutUnit viewport_width_;
  LayoutUnit viewport_height_;
  bool font_scale_sp_only_ = false;
};

// WARNING!!! Don't use this method
LayoutUnit NLengthToFakeLayoutUnit(const NLength& length);

LayoutUnit NLengthToLayoutUnit(const NLength& length,
                               const LayoutUnit& parent_value);

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_TYPES_MEASURE_CONTEXT_H_
