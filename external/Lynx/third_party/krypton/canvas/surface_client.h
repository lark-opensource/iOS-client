// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef CANVAS_SURFACE_CLIENT_H_
#define CANVAS_SURFACE_CLIENT_H_

#include <vector>

#include "canvas/surface_registry.h"

namespace lynx {
namespace canvas {

class SurfaceClient {
 public:
  SurfaceClient(std::shared_ptr<shell::LynxActor<SurfaceRegistry>> actor,
                const std::string &surface_id, int32_t unique_id);
  SurfaceClient(std::shared_ptr<shell::LynxActor<SurfaceRegistry>> actor,
                const std::string &surface_id, int32_t unique_id,
                int32_t initial_priority);

  ~SurfaceClient();

  SurfaceClient(const SurfaceClient &) = delete;

  SurfaceClient &operator=(const SurfaceClient &) = delete;

  void Init();

  int32_t GetPriority();

  void UpdatePriority(int32_t new_priority, bool need_reassign_surface);

  int32_t GetClientId() const { return client_id; }

  void OnSurfaceReady(CanvasSurfaceInfo *surface) {
    surface_vec_.emplace_back(surface);
  }

  void OnSurfaceRemove(CanvasSurfaceInfo *surfaceInfo);

  std::vector<CanvasSurfaceInfo *> &surface_vector() { return surface_vec_; }

  int32_t unique_id() { return unique_id_; }

  const std::string &surface_name() { return surface_name_; }

 private:
  std::vector<CanvasSurfaceInfo *> surface_vec_;
  const std::string surface_name_;
  // unique_id from canvas element
  int32_t unique_id_;
  int32_t priority_;
  std::shared_ptr<shell::LynxActor<SurfaceRegistry>> surface_actor_;
  int32_t client_id;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_SURFACE_CLIENT_H_
