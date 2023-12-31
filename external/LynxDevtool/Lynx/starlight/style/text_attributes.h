// Copyright 2020 The Lynx Authors. All rights reserved.
#ifndef LYNX_STARLIGHT_STYLE_TEXT_ATTRIBUTES_H_
#define LYNX_STARLIGHT_STYLE_TEXT_ATTRIBUTES_H_

#include <optional>
#include <tuple>
#include <vector>

#include "lepus/value-inl.h"
#include "lepus/value.h"
#include "starlight/style/css_type.h"
#include "starlight/style/shadow_data.h"
#include "starlight/types/nlength.h"

namespace lynx {
namespace starlight {

enum TextPropertyID {
  kTextProperIDFontSize = 1,
  kTextProperIDColor = 2,
  kTextProperIDWhiteSpace = 3,
  kTextProperIDTextOverflow = 4,
  kTextProperIDFontWeight = 5,
  kTextProperIDFontStyle = 6,
  kTextProperIDLineHeight = 7,
  kTextProperIDEnableFontScaling = 8,
  kTextProperIDLetterSpacing = 9,
  kTextProperIDLineSpacing = 10,
  kTextProperIDTextAlign = 11,
  kTextProperIDWordBreak = 12,
  kTextProperIDUnderline = 13,
  kTextProperIDLineThrough = 14,
  kTextProperIDHasTextShadow = 15,
  kTextProperIDShadowHOffset = 16,
  kTextProperIDShadowVOffset = 17,
  kTextProperIDShadowBlur = 18,
  kTextProperIDShadowColor = 19,
  kTextProperIDVerticalAlign = 20,
  kTextProperIDVerticalAlignLength = 21,
  kTextProperIDTextIndent = 22,

  kTextProperIDEnd = 0xFF,
};

class TextAttributes {
 public:
  TextAttributes();

  float font_size;
  unsigned int color;
  unsigned int decoration_color;
  lepus::Value text_gradient;
  // TODO(linxs) this type has changed.
  starlight::WhiteSpaceType white_space;
  starlight::TextOverflowType text_overflow;
  starlight::FontWeightType font_weight;
  starlight::FontStyleType font_style;
  lepus::String font_family;
  float computed_line_height;
  float line_height_factor;
  bool enable_font_scaling;
  float letter_spacing;
  float line_spacing;
  starlight::TextAlignType text_align;
  starlight::WordBreakType word_break;
  bool underline_decoration;
  bool line_through_decoration;
  unsigned int text_decoration_color;
  unsigned int text_decoration_style;
  float text_stroke_width;
  unsigned int text_stroke_color;
  std::optional<std::vector<ShadowData>> text_shadow;
  starlight::VerticalAlignType vertical_align;
  double vertical_align_length;
  NLength text_indent;

  void Reset() {}

  bool operator==(const TextAttributes& rhs) const {
    return std::tie(font_size, color, decoration_color, white_space,
                    text_overflow, font_weight, font_style, font_family,
                    computed_line_height, line_height_factor,
                    enable_font_scaling, letter_spacing, line_spacing,
                    text_shadow, text_align, word_break, underline_decoration,
                    line_through_decoration, text_decoration_color,
                    text_decoration_style, text_indent) ==
           std::tie(rhs.font_size, rhs.color, rhs.decoration_color,
                    rhs.white_space, rhs.text_overflow, rhs.font_weight,
                    rhs.font_style, rhs.font_family, rhs.computed_line_height,
                    rhs.line_height_factor, rhs.enable_font_scaling,
                    rhs.letter_spacing, rhs.line_spacing, rhs.text_shadow,
                    rhs.text_align, rhs.word_break, rhs.underline_decoration,
                    rhs.line_through_decoration, rhs.text_decoration_color,
                    rhs.text_decoration_style, rhs.text_indent);
  }

  bool operator!=(const TextAttributes& rhs) const { return !(*this == rhs); }

  void Apply(const TextAttributes& rhs);
};

}  // namespace starlight
}  // namespace lynx
#endif  // LYNX_STARLIGHT_STYLE_TEXT_ATTRIBUTES_H_
