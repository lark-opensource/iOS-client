// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_CANVAS_APP_H_
#define CANVAS_CANVAS_APP_H_

#include <mutex>

#include "base/base_export.h"
#include "canvas/canvas_options.h"
#include "canvas/platform/resource_loader.h"
#include "canvas/surface_registry.h"
#include "glue/canvas_runtime.h"
#include "glue/canvas_runtime_observer.h"
#include "jsbridge/bindings/canvas/canvas_module.h"
#include "shell/lynx_actor.h"

#ifdef ENABLE_LYNX_CANVAS_SKIA
#include "canvas/2d/canvas_resource_provider_2d.h"
#include "canvas/text/font_cache.h"
#endif

#ifndef KRYPTON_ERROR_CHECK_IF_NEED
#define KRYPTON_ERROR_CHECK_IF_NEED \
  if (UNLIKELY(!canvas_app_->GetCanvasOptions()->skip_error_check))
#endif

namespace lynx {
namespace canvas {
class CanvasResourceProvider;
class Surface;
class CanvasView;
class GLContext;
class CanvasElement;
class FontCollection;
class CanvasUIProxy;
class PlatformViewObserver;
/**
 * CanvasApp runs on JS Thread
 */

class AppShowStatusObserver {
 public:
  virtual ~AppShowStatusObserver() = default;
  virtual void OnAppEnterForeground() = 0;
  virtual void OnAppEnterBackground() = 0;
};

class CanvasApp : public std::enable_shared_from_this<CanvasApp> {
 public:
  CanvasApp();
  virtual ~CanvasApp();

  std::shared_ptr<shell::LynxActor<CanvasRuntime>> runtime_actor() {
    DCHECK(runtime_actor_);
    return runtime_actor_;
  }

  std::shared_ptr<shell::LynxActor<SurfaceRegistry>> surface_registry_actor() {
    return surface_registry_actor_;
  }

  fml::RefPtr<fml::TaskRunner> runtime_task_runner() {
    DCHECK(runtime_task_runner_);
    return runtime_task_runner_;
  }

  fml::RefPtr<fml::TaskRunner> gpu_task_runner() {
    DCHECK(gpu_task_runner_);
    return gpu_task_runner_;
  }

  int64_t GetNativeHandler() { return reinterpret_cast<int64_t>(this); }

  void SetResourceLoader(std::unique_ptr<ResourceLoader> resource_loader);

  void SetDevicePixelRatio(float ratio) { pixel_ratio_ = ratio; };

  float GetDevicePixelRatio() { return pixel_ratio_; }

  ResourceLoader* resource_loader() const { return resource_loader_.get(); }

  void OnRuntimeAttach(piper::NapiEnvironment* env);
  void OnRuntimeDetach();
  void OnAppEnterForeground();
  void OnAppEnterBackground();

  void SetRuntimeActor(void* actor_native_ptr) {
    runtime_actor_ =
        *reinterpret_cast<std::shared_ptr<shell::LynxActor<CanvasRuntime>>*>(
            actor_native_ptr);
  }

  void SetRuntimeTaskRunner(void* task_runner_native_ptr) {
    runtime_task_runner_ = *reinterpret_cast<fml::RefPtr<fml::TaskRunner>*>(
        task_runner_native_ptr);
  }

  void SetGPUTaskRunner(void* task_runner_native_ptr) {
    gpu_task_runner_ = *reinterpret_cast<fml::RefPtr<fml::TaskRunner>*>(
        task_runner_native_ptr);
    PostSetGPUTaskRunner();
  }

  void UpdateCanvasOptions(Napi::Object js_options) {
    options_.Update(js_options);
  }
  CanvasOptions* GetCanvasOptions() { return &options_; }

  CanvasUIProxy* GetUIProxy() { return canvas_ui_proxy_.get(); }
  PlatformViewObserver* platform_view_observer() {
    return platform_view_observer_.get();
  }

  virtual void* GetHostImpl() { return nullptr; }

  // font
  FontCollection* GetFontCollection() const;
  // AppShowStatusObserver
  BASE_EXPORT void RegisterAppShowStatusObserver(
      const std::weak_ptr<AppShowStatusObserver> observer);

 private:
  void PostSetGPUTaskRunner();

 protected:
  std::shared_ptr<shell::LynxActor<CanvasRuntime>> runtime_actor_;

 private:
  std::shared_ptr<shell::LynxActor<SurfaceRegistry>> surface_registry_actor_;
  std::unique_ptr<ResourceLoader> resource_loader_{nullptr};

  fml::RefPtr<fml::TaskRunner> runtime_task_runner_;
  fml::RefPtr<fml::TaskRunner> gpu_task_runner_;
  CanvasOptions options_;
  std::unique_ptr<PlatformViewObserver> platform_view_observer_;
  mutable std::unique_ptr<FontCollection> font_collection_;
  std::vector<std::weak_ptr<AppShowStatusObserver>>
      app_show_status_observer_vec_;
  // A proxy used to sync surface info in ui thread to avoid lynx.createCanvas
  // return null. it's a polyfill for helium lynx.createCanvas, and will be
  // removed after most projects use async api to create canvas
  // TODO @dupengcheng
  std::unique_ptr<CanvasUIProxy> canvas_ui_proxy_;
  float pixel_ratio_ = 1.0;
#ifdef ENABLE_LYNX_CANVAS_SKIA
  std::unique_ptr<FontCache> font_cache_;
#endif
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_CANVAS_APP_H_
