// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_RESOURCE_DOWNLOADER_H
#define KRYPTON_EFFECT_RESOURCE_DOWNLOADER_H

#include <filesystem>
#include <functional>
#include <memory>
#include <optional>
#include <string>

#include "canvas/canvas_app.h"
#include "effect/krypton_effect_pfunc.h"

namespace lynx {
namespace canvas {
using StickerDownloadCallbackType = std::function<void(int, int, std::string)>;
using ModelDownloadWithResultCallbackType =
    std::function<void(bool, int, const char*)>;
using BundleDownloadWithResultCallbackType =
    std::function<void(const char*, const char*)>;
using DownloadStickerCallbackArgsType =
    std::tuple<bool, int, std::string, std::string>;
typedef void (*StickerDownloadWithProgressCallbackType)(void*, bool, float,
                                                        const char*, int64_t,
                                                        const char*);

namespace effect {

class EffectResourceDownloader {
 public:
  static EffectResourceDownloader* Instance();
  virtual ~EffectResourceDownloader() = default;

  virtual void SetCanvasApp(const std::shared_ptr<CanvasApp>& canvas_app) = 0;

  virtual void* GetResourceFinder(void* effect_handler) = 0;

  using EffectPrepareResourceCallback =
      std::function<void(std::optional<std::string>)>;
  void PrepareEffectResource(uint32_t algorithms,
                             EffectPrepareResourceCallback callback);

  const char* ReshapePath() { return reshape_path_.c_str(); }
  const char* QingYanPath() { return qingyan_path_.c_str(); }

  std::string AlgorithmModelPath() { return algorithm_model_path_; }

  /**
   * bundle_path =
   * "/data/user/0/com.lynx.uiapp/files/effect/IESLiveEffectResource.bundle"
   * @param bundle_path
   */
  void SetBundlePath(std::string bundle_path) {
    bundle_path_ = bundle_path;
    reshape_path_ = bundle_path_ + "/B612ReshapeCompser";
    qingyan_path_ = bundle_path_ + "/Qinyan2Composer";
  }

  std::string BundlePath() { return bundle_path_; }

  using EffectDownloadWithPathCallback =
      std::function<void(std::string, std::optional<std::string>)>;
  virtual void DownloadBundles(EffectDownloadWithPathCallback callback) = 0;
  virtual void DownloadModels(std::vector<const char*> requirement,
                              EffectDownloadWithPathCallback callback) = 0;

  virtual bool DownloadSticker(
      const char* sticker_id,
      std::unique_ptr<StickerDownloadCallbackType> cb) = 0;

  virtual void OnEffectHandlerRelease(bef_effect_handle_t effect_handler){};

 private:
  std::atomic<bool> resource_downloaded_{false};
  std::atomic<bool> models_downloaded_{false};
  std::atomic<bool> is_preparing_{false};

  std::string reshape_path_;
  std::string qingyan_path_;
  std::string algorithm_model_path_;
  std::string bundle_path_;
};

}  // namespace effect
}  // namespace canvas
}  // namespace lynx

#endif /* KRYPTON_EFFECT_RESOURCE_DOWNLOADER_H */
