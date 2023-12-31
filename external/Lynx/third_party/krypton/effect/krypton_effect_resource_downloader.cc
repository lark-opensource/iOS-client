//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "krypton_effect_resource_downloader.h"

#include <atomic>
#include <string>
#include <vector>

#include "canvas/base/log.h"
#include "canvas/platform/camera_option.h"
#include "krypton_effect_video_context.h"

namespace lynx {
namespace canvas {
namespace effect {

void EffectResourceDownloader::PrepareEffectResource(
    uint32_t algorithms, EffectPrepareResourceCallback callback) {
  if (is_preparing_) {
    callback("last prepare task not complete");
    return;
  }

  bool enable_beautify = algorithms & EffectAlgorithms::kEffectBeautify;

  is_preparing_ = true;
  resource_downloaded_ = !enable_beautify;
  models_downloaded_ = false;
  auto fn = [=]() {
    if (!this->resource_downloaded_ || !this->models_downloaded_) {
      return;
    }

    is_preparing_ = false;
    callback({});
  };

  if (enable_beautify) {
    KRYPTON_LOGI("download bundle start");
    DownloadBundles(
        [callback, fn, this](std::string path, std::optional<std::string> err) {
          if (err) {
            KRYPTON_LOGE("download beautify bundles fail ") << err->c_str();
            this->is_preparing_ = false;
            callback(err);
            return;
          }

          this->SetBundlePath(path);
          this->resource_downloaded_ = true;
          fn();
        });
  }

  std::vector<const char *> requirements;
  if (algorithms & EffectAlgorithms::kEffectFace) {
    requirements.push_back("faceDetect");
  }

  if (algorithms & EffectAlgorithms::kEffectSkeleton) {
    requirements.push_back("skeletonDetect");
  }

  if (algorithms & EffectAlgorithms::kEffectHand) {
    requirements.push_back("handDetect");
  }

  KRYPTON_LOGI("download models start");
  DownloadModels(
      requirements,
      [callback, fn, this](std::string path, std::optional<std::string> err) {
        if (err) {
          KRYPTON_LOGE("download model fail ") << err->c_str();
          this->is_preparing_ = false;
          callback(err);
          return;
        }

        this->algorithm_model_path_ = path.c_str();
        this->models_downloaded_ = true;
        fn();
      });
}

}  // namespace effect
}  // namespace canvas
}  // namespace lynx
