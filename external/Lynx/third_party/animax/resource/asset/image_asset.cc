// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/resource/asset/image_asset.h"

#include "animax/base/log.h"
#include "animax/render/include/context.h"
#include "canvas/bitmap.h"

namespace lynx {
namespace animax {

ImageAsset::ImageAsset(int32_t width, int32_t height, std::string& id,
                       std::string& file_name, std::string& dir_name) {
  width_ = width;
  height_ = height;
  id_ = id;
  file_name_ = file_name;
  dir_name_ = dir_name;
  has_base64_ = file_name_.rfind("data:", 0) == 0 &&
                file_name_.find("base64,") != std::string::npos;
}

void ImageAsset::AttachBitmapDirectly(std::unique_ptr<canvas::Bitmap> bitmap) {
  bitmap_ = std::move(bitmap);
}

void ImageAsset::LoadBitmapBy(
    canvas::ResourceLoader& loader, const std::string& prefix,
    std::unordered_map<std::string, std::string>& polyfill_map,
    const std::function<void(std::unique_ptr<canvas::Bitmap>, bool)>&
        callback) {
  if (bitmap_ || image_) {
    callback(nullptr, true);
    return;
  }

  // 1. check base64 first
  if (has_base64_) {
    auto bitmap = loader.DecodeDataURLSync(file_name_);
    if (bitmap) {
      callback(std::move(bitmap), true);
      return;
    }
  }

  // 2. check polyfill map match
  if (file_name_ == "%s") {
    // use polyfillmap to query
    if (!polyfill_map.empty() && polyfill_map.find(id_) != polyfill_map.end()) {
      file_name_ = polyfill_map[id_];
      ANIMAX_LOGI("using polyfill:") << file_name_ << " on id:" << id_;
    } else {
      callback(nullptr, false);
      return;
    }
  }

  // 3. then check whether have full url to fetch from cdn
  std::string full_path;
  full_path.append(dir_name_).append(file_name_);
  if (prefix.empty() || full_path.empty()) {
    callback(nullptr, false);
    return;
  }

  std::string full_url;
  if (full_path.rfind("http") != 0) {
    full_url.append(prefix).append(full_path);
  } else {
    full_url = full_path;
  }

  ANIMAX_LOGI("start to request image by url:") << full_url;
  loader.LoadBitmap(
      full_url, [callback, full_url](std::unique_ptr<canvas::Bitmap> bitmap) {
        callback(std::move(bitmap), true);
      });
}

std::string& ImageAsset::GetDirName() { return dir_name_; }

std::string& ImageAsset::GetFileName() { return file_name_; }

std::string& ImageAsset::GetImageId() { return id_; }

Image* ImageAsset::GetImage(RealContext* real_context) {
  if (image_) {
    return image_.get();
  }

  if (bitmap_) {
    image_ = Context::MakeImage(*bitmap_, real_context);
  }

  return image_.get();
}

}  // namespace animax
}  // namespace lynx
