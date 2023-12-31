// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skia/skia_font.h"

#include <memory>

#include "animax/base/log.h"

namespace lynx {
namespace animax {

SkiaFont::SkiaFont(SkFont sk_font) : sk_font_(std::move(sk_font)) {}

void SkiaFont::SetTextSize(float text_size) { sk_font_.setSize(text_size); }

float SkiaFont::MeasureText(const std::string& text) const {
  return sk_font_.measureText(text.c_str(), text.length(),
                              SkTextEncoding::kUTF8);
}

std::shared_ptr<Font> SkiaFont::MakeSkiaFont(const void* bytes, size_t len) {
  sk_sp<SkData> data = SkData::MakeWithoutCopy(bytes, len);
  auto sk_typeface = SkTypeface::MakeFromData(data);
  if (!sk_typeface) {
    ANIMAX_LOGW("typeface read failed");
    return nullptr;
  }
  return std::make_shared<SkiaFont>(SkFont(sk_typeface));
}

std::shared_ptr<Font> SkiaFont::MakeSkiaDefaultFont() {
  return std::make_shared<SkiaFont>(SkFont(SkTypeface::MakeDefault()));
}

}  // namespace animax
}  // namespace lynx
