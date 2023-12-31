// Copyright 2021 The Lynx Authors. All rights reserved.

#include "starlight/types/measure_context.h"

#include "starlight/style/computed_css_style.h"
#include "tasm/lynx_env_config.h"

namespace lynx {
namespace starlight {
CssMeasureContext::CssMeasureContext(float screen_width,
                                     float layouts_unit_per_px,
                                     float physical_pixels_per_layout_unit,
                                     float root_font_size, float cur_font_size,
                                     const LayoutUnit& viewport_width,
                                     const LayoutUnit& viewport_height)
    : screen_width_(screen_width),
      layouts_unit_per_px_(layouts_unit_per_px),
      physical_pixels_per_layout_unit_(physical_pixels_per_layout_unit),
      root_node_font_size_(root_font_size),
      cur_node_font_size_(cur_font_size),
      viewport_width_(viewport_width),
      viewport_height_(viewport_height) {}

CssMeasureContext::CssMeasureContext(const tasm::LynxEnvConfig& config,
                                     float root_font_size, float cur_font_size)
    : screen_width_(config.ScreenWidth()),
      layouts_unit_per_px_(ComputedCSSStyle::LAYOUTS_UNIT_PER_PX),
      physical_pixels_per_layout_unit_(
          ComputedCSSStyle::PHYSICAL_PIXELS_PER_LAYOUT_UNIT),
      root_node_font_size_(root_font_size),
      cur_node_font_size_(cur_font_size),
      font_scale_(config.FontScale()),
      viewport_width_(config.ViewportWidth()),
      viewport_height_(config.ViewportHeight()),
      font_scale_sp_only_(config.FontScaleSpOnly()) {}

LayoutUnit NLengthToFakeLayoutUnit(const NLength& length) {
  return NLengthToLayoutUnit(length, LayoutUnit::Indefinite());
}

// static
LayoutUnit NLengthToLayoutUnit(const NLength& length,
                               const LayoutUnit& parent_value) {
  if (length.IsUnit()) {
    return LayoutUnit(length.GetRawValue());
  } else if (length.IsPercent()) {
    return parent_value * (length.GetRawValue() / 100.0f);
  } else if (length.IsCalc()) {
    // Definite
    LayoutUnit result = LayoutUnit(0.0f);
    for (auto entry : length.GetCalcSubLengths()) {
      result = result + NLengthToLayoutUnit(entry, parent_value);
    }
    return result;
  }

  return LayoutUnit::Indefinite();
}

}  // namespace starlight
}  // namespace lynx
