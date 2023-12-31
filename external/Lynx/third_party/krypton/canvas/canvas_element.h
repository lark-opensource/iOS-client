// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_CANVAS_ELEMENT_H_
#define CANVAS_CANVAS_ELEMENT_H_

#include <cstddef>
#include <memory>
#include <string>

#include "canvas/base/data_holder.h"
#include "canvas/canvas_image_source.h"
#include "canvas/canvas_resource_provider.h"
#include "canvas/canvas_view.h"
#include "canvas/event_target.h"
#include "canvas/instance_guard.h"
#include "canvas/platform_view_observer.h"
#include "canvas/text/typeface.h"
#include "canvas/webgl/canvas_renderbuffer.h"
#include "jsbridge/bindings/canvas/napi_webgl_context_attributes.h"
#include "jsbridge/napi/base.h"
#include "shell/lynx_actor.h"

namespace lynx {
namespace canvas {

class BoundRect;

class CanvasContext;

class CanvasRenderingContext2D;

class CanvasRenderingContext2DLite;

class CanvasRenderingContext2DRK;

class WebGLRenderingContext;

using piper::BridgeBase;
using piper::ImplBase;

class CanvasElement : public CanvasImageSource, public EventTarget {
 public:
  static std::unique_ptr<CanvasElement> Create() {
    return std::unique_ptr<CanvasElement>(new CanvasElement());
  }

  static std::unique_ptr<CanvasElement> Create(const std::string &id,
                                               bool legacy_behaviors = true) {
    return std::unique_ptr<CanvasElement>(
        new CanvasElement(id, legacy_behaviors));
  }

  CanvasElement();

  CanvasElement(std::string id, bool legacy_behaviors);

  CanvasElement(const CanvasElement &) = delete;

  ~CanvasElement() override;

  CanvasElement &operator=(const CanvasElement &) = delete;

  void OnWrapped() override;

  bool AttachToCanvasView(std::string name);

  bool DetachFromCanvasView();

  void SetWidth(Napi::Number width);

  void SetHeight(Napi::Number height);

  void SetWidth(size_t width);

  void SetHeight(size_t height);

  void TriggerTouchEvent(std::shared_ptr<DataHolder> event);

  void TriggerResizeEvent(size_t width, size_t height);

  size_t GetTouchDec95Width();

  size_t GetTouchDec95Height();

  bool GetIsSurfaceCreated();

  std::string GetCanvasId();

  uint32_t GetWidth() override;

  uint32_t GetHeight() override;

  uint32_t GetClientWidth();

  uint32_t GetClientHeight();

  void SetClientWidth(uint32_t width);

  void SetClientHeight(uint32_t height);

#ifndef ENABLE_RENDERKIT_CANVAS

  std::shared_ptr<shell::LynxActor<TextureSource>> GetTextureSource() override;

#endif

  CanvasContext *GetContext(const std::string &type);

  BoundRect *GetBoundingClientRect();

  CanvasContext *GetContext(const std::string &type,
                            std::unique_ptr<WebGLContextAttributes>);

  std::string ToDataURL();

  std::string ToDataURL(const std::string &type);

  std::string ToDataURL(const std::string &type, double encoderOptions);

  bool HasContext(const std::string &type);

  std::shared_ptr<CanvasResourceProvider> ResourceProvider() {
    return resource_provider_;
  }

  void DidCanvasRecreated();

  void WillDraw() override;

  void Clear();

#ifdef ENABLE_LYNX_CANVAS_SKIA
  sk_sp<SkImage> GetSourceImageForCanvas(SourceImageStatus *status) override;

  void ReadPixels(const SkIPoint &start, const SkPixmap &pixmap);
#else

  void ReadPixels(int x, int y, int width, int height, void *data,
                  bool premultiply_alpha = false);

  void PutPixels(void *data, int width, int height, int dx, int dy, int dirtyX,
                 int dirtyY, int dirtyWidth, int dirtyHeight);

#endif

  bool IsCanvasElement() const override { return true; }

  size_t UniqueId() const { return unique_id_; }

  int32_t GetRasterPriority() { return raster_priority_; }

  FontCache *GetFontCache() { return resource_provider_->GetFontCache(); }

  FontCollection *GetFontCollection() const;

  std::shared_ptr<InstanceGuard<CanvasElement>> GetInstanceGuard();

 private:
  static size_t GenerateUniqueId() {
    static size_t next_id = 0;
    return next_id++;
  }

  void ListenAppShowStatus();
  void ListenPlatformViewEvents();
  void CancelListenPlatformViewEvents();

  inline void TriggerEventInternal(const std::string &type,
                                   const Napi::Object &event) {
    // trigger add event listener callback
    TriggerEventListeners(type, event);
  }

  Napi::Object GenTouchEvent(const std::string &type,
                             std::shared_ptr<DataHolder> event);

  Napi::Object GenTouchItem(const std::string &type,
                            const CanvasTouchEvent::TouchItem &event,
                            int canvas_x, int canvas_y);

  std::string GetTouchEventType(CanvasTouchEvent::Action action);

  void ClearFrameBuffer();

  static constexpr int kDefaultWidth = 300;
  static constexpr int kDefaultHeight = 150;
  std::string canvas_id_;
  std::shared_ptr<CanvasResourceProvider> resource_provider_;
  std::shared_ptr<shell::LynxActor<TextureSource>> texture_source_;
  size_t width_;
  size_t height_;
  size_t unique_id_;
  int32_t raster_priority_;
#ifdef ENABLE_LYNX_CANVAS_SKIA
  CanvasRenderingContext2D *context_2d_{nullptr};
#elif ENABLE_RENDERKIT_CANVAS
  CanvasRenderingContext2DRK *context_2d_{nullptr};
#else
  CanvasRenderingContext2DLite *context_2d_{nullptr};
#endif
  WebGLRenderingContext *context_webgl_{nullptr};

  bool legacy_behaviors_{false};

  std::shared_ptr<InstanceGuard<CanvasElement>> instance_guard_{nullptr};
  // NOTICE!! client width and client height is a readonly in web standard.
  // User cannot get client width/height in js thread synchronized in Lynx
  // environment. So need to support user custom client width and height.
  std::optional<uint32_t> custom_client_width_;
  std::optional<uint32_t> custom_client_height_;

  std::shared_ptr<PlatformViewEventListener> event_listener_;
  std::shared_ptr<AppShowStatusObserver> app_show_status_observer_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_CANVAS_ELEMENT_H_
