// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RENDER_SKIA_SKIA_FONT_H_
#define ANIMAX_RENDER_SKIA_SKIA_FONT_H_

#include "animax/render/include/font.h"
#include "animax/render/skia/skia_util.h"

namespace lynx {
namespace animax {

class SkiaFont : public Font {
 public:
  static std::shared_ptr<Font> MakeSkiaFont(const void* bytes, size_t len);
  static std::shared_ptr<Font> MakeSkiaDefaultFont();

  SkiaFont(SkFont sk_font);
  ~SkiaFont() override = default;

  void SetTextSize(float text_size) override;

  float MeasureText(const std::string& text) const override;

  const SkFont& GetSkFont() const { return sk_font_; }

 private:
  SkFont sk_font_ = {};
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RENDER_SKIA_SKIA_FONT_H_
