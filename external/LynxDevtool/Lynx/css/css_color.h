// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_CSS_COLOR_H_
#define LYNX_CSS_CSS_COLOR_H_

#include <string>

namespace lynx {
namespace tasm {
class CSSColor {
 public:
  CSSColor() : r_(0), g_(0), b_(0), a_(1.0f) {}
  CSSColor(unsigned char r, unsigned char g, unsigned char b, float a)
      : r_(r), g_(g), b_(b), a_(a) {}
  static bool Parse(const std::string& color_str, CSSColor& color);
  static bool ParseNamedColor(const std::string& color_str, CSSColor& color);
  static CSSColor CreateFromHSLA(float h, float s, float l, float a);

  unsigned int Cast();

  bool operator==(const CSSColor& other) const {
    return r_ == other.r_ && g_ == other.g_ && b_ == other.b_ && a_ == other.a_;
  }

  static constexpr unsigned int Black = 0xFF000000;
  static constexpr unsigned int White = 0xFFFFFFFF;
  static constexpr unsigned int Gray = 0xFF808080;
  static constexpr unsigned int Transparent = 0x00000000;

  unsigned char r_;
  unsigned char g_;
  unsigned char b_;
  float a_;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CSS_COLOR_H_
