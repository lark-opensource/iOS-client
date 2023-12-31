// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/render/skity/skity_font.h"

#include <memory>

#include "animax/base/log.h"
#include "skity/text/font_manager.hpp"
#include "skity/text/utf.hpp"

namespace lynx {
namespace animax {

std::shared_ptr<Font> SkityFont::MakeFont(const void* bytes, size_t len) {
  const auto data = skity::Data::MakeWithProc(bytes, len, nullptr, nullptr);
  return std::make_shared<SkityFont>(
      skity::Font(skity::Typeface::MakeFromData(data)));
}

std::shared_ptr<Font> SkityFont::MakeDefaultFont() {
  return std::make_shared<SkityFont>(
      skity::Font(skity::Typeface::GetDefaultTypeface()));
}

void SkityFont::SetTextSize(float text_size) { font_.SetSize(text_size); }

float SkityFont::MeasureText(const std::string& text) const {
  skity::Paint paint;
  paint.SetTextSize(font_.GetSize());
  paint.SetTypeface(font_.GetTypeface());

  skity::TextBlobBuilder builder;
  auto blob = builder.BuildTextBlob(text.c_str(), paint, delegate_.get());

  if (blob) {
    auto bounds = blob->GetBoundSize();
    return bounds.x;
  }

  return 0;
}

skity::Typeface* FallbackTypefaceDelegate::Fallback(
    skity::Unichar code_point, skity::Paint const& text_paint) {
  auto font_manager = skity::FontManager::RefDefault();

  auto type_face = font_manager->MatchFamilyStyleCharacter(
      0, skity::FontStyle(), nullptr, 0, code_point);
  return type_face;
}

}  // namespace animax
}  // namespace lynx
