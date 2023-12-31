// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/canvas_ui_proxy.h"

#include <thread>

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
constexpr static uint32_t kMaxRetryTime = 5;
void CanvasUIProxy::SetSurfaceAbstract(uintptr_t surface_key,
                                       const std::string& id, uint32_t width,
                                       uint32_t height) {
  std::lock_guard<std::mutex> guard(mutex_);
  auto it = std::find_if(surface_collector_.begin(), surface_collector_.end(),
                         [surface_key_ = surface_key](auto& item) {
                           return item.surface_key == surface_key_;
                         });
  if (it == surface_collector_.end()) {
    surface_collector_.push_back({surface_key, width, height, id});
  }
}

void CanvasUIProxy::UpdateSurfaceAbstract(uintptr_t surface_key, uint32_t width,
                                          uint32_t height) {
  std::lock_guard<std::mutex> guard(mutex_);
  auto it = std::find_if(surface_collector_.begin(), surface_collector_.end(),
                         [surface_key_ = surface_key](auto& item) {
                           return item.surface_key == surface_key_;
                         });
  if (it != surface_collector_.end()) {
    it->height = height;
    it->width = width;
  }
}

void CanvasUIProxy::DeleteSurfaceAbstract(uintptr_t surface_key) {
  std::lock_guard<std::mutex> guard(mutex_);
  auto it = std::find_if(surface_collector_.begin(), surface_collector_.end(),
                         [surface_key_ = surface_key](auto& item) {
                           return item.surface_key == surface_key_;
                         });
  if (it != surface_collector_.end()) {
    surface_collector_.erase(it);
  }
}

std::optional<SurfaceAbstract> CanvasUIProxy::GetFirstSurfaceAbstractById(
    const std::string& id) {
  std::lock_guard<std::mutex> guard(mutex_);
  auto it = std::find_if(surface_collector_.begin(), surface_collector_.end(),
                         [id_ = id](auto& item) { return item.id == id_; });

  if (it == surface_collector_.end()) {
    return std::optional<SurfaceAbstract>();
  } else {
    return *it;
  }
}

// call in js thread
// wait for canvas surface created
// logic from Android/LynxHelium/src/main/java/com/he/lynx/HeliumApp.java file
std::optional<SurfaceAbstract> CanvasUIProxy::GetFirstSurfaceAbstractByIdSync(
    const std::string& id) {
  // wait for canvas surface created
  for (int i = 0; i < kMaxRetryTime; ++i) {
    auto info = GetFirstSurfaceAbstractById(id);
    if (info.has_value()) {
      return *info;
    }
    KRYPTON_LOGI("wait for canvas surface created with loop: ") << i;
    std::this_thread::sleep_for(std::chrono::milliseconds(16));
  }
  return std::optional<SurfaceAbstract>();
}
}  // namespace canvas
}  // namespace lynx
