// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/canvas_app.h"

#include <utility>

#include "canvas/base/log.h"
#include "canvas/canvas_element.h"
#include "canvas/canvas_resource_provider.h"
#include "canvas/canvas_ui_proxy.h"
#include "canvas/canvas_view.h"
#include "canvas/text/font_collection.h"
#include "canvas/text/typeface.h"
#include "canvas/util/string_utils.h"
#include "canvas/webgl/canvas_resource_provider_3d.h"
#include "jsbridge/bindings/canvas/canvas_module.h"

namespace lynx {
namespace canvas {
CanvasApp::CanvasApp()
#ifdef ENABLE_LYNX_CANVAS_SKIA
    : font_cache_(std::make_unique<FontCache>())
#endif
{
  KRYPTON_CONSTRUCTOR_LOG(CanvasApp);
  // keep this to use iostream to initial locale.
  // TODO(luchengxuan) remove this when use common c++ shared with lynx in
  // release 2.2
  canvas_ui_proxy_ = std::make_unique<CanvasUIProxy>();
}

CanvasApp::~CanvasApp() {
  if (runtime_actor_ != nullptr) {
    runtime_actor_->Act([](auto &runtime) { runtime = nullptr; });
  }
  if (surface_registry_actor_ != nullptr) {
    surface_registry_actor_->Act([](auto &runtime) { runtime = nullptr; });
  }
  KRYPTON_DESTRUCTOR_LOG(CanvasApp);
}

void CanvasApp::PostSetGPUTaskRunner() {
  if (!surface_registry_actor_ && gpu_task_runner_) {
    uintptr_t app_ptr = reinterpret_cast<uintptr_t>(this);
    surface_registry_actor_ =
        std::make_shared<shell::LynxActor<SurfaceRegistry>>(
            std::make_unique<SurfaceRegistry>(gpu_task_runner_, app_ptr),
            gpu_task_runner_);
    platform_view_observer_ = std::make_unique<PlatformViewObserver>(
        surface_registry_actor_, app_ptr);
  }
}

void CanvasApp::SetResourceLoader(
    std::unique_ptr<ResourceLoader> resource_loader) {
  resource_loader_ = std::move(resource_loader);
}

void CanvasApp::OnRuntimeAttach(piper::NapiEnvironment *env) {
  if (env) {
    auto canvas_module = new CanvasModule(shared_from_this());
    canvas_module->Install(env->proxy()->Env());
  }
}

void CanvasApp::OnRuntimeDetach() {
  runtime_actor_->Act([](auto &runtime) { runtime = nullptr; });
}

FontCollection *CanvasApp::GetFontCollection() const {
  if (!font_collection_) {
    font_collection_ = std::make_unique<FontCollection>();
  }
  return font_collection_.get();
}

void CanvasApp::RegisterAppShowStatusObserver(
    const std::weak_ptr<AppShowStatusObserver> observer) {
  app_show_status_observer_vec_.emplace_back(observer);
}

void CanvasApp::OnAppEnterForeground() {
  for (const auto &observer : app_show_status_observer_vec_) {
    auto cur_observer = observer.lock();
    if (!cur_observer) return;
    cur_observer->OnAppEnterForeground();
  }
}

void CanvasApp::OnAppEnterBackground() {
  for (const auto &observer : app_show_status_observer_vec_) {
    auto cur_observer = observer.lock();
    if (!cur_observer) return;
    cur_observer->OnAppEnterBackground();
  }
}
}  // namespace canvas
}  // namespace lynx
