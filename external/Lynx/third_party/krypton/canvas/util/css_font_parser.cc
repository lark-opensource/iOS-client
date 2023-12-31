// Copyright 2021 The Lynx Authors. All rights reserved.

#include "css_font_parser.h"

#include "canvas/util/string_utils.h"

namespace lynx {
namespace canvas {
namespace {
const char *kNormal = "normal";
const char *kItalic = "italic";
const char *kOblique = "oblique";
const char *kSmallCaps = "small-caps";
const char *kBold = "bold";
const char *kBolder = "bolder";
const char *kLighter = "lighter";
const char *kSerifFontFamily = "serif";
const char *kSansSerifFontFamily = "sans-serif";
const char *kMonospaceFontFamily = "monospace";
const char *kCursiveFontFamily = "cursive";
const char *kFantasyFontFamily = "fantasy";

const char *kGenericFontFamilyArray[] = {
    kSerifFontFamily,   kSansSerifFontFamily, kMonospaceFontFamily,
    kCursiveFontFamily, kFantasyFontFamily,
};

bool StringToDoubleIgnoreSuffix(const std::string &input, double &output) {
  errno = 0;
  char *end_ptr = nullptr;
  double d = strtod(input.c_str(), &end_ptr);
  bool valid = errno == 0 && !input.empty() && input.data() != end_ptr;
  if (valid) {
    output = d;
  }
  return valid;
}

bool StringToDoubleWithoutSuffix(const std::string &input, double &output) {
  errno = 0;
  char *end_ptr = nullptr;
  double d = strtod(input.c_str(), &end_ptr);
  bool valid =
      errno == 0 && !input.empty() && input.data() != end_ptr && !*end_ptr;
  if (valid) {
    output = d;
  }
  return valid;
}

std::string MapGenericFamily(const std::string &origin) {
  std::string lower = StringToLowerASCII(origin);

  for (auto *name : kGenericFontFamilyArray) {
    if (lower == name) {
      return name;
    }
  }

  return origin;
}

}  // namespace
bool CSSFontParser::ParseFont(const std::string &css_font_string,
                              CSSFont &css_font) {
  if (css_font_string.empty()) {
    return false;
  }

  CSSTokenizer tokenizer(css_font_string);
  tokenizer.ConsumeSpace();

  Style style = kNormalStyle;
  double oblique_deg = 0;
  bool style_found = false;
  Variant variant = kNormalVariant;
  bool variant_found = false;
  Weight weight = kNormalWeight;
  bool weight_found = false;
  double weight_value = 0;

  const int kNumReorderableFontProperties = 3;
  for (int i = 0; i < kNumReorderableFontProperties && !tokenizer.AtEnd();
       ++i) {
    if (tokenizer.Peek() == kNormal) {
      tokenizer.ConsumeIdentWithSpace();
      continue;
    }

    if (!style_found &&
        (tokenizer.Peek() == kItalic || tokenizer.Peek() == kOblique)) {
      style_found = ParseStyle(tokenizer, style, oblique_deg);
      continue;
    }

    if (!variant_found && tokenizer.Peek() == kSmallCaps) {
      variant_found = ParseVariant(tokenizer, variant);
      continue;
    }

    if (!weight_found) {
      weight_found = ParseWeight(tokenizer, weight, weight_value);
      continue;
    }
  }

  if (tokenizer.AtEnd()) {
    return false;
  }

  double size, line_height = 1.2;
  if (!ParseSize(tokenizer, size, line_height)) {
    return false;
  }

  std::vector<std::string> family_vector;
  if (!ParseFamily(tokenizer, family_vector)) {
    return false;
  }

  css_font.family_vector = family_vector;
  css_font.size = size;
  css_font.line_height = line_height;
  css_font.style = style;
  css_font.oblique_deg = oblique_deg;
  css_font.variant = variant;
  css_font.weight = weight;
  css_font.weight_value = weight_value;

  return tokenizer.AtEnd();
}

bool CSSFontParser::ParseStyle(CSSTokenizer &tokenizer, Style &style,
                               double &oblique_deg) {
  if (tokenizer.Peek() == kItalic) {
    style = kItalicStyle;
    tokenizer.ConsumeIdentWithSpace();
    return true;
  }

  if (tokenizer.Peek() != kOblique) {
    return false;
  }

  style = kObliqueStyle;

  tokenizer.ConsumeIdentWithSpace();
  oblique_deg = 14;
  if (tokenizer.Peek().EndsWith("deg") || tokenizer.Peek().EndsWith("rad") ||
      tokenizer.Peek().EndsWith("grad") || tokenizer.Peek().EndsWith("turn")) {
    // TODO(luchengxuan) convert to real deg, but we do not support oblique now
    tokenizer.ConsumeIdentWithSpace();
  }
  return true;
}

bool CSSFontParser::ParseVariant(CSSTokenizer &tokenizer, Variant &variant) {
  if (tokenizer.Peek() == kSmallCaps) {
    variant = kSmallCapsVariant;
    tokenizer.ConsumeIdentWithSpace();
    return true;
  }

  return false;
}

bool CSSFontParser::ParseWeight(CSSTokenizer &tokenizer, Weight &weight,
                                double &weight_value) {
  if (tokenizer.Peek() == kBold) {
    weight = kBoldWeight;
    tokenizer.ConsumeIdentWithSpace();
    return true;
  } else if (tokenizer.Peek() == kBolder) {
    weight = kBolderWeight;
    tokenizer.ConsumeIdentWithSpace();
    return true;
  } else if (tokenizer.Peek() == kLighter) {
    weight = kLighterWeight;
    tokenizer.ConsumeIdentWithSpace();
    return true;
  }
  double value;
  if (!StringToDoubleWithoutSuffix(tokenizer.Peek().ToString(), value)) {
    return false;
  }

  if (value > 0 && value <= 1000) {
    weight_value = value;
    weight = kNumberWeight;
    tokenizer.ConsumeIdentWithSpace();
    return true;
  }

  return false;
}

bool CSSFontParser::ParseSize(CSSTokenizer &tokenizer, double &size,
                              double &line_height) {
  std::string font_size_string, line_height_string;

  auto source = tokenizer.Peek().ToString();
  size_t separator_idx = source.find('/');
  if (separator_idx != std::string::npos) {
    font_size_string = source.substr(0, separator_idx);
    line_height_string = source.substr(separator_idx + 1);
  } else {
    font_size_string = source;
  }

  // now only support size in px
  if (EndsWithIgnoreSourceCase(font_size_string, "px")) {
    if (!StringToDoubleIgnoreSuffix(font_size_string, size)) {
      return false;
    }
  }

  if (!line_height_string.empty()) {
    if (!StringToDoubleIgnoreSuffix(line_height_string, line_height)) {
      return false;
    }
  }

  tokenizer.ConsumeIdentWithSpace();

  return true;
}

bool CSSFontParser::ParseFamily(CSSTokenizer &tokenizer,
                                std::vector<std::string> &family_vector) {
  family_vector.clear();

  do {
    std::string family;
    bool start_with_quote = tokenizer.ConsumeQuote();
    while (tokenizer.PeekType() == kIdentTokenType) {
      if (!family.empty()) {
        family.append(" ");
      }
      family.append(tokenizer.Peek().ToString());
      tokenizer.ConsumeIdentWithSpace();
    }
    if (start_with_quote && !tokenizer.ConsumeQuote()) {
      break;
    }
    family_vector.emplace_back(MapGenericFamily(family));
  } while (tokenizer.ConsumeCommaWithSpace());
  return !family_vector.empty();
}

}  // namespace canvas
}  // namespace lynx
