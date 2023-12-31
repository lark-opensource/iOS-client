// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_CANVAS_UI_PROXY_H_
#define CANVAS_CANVAS_UI_PROXY_H_

#include <mutex>
#include <optional>
#include <vector>

namespace lynx {
namespace canvas {
struct SurfaceAbstract {
  uintptr_t surface_key;
  uint32_t width;
  uint32_t height;
  std::string id;
};
// class works in js thread and UI thread
// polyfill for helium canvas create canvas
class CanvasUIProxy {
 public:
  void SetSurfaceAbstract(uintptr_t surface_key, const std::string& id,
                          uint32_t width, uint32_t height);
  std::optional<SurfaceAbstract> GetFirstSurfaceAbstractById(
      const std::string& id);
  std::optional<SurfaceAbstract> GetFirstSurfaceAbstractByIdSync(
      const std::string& id);
  void UpdateSurfaceAbstract(uintptr_t surface_key, uint32_t width,
                             uint32_t height);
  void DeleteSurfaceAbstract(uintptr_t surface_key);

 private:
  std::vector<SurfaceAbstract> surface_collector_;
  std::mutex mutex_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_CANVAS_UI_PROXY_H_
