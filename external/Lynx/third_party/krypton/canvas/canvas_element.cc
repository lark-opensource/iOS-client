// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas_element.h"

#include <utility>

#include "canvas/background_lock.h"
#include "canvas/base/log.h"
#include "canvas/bound_rect.h"
#include "canvas/canvas_app.h"
#include "canvas/canvas_view.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"
#include "canvas/gpu/gl_global_device_attributes.h"
#include "canvas/text/font_collection.h"
#include "canvas/text/typeface.h"
#include "canvas/util/texture_util.h"
#include "canvas/util/utils.h"
#include "canvas/webgl/canvas_element_texture_source.h"
#include "canvas/webgl/webgl_rendering_context.h"
#include "config/config.h"
#include "jsbridge/bindings/canvas/canvas_module.h"
#include "jsbridge/bindings/canvas/napi_canvas_rendering_context_2d.h"
#include "jsbridge/bindings/canvas/napi_webgl_rendering_context.h"

#ifdef ENABLE_LYNX_CANVAS_SKIA
#include "canvas/2d/canvas_rendering_context_2d.h"
#include "canvas/util/skia.h"
#else
#include "canvas/2d/lite/canvas_rendering_context_2d_lite.h"
#include "canvas/2d/lite/canvas_resource_provider_2d_lite.h"
#endif

namespace lynx {
namespace canvas {

constexpr float kDefaultEncoderOptions =
    0.92;  // 0.92 is magic number align to web standard.

constexpr int CanvasElement::kDefaultWidth;
constexpr int CanvasElement::kDefaultHeight;
using Napi::PropertyDescriptor;

CanvasElement::CanvasElement()
    : width_(kDefaultWidth),
      height_(kDefaultHeight),
      unique_id_(GenerateUniqueId()) {
  raster_priority_ = unique_id_;
  KRYPTON_CONSTRUCTOR_LOG(CanvasElement);
}

CanvasElement::CanvasElement(std::string id, bool legacy_behaviors)
    : canvas_id_(std::move(id)),
      width_(kDefaultWidth),
      height_(kDefaultHeight),
      unique_id_(GenerateUniqueId()),
      legacy_behaviors_(legacy_behaviors) {
  raster_priority_ = unique_id_;
  KRYPTON_CONSTRUCTOR_LOG(CanvasElement);
}

CanvasElement::~CanvasElement() {
  if (resource_provider_) {
    resource_provider_->SetCanvasElement(nullptr);
  }
  CancelListenPlatformViewEvents();
  if (texture_source_) {
    texture_source_->Act([](auto& impl) {
#ifdef OS_IOS
      BackgroundLock::Instance().WaitForForeground();
#endif
      impl.reset();
    });
  }

  KRYPTON_DESTRUCTOR_LOG(CanvasElement);
}

bool CanvasElement::HasContext(const std::string& type) {
  if (type == "2d") {
    return context_2d_ != nullptr;
  } else if (type == "webgl" || type == "experimental-webgl") {
    return context_webgl_ != nullptr;
  }
  return false;
}

CanvasContext* CanvasElement::GetContext(const std::string& type) {
  return GetContext(type, nullptr);
}

CanvasContext* CanvasElement::GetContext(
    const std::string& type,
    std::unique_ptr<WebGLContextAttributes> context_attributes) {
  if (type == "2d") {
    if (context_2d_) {
      return context_2d_;
    }

    if (context_webgl_) {
      return nullptr;
    }

#ifdef ENABLE_LYNX_CANVAS_SKIA
    if (!GetResourceProvider(true)) {
      return nullptr;
    }

    context_2d_ = new CanvasRenderingContext2D(this);
    Napi::Object ctx = NapiCanvasRenderingContext2D::Wrap(
        std::unique_ptr<CanvasRenderingContext2D>(context_2d_), Env());
    PropertyDescriptor ctx_property_descriptor =
        PropertyDescriptor::Value("_ctx", ctx, napi_default);
    JsObject().DefineProperty(ctx_property_descriptor);

    PropertyDescriptor canvas_property_descriptor =
        PropertyDescriptor::Value("_canvas", JsObject(), napi_default);
    ctx.DefineProperty(canvas_property_descriptor);

    return context_2d_;
#else
    auto resource_provider = std::make_shared<CanvasResourceProvider2DLite>(
        this, canvas_app_->runtime_actor(),
        canvas_app_->surface_registry_actor());
    if (!resource_provider->Init(canvas_app_->gpu_task_runner())) {
      return nullptr;
    }

    resource_provider_ = std::move(resource_provider);
    auto texture_source = std::unique_ptr<TextureSource>(
        static_cast<TextureSource*>(new CanvasElementTextureSource(
            resource_provider_->gpu_actor(), true)));
    texture_source_ = std::make_shared<shell::LynxActor<TextureSource>>(
        std::move(texture_source), canvas_app_->gpu_task_runner());

    context_2d_ = new CanvasRenderingContext2DLite(this);

    Napi::Object ctx = NapiCanvasRenderingContext2D::Wrap(
        std::unique_ptr<CanvasRenderingContext2D>(context_2d_), Env());
    PropertyDescriptor ctx_property_descriptor =
        PropertyDescriptor::Value("__krypton__ctx", ctx, napi_default);
    JsObject().DefineProperty(ctx_property_descriptor);

    PropertyDescriptor canvas_property_descriptor = PropertyDescriptor::Value(
        "__krypton__canvas", JsObject(), napi_default);
    ctx.DefineProperty(canvas_property_descriptor);

    return context_2d_;
#endif
  } else if (type == "webgl" || type == "experimental-webgl") {
    if (context_webgl_) {
      return context_webgl_;
    }

    if (context_2d_) {
      return nullptr;
    }

    // in browser env, anti alias is the default, but as we do not support it
    // yet, we treat it false as default.
    auto resource_provider_option = CanvasResourceProvider::Option{
        .antialias = context_attributes &&
                     (context_attributes->hasAntialias() &&
                      context_attributes->antialias()) &&
                     context_attributes->enableMSAA(),
    };
    auto resource_provider = std::make_shared<CanvasResourceProvider3D>(
        this, canvas_app_->runtime_actor(),
        canvas_app_->surface_registry_actor(), resource_provider_option);
    if (!resource_provider->Init(canvas_app_->gpu_task_runner())) {
      return nullptr;
    }

    resource_provider_ = std::move(resource_provider);
    auto texture_source = std::unique_ptr<TextureSource>(
        static_cast<TextureSource*>(new CanvasElementTextureSource(
            resource_provider_->gpu_actor(), false)));
    texture_source_ = std::make_shared<shell::LynxActor<TextureSource>>(
        std::move(texture_source), canvas_app_->gpu_task_runner());

    context_webgl_ = new WebGLRenderingContext(this, canvas_app_,
                                               std::move(context_attributes));

    Napi::Object ctx = NapiWebGLRenderingContext::Wrap(
        std::unique_ptr<WebGLRenderingContext>(context_webgl_), Env());
    PropertyDescriptor ctx_property_descriptor =
        PropertyDescriptor::Value("__krypton__ctx", ctx, napi_default);
    JsObject().DefineProperty(ctx_property_descriptor);

    PropertyDescriptor canvas_property_descriptor = PropertyDescriptor::Value(
        "__krypton__canvas", JsObject(), napi_default);
    ctx.DefineProperty(canvas_property_descriptor);

    return context_webgl_;
  }
  return nullptr;
}

std::string CanvasElement::ToDataURL() {
  return ToDataURL("image/png", kDefaultEncoderOptions);
}

std::string CanvasElement::ToDataURL(const std::string& type) {
  return ToDataURL(type, kDefaultEncoderOptions);
}

std::string CanvasElement::ToDataURL(const std::string& type,
                                     double encoderOptions) {
  ResourceLoader::ImageType imageType;
  if (type == "image/png") {
    imageType = ResourceLoader::ImageType::PNG;
  } else if (type == "image/jpeg") {
    imageType = ResourceLoader::ImageType::JPEG;
  } else {  /// TODO: support other image type
    return "";
  }

  if (encoderOptions < 0 || encoderOptions > 1.0) {
    encoderOptions = kDefaultEncoderOptions;
  }

  uint32_t bpr = static_cast<uint32_t>(width_ << 2);
  void* pixels = malloc(bpr * height_);
  // ReadPixels remains alpha premultiplied because platform interface will
  // encode image with alpha premultiplied.
  ReadPixels(0, 0, static_cast<int>(width_), static_cast<int>(height_), pixels,
             true);

  Bitmap bitmap(static_cast<int>(width_), static_cast<int>(height_), GL_RGBA,
                GL_UNSIGNED_BYTE,
                DataHolder::MakeWithMoveTo(pixels, bpr * height_), 1);

  auto rawData = canvas_app_->resource_loader()->EncodeBitmap(bitmap, imageType,
                                                              encoderOptions);
  if (!rawData->length) {
    return "";
  }

  size_t length = Base64::encode_buflen(static_cast<uint32_t>(rawData->length));
  if (imageType == ResourceLoader::ImageType::PNG) {
    length += 22;
  } else {
    length += 23;
  }
  char* chars = new char[length + 1];
  int loc = snprintf(chars, 24, "data:%s;base64,", type.c_str());
  Base64::encode(static_cast<const uint8_t*>(rawData->data->Data()),
                 static_cast<uint32_t>(rawData->length), chars + loc);
  std::string dataURL(chars);
  delete[] chars;
  return dataURL;
}

void CanvasElement::SetWidth(Number width) { SetWidth(width.Uint32Value()); }

void CanvasElement::SetHeight(Number height) {
  SetHeight(height.Uint32Value());
}

void CanvasElement::SetWidth(size_t width) {
  KRYPTON_LOGI("canvas element set width ") << width << "id" << canvas_id_;
  if (width <= 0) return;
  width_ = width;
  if (resource_provider_) {
    resource_provider_->OnCanvasSizeChanged();
  }

  if (texture_source_) {
    texture_source_->Act([w = width, h = height_](auto& impl) {
      static_cast<CanvasElementTextureSource*>(impl.get())
          ->OnCanvasSizeChange(w, h);
    });
  }
#ifdef ENABLE_LYNX_CANVAS_SKIA
  if (context_2d_) {
    context_2d_->Reset();
  }
#endif
}

void CanvasElement::SetHeight(size_t height) {
  KRYPTON_LOGI("canvas element set height ") << height << "id" << canvas_id_;
  if (height <= 0) return;
  height_ = height;
  if (resource_provider_) {
    resource_provider_->OnCanvasSizeChanged();
  }

  if (texture_source_) {
    texture_source_->Act([w = width_, h = height](auto& impl) {
      static_cast<CanvasElementTextureSource*>(impl.get())
          ->OnCanvasSizeChange(w, h);
    });
  }
#ifdef ENABLE_LYNX_CANVAS_SKIA
  if (context_2d_) {
    context_2d_->Reset();
  }
#endif
}

uint32_t CanvasElement::GetWidth() { return static_cast<uint32_t>(width_); }

uint32_t CanvasElement::GetHeight() { return static_cast<uint32_t>(height_); }

uint32_t CanvasElement::GetClientWidth() {
  if (custom_client_width_.has_value()) {
    return *custom_client_width_;
  }
  const auto* platform_view_info =
      canvas_app_->platform_view_observer()->GetViewInfoByViewName(canvas_id_);
  if (platform_view_info) {
    return platform_view_info->width;
  }
  return 0;
}

uint32_t CanvasElement::GetClientHeight() {
  if (custom_client_height_.has_value()) {
    return *custom_client_height_;
  }
  const auto* platform_view_info =
      canvas_app_->platform_view_observer()->GetViewInfoByViewName(canvas_id_);
  if (platform_view_info) {
    return platform_view_info->height;
  }
  return 0;
}

void CanvasElement::SetClientWidth(uint32_t width) {
  custom_client_width_ = width;
}

void CanvasElement::SetClientHeight(uint32_t height) {
  custom_client_height_ = height;
}

std::shared_ptr<shell::LynxActor<TextureSource>>
CanvasElement::GetTextureSource() {
  return texture_source_;
}

std::string CanvasElement::GetCanvasId() { return canvas_id_; }

size_t CanvasElement::GetTouchDec95Width() {
  const auto* platform_view_info =
      canvas_app_->platform_view_observer()->GetViewInfoByViewName(canvas_id_);
  if (platform_view_info) {
    return platform_view_info->touch_width;
  }
  return 0;
}

size_t CanvasElement::GetTouchDec95Height() {
  const auto* platform_view_info =
      canvas_app_->platform_view_observer()->GetViewInfoByViewName(canvas_id_);
  if (platform_view_info) {
    return platform_view_info->touch_height;
  }
  return 0;
}

bool CanvasElement::GetIsSurfaceCreated() {
  return canvas_app_->platform_view_observer()->IsPlatformViewAvailable(
      canvas_id_);
}

void CanvasElement::DidCanvasRecreated() {
#ifdef ENABLE_LYNX_CANVAS_SKIA
  if (context_2d_) {
    context_2d_->RestoreMatrixClipStack();
  }
#else
  if (context_2d_) {
    context_2d_->Reset();
  }
#endif
}

#ifdef ENABLE_LYNX_CANVAS_SKIA
sk_sp<SkImage> CanvasElement::GetSourceImageForCanvas(
    SourceImageStatus* status) {
  if (!GetWidth() || !GetHeight()) {
    *status = kZeroSizeCanvasSourceImageStatus;
    return nullptr;
  }
  if (resource_provider_) {
    return resource_provider_->MakeSnapshot(SkIRect::MakeWH(width_, height_));
  } else {
    *status = kInvalidSourceImageStatus;
    sk_sp<SkSurface> surface = SkSurface::MakeRasterN32Premul(width_, height_);
    return surface ? surface->makeImageSnapshot() : nullptr;
  }
}

void CanvasElement::ReadPixels(const SkIPoint& start, const SkPixmap& pixmap) {
  if (resource_provider_) {
    // only for read self, do not need pass grcontext
    resource_provider_->MakeSnapshot(
        SkIRect::MakeXYWH(start.x(), start.y(), pixmap.width(),
                          pixmap.height()),
        &pixmap);
  } else {
    sk_sp<SkSurface> surface =
        SkSurface::MakeRasterN32Premul(pixmap.width(), pixmap.height());
    sk_sp<SkImage> snapshot = surface->makeImageSnapshot();
    snapshot->readPixels(pixmap, 0, 0);
  }
}

#else

void CanvasElement::ReadPixels(int x, int y, int width, int height, void* data,
                               bool premultiply_alpha) {
  if (resource_provider_) {
    WillDraw();
    resource_provider_->ReadPixels(x, GetHeight() - y - height, width, height,
                                   data, premultiply_alpha);
  }
}

void CanvasElement::PutPixels(void* data, int width, int height, int dx, int dy,
                              int dirtyX, int dirtyY, int dirtyWidth,
                              int dirtyHeight) {
  if (resource_provider_) {
    resource_provider_->PutPixels(data, width, height, dirtyX, dirtyY,
                                  dirtyWidth, dirtyHeight, dirtyX + dx,
                                  GetHeight() - (dirtyY + dy + dirtyHeight),
                                  dirtyWidth, dirtyHeight);
  }
}

#endif

void CanvasElement::WillDraw() {
  if (resource_provider_) {
    // offscreen surface may not created or changed, wait for the lastest one.
    resource_provider_->Flush(false, false, true);
  }
}

BoundRect* CanvasElement::GetBoundingClientRect() {
  const auto* platform_view_info =
      canvas_app_->platform_view_observer()->GetViewInfoByViewName(canvas_id_);
  if (platform_view_info) {
    auto rect = new BoundRect();
    if (legacy_behaviors_) {
      // Align with helium
      rect->set(platform_view_info->width, platform_view_info->height, 0, 0, 0,
                0, 0, 0);
    } else {
      rect->set(
          platform_view_info->width, platform_view_info->height,
          platform_view_info->layout.left, platform_view_info->layout.top,
          platform_view_info->layout.top, platform_view_info->layout.right,
          platform_view_info->layout.bottom, platform_view_info->layout.left);
    }
    return rect;
  }
  return nullptr;
}

void CanvasElement::OnWrapped() {
  canvas_app_ = CanvasModule::From(Env())->GetCanvasApp();
  ListenAppShowStatus();
  if (!canvas_id_.empty()) {
    ListenPlatformViewEvents();
  }
}

void CanvasElement::ClearFrameBuffer() {
  ScopedGLResetRestore s(GL_FRAMEBUFFER_BINDING);
  ScopedGLResetRestore s1(GL_COLOR_CLEAR_VALUE);
  ScopedGLResetRestore s2(GL_VIEWPORT);
  ScopedGLResetRestore s3(GL_SCISSOR_TEST);
  ScopedGLResetRestore s4(GL_COLOR_WRITEMASK);
  GL::BindFramebuffer(GL_FRAMEBUFFER, resource_provider_->drawing_fbo());
  GL::ClearColor(0, 0, 0, 0);
  GL::Viewport(0, 0, static_cast<GLsizei>(width_),
               static_cast<GLsizei>(height_));
  GL::Disable(GL_SCISSOR_TEST);
  GL::ColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
  if (resource_provider_->HasCanvasRenderBuffer()) {
    ScopedGLResetRestore ss(GL_DEPTH_CLEAR_VALUE);
    ScopedGLResetRestore ss1(GL_STENCIL_CLEAR_VALUE);
    ScopedGLResetRestore ss2(GL_DEPTH_WRITEMASK);
    ScopedGLResetRestore ss3(GL_STENCIL_WRITEMASK);
    GL::ClearDepthf(0);
    GL::ClearStencil(0);
    GL::DepthMask(GL_TRUE);
    GL::StencilMask(GL_TRUE);
    GL::Clear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT |
              GL_STENCIL_BUFFER_BIT);
  } else {
    GL::Clear(GL_COLOR_BUFFER_BIT);
  }
}

void CanvasElement::Clear() {
  canvas_app_->gpu_task_runner()->PostTask([this]() {
#ifdef OS_IOS
    BackgroundLock::Instance().WaitForForeground();
#endif
    ClearFrameBuffer();
  });
}

FontCollection* CanvasElement::GetFontCollection() const {
  return canvas_app_->GetFontCollection();
}

std::shared_ptr<InstanceGuard<CanvasElement>>
CanvasElement::GetInstanceGuard() {
  if (!instance_guard_) {
    instance_guard_ = InstanceGuard<CanvasElement>::CreateSharedGuard(this);
  }
  return instance_guard_;
}

bool CanvasElement::AttachToCanvasView(std::string name) {
  if (name.empty()) {
    Napi::Error::New(Env(), "Cannot attach to canvas view with empty name")
        .ThrowAsJavaScriptException();
    return false;
  }
  if (!canvas_id_.empty()) {
    if (canvas_id_ != name) {
      std::string error_message =
          "Canvas element has already attach to another view: " + canvas_id_ +
          " ,need call detachFromCanvasView first!";
      KRYPTON_LOGI("Canvas element with unique id: ")
          << unique_id_ << " attach failed, " << error_message;
      Napi::Error::New(Env(), error_message.c_str())
          .ThrowAsJavaScriptException();
      return false;
    } else {
      raster_priority_ = GenerateUniqueId();
      KRYPTON_LOGI("Canvas element intends to attach to same view: ") << name;
      if (resource_provider_) {
        KRYPTON_LOGI(
            "Update raster's priority and reassign surface to surface client");
        resource_provider_->UpdateRasterPriority(raster_priority_);
      }
      return true;
    }
  }

  KRYPTON_LOGI("Canvas element with unique id : ")
      << unique_id_ << " attach to canvas view with name: " << name;
  canvas_id_ = std::move(name);
  // update priority.
  // In some cases, canvasA may created before canvasB but attach to canvasView
  // later then canvasB. In such cases, surface need draw the content of
  // canvasA, so update priority before canvas attachToCanvasView
  raster_priority_ = GenerateUniqueId();
  if (resource_provider_) {
    KRYPTON_LOGI("This canvas element with unique id : ")
        << unique_id_
        << " is regard as an offscreen canvas with resource provider existed, "
           "attach to canvas view with name: "
        << canvas_id_;
    resource_provider_->AttachToOnscreenCanvas();
  }
  ListenPlatformViewEvents();
  if (GetIsSurfaceCreated()) {
    // Trigger resize event because element may listen event before attach
    TriggerResizeEvent(GetClientHeight(), GetClientHeight());
  }
  return true;
}

bool CanvasElement::DetachFromCanvasView() {
  if (canvas_id_.empty()) {
    KRYPTON_LOGI("Canvas element with unique_id: ")
        << unique_id_ << " has not attach to any canvas view";
    return true;
  }
  KRYPTON_LOGI("Canvas element with unique_id: ")
      << unique_id_ << " detach from canvas view with name: " << canvas_id_;
  if (resource_provider_) {
    KRYPTON_LOGI("Handle resource provider with unique_id: ")
        << unique_id_ << " ,reset resource provider and raster with canvas id: "
        << canvas_id_;
    resource_provider_->DetachFromOnscreenCanvas();
  }
  CancelListenPlatformViewEvents();
  canvas_id_.clear();
  // Detach from canvas view will delete surface client from raster, so don't
  // need update the surface client's priority, just reset the element's
  raster_priority_ = unique_id_;
  return true;
}

}  // namespace canvas
}  // namespace lynx
