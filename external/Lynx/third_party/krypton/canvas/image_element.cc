// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/image_element.h"

#include "canvas/background_lock.h"
#include "canvas/base/log.h"
#include "canvas/canvas_app.h"
#include "canvas/gpu/gl/scoped_gl_reset_restore.h"
#include "canvas/gpu/gl_context.h"
#include "canvas/image_element_texture_source.h"
#include "canvas/util/texture_util.h"
#include "jsbridge/bindings/canvas/canvas_module.h"
#include "jsbridge/napi/callback_helper.h"
#include "third_party/fml/make_copyable.h"

#ifdef ENABLE_RENDERKIT_CANVAS
#include "canvas/renderkit/canvas_app_renderkit.h"
#endif

#if OS_WIN
#undef LoadBitmap
#endif

#define TRUNCATE_PATH(path) (path.substr(0, 100))

using lynx::piper::CallbackHelper;

namespace lynx {
namespace canvas {

#ifdef LYNX_KRYPTON_TEST
namespace test {
extern void AccumulateJSTime(const std::function<void()>& task);
}
#endif

namespace {
std::string GenerateUniqueId() {
  static uint32_t s_unique_id = 0;
  return std::to_string(++s_unique_id);
}
constexpr char collector_name[] = "kryptonImageCollector";
}  // namespace

ImageElement::ImageElement() : id_(GenerateUniqueId()) {
  KRYPTON_CONSTRUCTOR_LOG(ImageElement);
}

ImageElement::~ImageElement() {
  if (texture_source_) {
    texture_source_->Act([](auto& impl) {
#ifdef OS_IOS
      BackgroundLock::Instance().WaitForForeground();
#endif
      impl.reset();
    });
  }

  KRYPTON_DESTRUCTOR_LOG(ImageElement);
}

void ImageElement::SetSrc(const std::string& src) {
  KRYPTON_LOGI("ImageElement setSrc ")
      << this << (" with ") << TRUNCATE_PATH(src);
  src_ = src;
  InternalLoad(src);
}

void ImageElement::InternalLoad(const std::string& src) {
  load_complete_ = false;
  if (src.empty() || src == "undefined") {
    DoReleaseMemUsed();
    return;
  }

  HoldObject();
  DCHECK(canvas_app_);

  if (!instance_guard_) {
    instance_guard_ = InstanceGuard<ImageElement>::CreateSharedGuard(this);
  }
  auto weak_guard = std::weak_ptr<InstanceGuard<ImageElement>>(instance_guard_);

#ifdef ENABLE_RENDERKIT_CANVAS
  reinterpret_cast<CanvasAppRenderkit*>(canvas_app_.get())
      ->LoadImage(src_, weak_guard);
  return;
#endif

  auto runtime_task_runner = canvas_app_->runtime_task_runner();
  auto callback = [weak_guard,
                   runtime_task_runner](std::unique_ptr<Bitmap> bitmap) {
    // make sure run on JS Thread
    runtime_task_runner->PostTask(fml::MakeCopyable(
        [weak_guard = weak_guard, bitmap = std::move(bitmap)]() mutable {
          auto shared_guard = weak_guard.lock();
          if (!shared_guard) {
            KRYPTON_LOGW("Image load")
                << " platform callback when image_element has been released.";
            return;
          }

          ImageElement* self = shared_guard->Get();
          if (!bitmap || !bitmap->IsValidate()) {
            self->TriggerOnError();
            return;
          }

          self->load_complete_ = true;
          self->bitmap_ = std::shared_ptr<Bitmap>(std::move(bitmap));
          auto image_element_texture_source =
              std::make_unique<ImageElementTextureSource>(self->bitmap_);
          if (self->texture_source_) {
            self->texture_source_->Act([](auto& impl) {
#ifdef OS_IOS
              BackgroundLock::Instance().WaitForForeground();
#endif
              impl.reset();
            });
          }
          self->texture_source_ =
              std::make_shared<shell::LynxActor<TextureSource>>(
                  std::move(image_element_texture_source),
                  self->canvas_app_->gpu_task_runner());
          self->TriggerOnLoad();
        }));
  };

  canvas_app_->resource_loader()->LoadBitmap(src, callback);
}

void ImageElement::OnLoadImageFromRenderkit(uint32_t image_id) {
  // make sure run on JS Thread
  // id == 0 means load image failed in Renderkit
  if (image_id == 0) {
    load_complete_ = false;
    TriggerOnError();
    return;
  }

  SetImageIDForRenderkit(image_id);
  load_complete_ = true;
  TriggerOnLoad();
}

void ImageElement::TriggerOnLoad() {
  KRYPTON_LOGI("TriggerOnLoad with src ") << TRUNCATE_PATH(src_);
  Napi::HandleScope hscope(Env());
  Napi::ContextScope scope(Env());

#ifdef LYNX_KRYPTON_TEST
  test::AccumulateJSTime(
      [&] { TriggerEventListeners("load", Env().Undefined()); });
#else
  TriggerEventListeners("load", Env().Undefined());
#endif
  ReleaseObject();
}

void ImageElement::TriggerOnError() {
  KRYPTON_LOGI("TriggerOnError with src ") << TRUNCATE_PATH(src_);
  Napi::HandleScope hscope(Env());
  Napi::ContextScope scope(Env());
  TriggerEventListeners("error", Env().Undefined());
  ReleaseObject();
}

uint32_t ImageElement::GetWidth() {
  return !GetBitmap() ? 0 : bitmap_->Width();
}

uint32_t ImageElement::GetHeight() {
  return !GetBitmap() ? 0 : bitmap_->Height();
}

std::shared_ptr<Bitmap> ImageElement::GetBitmap() {
  ReloadURLIfNeed();
  return bitmap_;
}

#ifndef ENABLE_RENDERKIT_CANVAS
std::shared_ptr<shell::LynxActor<TextureSource>>
ImageElement::GetTextureSource() {
  ReloadURLIfNeed();
  return texture_source_;
}
#endif

void ImageElement::ReleaseUsedMemIfNeed() {
  if (!canvas_app_->GetCanvasOptions()->enable_auto_release_image_mem) {
    return;
  }

  std::string data_url_prefix("data:");
  auto res = std::mismatch(data_url_prefix.begin(), data_url_prefix.end(),
                           src_.begin());
  if (res.first == data_url_prefix.end()) {
    DoReleaseMemUsed();
  }
}

void ImageElement::ReloadURLIfNeed() {
  if (bitmap_ || src_.empty() || src_ == "undefined") {
    return;
  }

  if (!load_complete_) {
    return;
  }

  if (!canvas_app_->GetCanvasOptions()->enable_auto_release_image_mem) {
    return;
  }

  bitmap_ = canvas_app_->resource_loader()->DecodeDataURLSync(src_);
  auto image_element_texture_source =
      std::make_unique<ImageElementTextureSource>(bitmap_);
  texture_source_ = std::make_shared<shell::LynxActor<TextureSource>>(
      std::move(image_element_texture_source), canvas_app_->gpu_task_runner());
}

void ImageElement::DoReleaseMemUsed() {
  if (bitmap_) {
    bitmap_.reset();
  }

  if (texture_source_) {
    texture_source_->Act([](auto& impl) {
#ifdef OS_IOS
      BackgroundLock::Instance().WaitForForeground();
#endif
      impl.reset();
    });
    texture_source_.reset();
  }
}

void ImageElement::OnWrapped() {
  canvas_app_ = CanvasModule::From(Env())->GetCanvasApp();
}

void ImageElement::HoldObject() {
  Napi::Env env = Env();
  if (!env.Global().Has(collector_name)) {
    env.Global()[collector_name] = Napi::Object::New(env);
  }
  Napi::Value collector = env.Global()[collector_name];
  Napi::Object collector_obj = collector.As<Napi::Object>();
  collector_obj[id_.c_str()] = JsObject();
}

void ImageElement::ReleaseObject() {
  Napi::Env env = Env();
  if (!env.Global().Has(collector_name)) {
    return;
  }
  Napi::Value collector = env.Global()[collector_name];
  Napi::Object collector_obj = collector.As<Napi::Object>();
  if (collector_obj.Has(id_.c_str())) {
    collector_obj.Delete(id_.c_str());
  }
}

}  // namespace canvas
}  // namespace lynx
