// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RESOURCE_ASSET_FONT_ASSET_H_
#define ANIMAX_RESOURCE_ASSET_FONT_ASSET_H_

#include <memory>

#include "animax/model/basic_model.h"
#include "animax/render/include/font.h"
#include "canvas/platform/resource_loader.h"

namespace lynx {
namespace animax {

class FontAsset {
 public:
  FontAsset() = default;
  FontAsset(const std::string& family, const std::string& name,
            const std::string& style, float ascent, std::string path)
      : family_(family),
        name_(name),
        style_(style),
        ascent_(ascent),
        path_(path) {}
  ~FontAsset() = default;

  std::string& GetName() { return name_; }
  std::string& GetFontFamily() { return family_; }

  void AttachRawDataDirectly(std::unique_ptr<canvas::RawData> raw_data);
  void LoadFontBy(canvas::ResourceLoader& loader, const std::string& prefix,
                  const std::function<void(std::unique_ptr<canvas::RawData>,
                                           bool)>& callback);

  Font* GetFont();

 private:
  friend class TextLayer;

  /**
    * {
          "origin": 0,
          "fPath": "",
          "fClass": "",
          "fFamily": "Arial",
          "fWeight": "",
          "fStyle": "Regular",
          "fName": "ArialMT",
          "ascent": 71.5988159179688
      }
   */

  std::string family_;  // fFamily
  std::string name_;    // fName
  std::string style_;   // fStyle
  float ascent_ = 0;    // ascent
  std::string path_;    // fPath

  std::unique_ptr<canvas::RawData> raw_data_;
  std::shared_ptr<Font> font_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RESOURCE_ASSET_FONT_ASSET_H_
