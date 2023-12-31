// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/style/text_attributes.h"

#include <tasm/config.h>

#include "starlight/style/default_css_style.h"

namespace lynx {
namespace starlight {
TextAttributes::TextAttributes()
    : font_size(lynx::tasm::Config::DefaultFontSize()),
      color(DefaultCSSStyle::SL_DEFAULT_TEXT_COLOR),
      decoration_color(DefaultCSSStyle::SL_DEFAULT_TEXT_COLOR),
      text_gradient(DefaultCSSStyle::EMPTY_LEPUS_VALUE()),
      white_space(DefaultCSSStyle::SL_DEFAULT_WHITE_SPACE),
      text_overflow(DefaultCSSStyle::SL_DEFAULT_TEXT_OVERFLOW),
      font_weight(DefaultCSSStyle::SL_DEFAULT_FONT_WEIGHT),
      font_style(DefaultCSSStyle::SL_DEFAULT_FONT_STYLE),
      font_family(DefaultCSSStyle::EMPTY_LEPUS_STRING()),
      computed_line_height(DefaultCSSStyle::SL_DEFAULT_LINE_HEIGHT),
      line_height_factor(DefaultCSSStyle::SL_DEFAULT_LINE_HEIGHT_FACTOR),
      enable_font_scaling(DefaultCSSStyle::SL_DEFAULT_BOOLEAN),
      letter_spacing(DefaultCSSStyle::SL_DEFAULT_LETTER_SPACING),
      line_spacing(DefaultCSSStyle::SL_DEFAULT_LINE_SPACING),
      text_align(DefaultCSSStyle::SL_DEFAULT_TEXT_ALIGN),
      word_break(DefaultCSSStyle::SL_DEFAULT_WORD_BREAK),
      underline_decoration(DefaultCSSStyle::SL_DEFAULT_BOOLEAN),
      line_through_decoration(DefaultCSSStyle::SL_DEFAULT_BOOLEAN),
      vertical_align(DefaultCSSStyle::SL_DEFAULT_VERTICAL_ALIGN),
      vertical_align_length(DefaultCSSStyle::SL_DEFAULT_FLOAT),
      text_indent(DefaultCSSStyle::SL_DEFAULT_ZEROLENGTH()) {
  text_shadow.reset();
}

void TextAttributes::Apply(const TextAttributes& rhs) {
  font_size = rhs.font_size;
  color = rhs.color;
  decoration_color = rhs.decoration_color;
  text_gradient = rhs.text_gradient;
  white_space = rhs.white_space;
  text_overflow = rhs.text_overflow;
  font_weight = rhs.font_weight;
  font_style = rhs.font_style;
  font_family = rhs.font_family;
  computed_line_height = rhs.computed_line_height;
  line_height_factor = rhs.line_height_factor;
  enable_font_scaling = rhs.enable_font_scaling;
  letter_spacing = rhs.letter_spacing;
  line_spacing = rhs.line_spacing;
  text_align = rhs.text_align;
  word_break = rhs.word_break;
  underline_decoration = rhs.underline_decoration;
  line_through_decoration = rhs.line_through_decoration;
  text_shadow = rhs.text_shadow ? *rhs.text_shadow : text_shadow;
  vertical_align = rhs.vertical_align;
  vertical_align_length = rhs.vertical_align_length;
  text_indent = rhs.text_indent;
}

}  // namespace starlight
}  // namespace lynx
