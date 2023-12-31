// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RESOURCE_ASSET_IMAGE_ASSET_H_
#define ANIMAX_RESOURCE_ASSET_IMAGE_ASSET_H_

#include <string>
#include <unordered_map>

#include "animax/render/include/canvas.h"
#include "animax/render/include/image.h"
#include "canvas/bitmap.h"
#include "canvas/platform/resource_loader.h"

namespace lynx {
namespace animax {

class ImageLayer;

class ImageAsset {
 public:
  ImageAsset(int32_t width, int32_t height, std::string& id,
             std::string& file_name, std::string& dir_name);
  ~ImageAsset() = default;

  std::string& GetDirName();
  std::string& GetFileName();
  std::string& GetImageId();
  Image* GetImage(RealContext* real_context);

  void AttachBitmapDirectly(std::unique_ptr<canvas::Bitmap> bitmap);

  void LoadBitmapBy(canvas::ResourceLoader& loader, const std::string& prefix,
                    std::unordered_map<std::string, std::string>& polyfill_map,
                    const std::function<void(std::unique_ptr<canvas::Bitmap>,
                                             bool)>& callback);

 private:
  friend class ImageLayer;

  /**
   *  {
          "id": "image_0",
          "w": 132,
          "h": 745,
          "u": "images/",
          "p": "img_0.png", # if use src-polyfill, set this to %s
          "e": 0
      }
   */

  int32_t width_ = 0;      // w
  int32_t height_ = 0;     // h
  std::string id_;         // id
  std::string dir_name_;   // u
  std::string file_name_;  // p

  bool has_base64_ = false;  // "p" has base64 text

  std::unique_ptr<canvas::Bitmap> bitmap_;
  std::shared_ptr<Image> image_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RESOURCE_ASSET_IMAGE_ASSET_H_
