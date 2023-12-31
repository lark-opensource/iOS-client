// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKITY_SKITY_FONT_H_
#define ANIMAX_RENDER_SKITY_SKITY_FONT_H_

#include "animax/render/include/font.h"
#include "skity/skity.hpp"
#include "skity/text/text_blob.hpp"

namespace lynx {
namespace animax {

class FallbackTypefaceDelegate : public skity::TypefaceDelegate {
 public:
  FallbackTypefaceDelegate() = default;
  ~FallbackTypefaceDelegate() override = default;

  skity::Typeface* Fallback(skity::Unichar code_point,
                            skity::Paint const& text_paint) override;

  std::vector<std::vector<skity::Unichar>> BreakTextRun(
      const char* text) override {
    return {};
  }
};

class SkityFont : public Font {
 public:
  static std::shared_ptr<Font> MakeFont(const void* bytes, size_t len);
  static std::shared_ptr<Font> MakeDefaultFont();

  SkityFont(skity::Font font) : font_(std::move(font)) {}
  ~SkityFont() override = default;

  void SetTextSize(float text_size) override;

  float MeasureText(const std::string& text) const override;

  const skity::Font& GetFont() const { return font_; }

 private:
  skity::Font font_ = {};
  std::unique_ptr<skity::TypefaceDelegate> delegate_ =
      std::make_unique<FallbackTypefaceDelegate>();
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKITY_SKITY_FONT_H_
