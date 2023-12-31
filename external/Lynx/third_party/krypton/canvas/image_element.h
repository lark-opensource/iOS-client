// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_IMAGE_ELEMENT_H_
#define CANVAS_IMAGE_ELEMENT_H_

#include <string>

#include "canvas/canvas_image_source.h"
#include "canvas/instance_guard.h"
#include "canvas/platform/resource_loader.h"
#include "event_target.h"
#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class ImageElement : public CanvasImageSource, public EventTarget {
 public:
  static std::unique_ptr<ImageElement> Create() {
    return std::unique_ptr<ImageElement>(new ImageElement());
  }
  ImageElement();
  ImageElement(const ImageElement&) = delete;
  ~ImageElement() override;

  void SetSrc(const std::string& src);
  std::string GetSrc() const { return src_; }

  bool GetComplete() const { return load_complete_; };

  bool IsImageElement() const override { return true; }

  uint32_t GetWidth() override;

  uint32_t GetHeight() override;

  std::shared_ptr<Bitmap> GetBitmap();
#ifndef ENABLE_RENDERKIT_CANVAS
  std::shared_ptr<shell::LynxActor<TextureSource>> GetTextureSource() override;
#endif
  void ReleaseUsedMemIfNeed();

  void OnWrapped() override;

  // Workaround for #5656.
  void HoldObject();
  void ReleaseObject();

  // TODO(yudingqian): Add interface for ImageElement and move these methods to
  // Renderkit derived class
  void OnLoadImageFromRenderkit(uint32_t image_id);
  void SetImageIDForRenderkit(uint32_t image_id) {
    image_id_renderkit_ = image_id;
  }
  uint32_t GetImageIDRenderkit() override { return image_id_renderkit_; }

 private:
  void InternalLoad(const std::string& src);
  void TriggerOnLoad();
  void TriggerOnError();
  void ReloadURLIfNeed();
  void DoReleaseMemUsed();

  std::string src_;
  std::shared_ptr<Bitmap> bitmap_;
  std::shared_ptr<shell::LynxActor<TextureSource>> texture_source_;

  bool load_complete_{false};
  std::shared_ptr<InstanceGuard<ImageElement>> instance_guard_ = nullptr;
  const std::string id_;

  uint32_t image_id_renderkit_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_IMAGE_ELEMENT_H_
