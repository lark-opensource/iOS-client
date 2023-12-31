// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/resource/asset/font_asset.h"

#include "animax/render/include/context.h"

namespace lynx {
namespace animax {

void FontAsset::AttachRawDataDirectly(
    std::unique_ptr<canvas::RawData> raw_data) {
  raw_data_ = std::move(raw_data);
}

void FontAsset::LoadFontBy(
    canvas::ResourceLoader& loader, const std::string& prefix,
    const std::function<void(std::unique_ptr<canvas::RawData>, bool)>&
        callback) {
  if (font_ || raw_data_) {
    callback(nullptr, true);
    return;
  }

  std::string full_url;
  if (path_.rfind("http") == 0) {
    full_url = path_;
  } else if (!prefix.empty() && !family_.empty()) {
    full_url.append(prefix).append("fonts/").append(family_).append(".ttf");
  } else {
    callback(nullptr, false);
    return;
  }

  loader.LoadData(full_url,
                  [callback](std::unique_ptr<canvas::RawData> raw_data) {
                    if (raw_data && raw_data->length > 1000) {
                      callback(std::move(raw_data), true);
                    } else {
                      callback(nullptr, false);
                    }
                  });
}

Font* FontAsset::GetFont() {
  if (font_) {
    return font_.get();
  }

  if (raw_data_) {
    font_ = Context::MakeFont(raw_data_->data->Data(), raw_data_->length);
  }

  font_ = Context::MakeDefaultFont();

  return font_.get();
}

}  // namespace animax
}  // namespace lynx
