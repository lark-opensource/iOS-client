// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_INCLUDE_FONT_H_
#define ANIMAX_RENDER_INCLUDE_FONT_H_

#include <string>

namespace lynx {
namespace animax {

class Font {
 public:
  virtual ~Font() = default;

  virtual void SetTextSize(float text_size) = 0;
  virtual float MeasureText(const std::string& text) const = 0;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_INCLUDE_FONT_H_
