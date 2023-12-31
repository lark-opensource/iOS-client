// Copyright 2023 The Lynx Authors. All rights reserved.

#include "canvas/surface_client.h"

namespace lynx {
namespace canvas {

namespace {
int32_t GenerateUniqueId() {
  static int32_t s_unique_id = 0;
  return ++s_unique_id;
}
}  // namespace

SurfaceClient::SurfaceClient(
    std::shared_ptr<shell::LynxActor<SurfaceRegistry>> actor,
    const std::string& surface_name, int32_t unique_id)
    : surface_name_(surface_name),
      unique_id_(unique_id),
      priority_(unique_id),
      surface_actor_(actor) {
  client_id = GenerateUniqueId();
  KRYPTON_CONSTRUCTOR_LOG(SurfaceClient)
      << " with surface id: " << surface_name_
      << " with client id :" << client_id;
}

SurfaceClient::SurfaceClient(
    std::shared_ptr<shell::LynxActor<SurfaceRegistry>> actor,
    const std::string& surface_name, int32_t unique_id,
    int32_t initial_priority)
    : surface_name_(surface_name),
      unique_id_(unique_id),
      priority_(initial_priority),
      surface_actor_(actor) {
  client_id = GenerateUniqueId();
  KRYPTON_CONSTRUCTOR_LOG(SurfaceClient)
      << " with surface id: " << surface_name_
      << " with client id :" << client_id;
}

SurfaceClient::~SurfaceClient() {
  if (!surface_name_.empty() && surface_actor_) {
    surface_actor_->ActSync(
        [this](auto& impl) { impl->DeregisterSurfaceClient(this); });
  }
  KRYPTON_DESTRUCTOR_LOG(SurfaceClient);
}

void SurfaceClient::Init() {
  if (!surface_name_.empty() && surface_actor_) {
    // surface observer's constructor may called in js thread
    // need to post to gpu thread to register to surface registry
    surface_actor_->ActSync(
        [this](auto& impl) { impl->RegisterSurfaceClient(this); });
  }
}

int32_t SurfaceClient::GetPriority() { return priority_; }

void SurfaceClient::UpdatePriority(int32_t new_priority,
                                   bool need_reassign_surface) {
  if (new_priority == priority_) {
    return;
  }
  priority_ = new_priority;
  if (need_reassign_surface) {
    surface_actor_->ActSync(
        [this](auto& impl) { impl->ContendForSurfaces(this); });
  }
}

void SurfaceClient::OnSurfaceRemove(CanvasSurfaceInfo* surfaceInfo) {
  if (!surface_vec_.empty()) {
    auto surface_key = surfaceInfo->surface_key;
    for (auto it = surface_vec_.cbegin(); it != surface_vec_.cend();) {
      if ((*it)->surface_key == surface_key) {
        it = surface_vec_.erase(it);
      } else {
        ++it;
      }
    }
  }
}

}  // namespace canvas
}  // namespace lynx
