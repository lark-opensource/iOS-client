// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef CANVAS_SURFACE_REGISTRY_H_
#define CANVAS_SURFACE_REGISTRY_H_

#include <unordered_map>
#include <vector>

#include "canvas/base/size.h"
#include "canvas/canvas_resource_provider.h"
#include "canvas/gpu/gl_context.h"
#include "canvas/instance_guard.h"
#include "canvas/surface/surface.h"

namespace lynx {
namespace canvas {

class SurfaceClient;

struct CanvasSurfaceInfo {
  uintptr_t surface_key;
  std::string id;
  std::unique_ptr<Surface> surface;
  ISize size;
  bool is_additional = false;
  SurfaceClient *client = nullptr;
};

class SurfaceRegistry {
 public:
  SurfaceRegistry(fml::RefPtr<fml::TaskRunner> gpu_task_runner,
                  uintptr_t canvas_app_ptr);

  // for test
  SurfaceRegistry(fml::RefPtr<fml::TaskRunner> gpu_task_runner,
                  uintptr_t canvas_app_ptr, std::unique_ptr<GLContext> context);

  void OnSurfaceCreated(const uintptr_t &surface_key, const std::string &id,
                        std::unique_ptr<Surface> surface,
                        bool is_additional = false);

  void OnSurfaceDestroyed(const uintptr_t &surface_key);

  void OnSurfaceChanged(const uintptr_t &surface_key, int32_t width,
                        int32_t height);

  void RegisterSurfaceClient(SurfaceClient *client);

  void DeregisterSurfaceClient(SurfaceClient *client);

  void ContendForSurfaces(SurfaceClient *new_client);

  const std::unordered_map<std::string, std::vector<SurfaceClient *>>
      &surface_clients() {
    return surface_clients_;
  }
  const std::vector<std::unique_ptr<CanvasSurfaceInfo>> &surface_vector() {
    return surface_vec_;
  }

 private:
  GLContext *GetContext();

  bool InitSurface(Surface *surface);

  void ResizeSurface(Surface *surface, int32_t new_width, int32_t new_height);

  bool CheckOnGPUThread() const;

  void AssignSurfaceToClient(CanvasSurfaceInfo *surface);

  void ReassignSurfaceClient(SurfaceClient *old_client);

  SurfaceClient *GetSurfaceClientWithHighestPriority(
      const std::string &canvas_name);

  void StoreUninitializedSurface(const uintptr_t &surface_key,
                                 const std::string &id,
                                 std::unique_ptr<Surface> surface);

  void RetryInitSurface(const uintptr_t &surface_key, int32_t width,
                        int32_t height);

  void RemoveUninitializedSurface(const uintptr_t &surface_key);

  const fml::RefPtr<fml::TaskRunner> gpu_task_runner_;
  std::unique_ptr<GLContext> context_;
  std::vector<std::unique_ptr<CanvasSurfaceInfo>> surface_vec_;
  // In some android devices, surface may initialized failed when surface size
  // is set to 0. Need to retry initial the surface when surface size changed.
  std::vector<std::unique_ptr<CanvasSurfaceInfo>> uninitialized_surface_vec_;
  // maybe should use priority queue, but it can not be iterated, so use vector
  // for now.
  std::unordered_map<std::string, std::vector<SurfaceClient *>>
      surface_clients_;
  uintptr_t canvas_app_ptr_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_SURFACE_REGISTRY_H_
