// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_RESOURCE_DOWNLOADER_IOS_H
#define KRYPTON_EFFECT_RESOURCE_DOWNLOADER_IOS_H

#include "krypton_effect_resource_downloader.h"

namespace lynx {
namespace canvas {
namespace effect {

class EffectResourceDownloaderIOS : public EffectResourceDownloader {
 public:
  void SetCanvasApp(const std::shared_ptr<CanvasApp>& canvas_app) override;

  void* GetResourceFinder(void* effect_handler) override;

  void DownloadBundles(EffectDownloadWithPathCallback callback) override;
  void DownloadModels(std::vector<const char*> requirement,
                      EffectDownloadWithPathCallback callback) override;

  bool DownloadSticker(
      const char* sticker_id,
      std::unique_ptr<StickerDownloadCallbackType> cb) override;
};

}  // namespace effect
}  // namespace canvas
}  // namespace lynx

#endif  // KRYPTON_EFFECT_RESOURCE_DOWNLOADER_IOS_H
