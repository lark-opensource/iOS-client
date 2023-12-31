// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_UTIL_CSS_FONT_PARSER_H_
#define CANVAS_UTIL_CSS_FONT_PARSER_H_

#include <string>
#include <vector>

#include "canvas/util/css_tokenizer.h"

namespace lynx {
namespace canvas {

enum Style { kNormalStyle, kItalicStyle, kObliqueStyle };

enum Variant { kNormalVariant, kSmallCapsVariant };

enum Weight {
  kNormalWeight,
  kBoldWeight,
  kBolderWeight,
  kLighterWeight,
  kNumberWeight,
};

struct CSSFont {
  std::vector<std::string> family_vector;
  double size;
  double line_height;
  Style style;
  double oblique_deg;
  Variant variant;
  Weight weight;
  double weight_value;
};

class CSSFontParser {
 public:
  bool ParseFont(const std::string& css_font_string, CSSFont& css_font);

 private:
  bool ParseStyle(CSSTokenizer& tokenizer, Style& style, double& oblique_deg);
  bool ParseVariant(CSSTokenizer& tokenizer, Variant& variant);
  bool ParseWeight(CSSTokenizer& tokenizer, Weight& weight,
                   double& weight_value);
  bool ParseSize(CSSTokenizer& tokenizer, double& size, double& line_height);
  bool ParseFamily(CSSTokenizer& tokenizer,
                   std::vector<std::string>& family_vector);
};
}  // namespace canvas
}  // namespace lynx
#endif  // CANVAS_UTIL_CSS_FONT_PARSER_H_
