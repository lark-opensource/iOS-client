// Copyright 2023 The Lynx Authors. All rights reserved.

#include "canvas/surface_registry.h"

#include "canvas/base/log.h"
#include "canvas/gpu/gl_context.h"
#include "canvas/surface_client.h"

namespace lynx {
namespace canvas {

SurfaceRegistry::SurfaceRegistry(fml::RefPtr<fml::TaskRunner> task_runner,
                                 uintptr_t canvas_app_ptr)
    : gpu_task_runner_(task_runner), canvas_app_ptr_(canvas_app_ptr) {
  KRYPTON_CONSTRUCTOR_LOG(SurfaceRegistry);
}

SurfaceRegistry::SurfaceRegistry(fml::RefPtr<fml::TaskRunner> gpuTaskRunner,
                                 uintptr_t canvas_app_ptr,
                                 std::unique_ptr<GLContext> context)
    : gpu_task_runner_(gpuTaskRunner),
      context_(std::move(context)),
      canvas_app_ptr_(canvas_app_ptr) {}

void SurfaceRegistry::OnSurfaceCreated(const uintptr_t &surface_key,
                                       const std::string &id,
                                       std::unique_ptr<Surface> surface,
                                       bool is_additional) {
  DCHECK(CheckOnGPUThread());
  auto it = std::find_if(
      surface_vec_.cbegin(), surface_vec_.cend(),
      [surface_key](auto &item) { return item->surface_key == surface_key; });

  if (it == surface_vec_.cend()) {
    if (InitSurface(surface.get())) {
      KRYPTON_LOGI("[OnSurfaceCreated] ")
          << "with id: " << id << " ,with surface_key: " << surface_key
          << " ,is additional: " << is_additional << "this: " << this
          << " canvas_app: " << canvas_app_ptr_;
      ISize surface_size = {surface->Width(), surface->Height()};
      auto surface_info = std::make_unique<CanvasSurfaceInfo>(CanvasSurfaceInfo{
          surface_key, id, std::move(surface), surface_size, is_additional});
      AssignSurfaceToClient(surface_info.get());
      surface_vec_.emplace_back(std::move(surface_info));
    } else {
      KRYPTON_LOGI("[OnSurfaceCreated] Surface init failed ")
          << "with surface_key: " << surface_key << " id: " << id
          << "this: " << this << " canvas_app: " << canvas_app_ptr_;
      StoreUninitializedSurface(surface_key, id, std::move(surface));
    }
  } else {
    KRYPTON_LOGI("[OnSurfaceCreated] Same surface has created ")
        << "with surface_key: " << surface_key << " id: " << id
        << "this: " << this << " canvas_app: " << canvas_app_ptr_;
  }
}

void SurfaceRegistry::OnSurfaceDestroyed(const uintptr_t &surface_key) {
  DCHECK(CheckOnGPUThread());
  auto it = std::find_if(
      surface_vec_.cbegin(), surface_vec_.cend(),
      [surface_key](auto &item) { return item->surface_key == surface_key; });
  if (it != surface_vec_.cend()) {
    auto surface_id = (*it)->id;
    KRYPTON_LOGI(
        "[OnSurfaceDestroyed] DeRegister surface from onscreen vector success "
        "with surface_key: ")
        << surface_key << " id: " << surface_id << " this: " << this
        << " canvas_app: " << canvas_app_ptr_;
    auto *client = (*it)->client;
    if (client) {
      client->OnSurfaceRemove((*it).get());
    }
    surface_vec_.erase(it);
  } else {
    KRYPTON_LOGI(
        "[OnSurfaceDestroyed] DeRegister surface from onscreen vector failed, "
        "cannot find surface with surface_key: ")
        << surface_key << " : this" << this
        << " canvas_app: " << canvas_app_ptr_;
    RemoveUninitializedSurface(surface_key);
  }
}

void SurfaceRegistry::OnSurfaceChanged(const uintptr_t &surface_key,
                                       int32_t width, int32_t height) {
  DCHECK(CheckOnGPUThread());
  auto it = std::find_if(
      surface_vec_.cbegin(), surface_vec_.cend(),
      [surface_key](auto &info) { return info->surface_key == surface_key; });
  if (it != surface_vec_.cend()) {
    if ((*it)->size.width != width || (*it)->size.height != height) {
      KRYPTON_LOGI("[OnSurfaceChanged] Surface with surface_key: ")
          << surface_key << " id: " << (*it)->id << " with new size "
          << " width: " << width << " height: " << height << " :this " << this
          << " canvas_app: " << canvas_app_ptr_;
      ResizeSurface((*it)->surface.get(), width, height);
      (*it)->size = {(*it)->surface->Width(), (*it)->surface->Height()};
      return;
    }
  } else {
    KRYPTON_LOGI(
        "[OnSurfaceChanged] Surface resize failed because surface with "
        "surface_key: ")
        << surface_key << " not existed!"
        << " this: " << this;
    // retry init surface when surface size changed
    RetryInitSurface(surface_key, width, height);
  }
}

void SurfaceRegistry::ResizeSurface(Surface *surface, int32_t new_width,
                                    int32_t new_height) {
  DCHECK(CheckOnGPUThread());
  GetContext()->MakeCurrent(nullptr);
  surface->Resize(new_width, new_height);
}

void SurfaceRegistry::RegisterSurfaceClient(SurfaceClient *client) {
  auto &canvas_name = client->surface_name();
  auto &client_vec = surface_clients_[canvas_name];
  for (const auto *it : client_vec) {
    if (it->GetClientId() == client->GetClientId()) {
      KRYPTON_LOGI(
          "[RegisterSurfaceClient] register surface client with same id: ")
          << client->GetClientId() << " this: " << this
          << " canvas_app: " << canvas_app_ptr_;
      return;
    }
  }
  ContendForSurfaces(client);
  client_vec.push_back(client);
  KRYPTON_LOGI(
      "[RegisterSurfaceClient] Register SurfaceClient success with "
      "canvas_name: ")
      << canvas_name << " client_id:" << client->GetClientId()
      << " client_vec size: " << client_vec.size() << " this: " << this
      << " canvas_app: " << canvas_app_ptr_;
}

void SurfaceRegistry::DeregisterSurfaceClient(SurfaceClient *client) {
  auto canvas_name = client->surface_name();
  auto &client_vec = surface_clients_[canvas_name];
  if (!client_vec.empty()) {
    for (auto it = client_vec.cbegin(); it != client_vec.cend();) {
      if ((*it)->GetClientId() == client->GetClientId()) {
        KRYPTON_LOGI(
            "[DeregisterSurfaceClient] DeRegister SurfaceClient success with "
            "canvas_name: ")
            << canvas_name << " client_id:" << client->GetClientId()
            << " this: " << this << " canvas_app: " << canvas_app_ptr_;
        it = client_vec.erase(it);
      } else {
        ++it;
      }
    }
  }
  ReassignSurfaceClient(client);
}

void SurfaceRegistry::AssignSurfaceToClient(CanvasSurfaceInfo *surface) {
  auto canvas_name = surface->id;
  auto *selected_client = GetSurfaceClientWithHighestPriority(canvas_name);
  if (selected_client) {
    KRYPTON_LOGI("[AssignSurfaceToClient] Allocate surface with surface id: ")
        << surface->id << " surface key: " << surface->surface_key
        << " to SurfaceClient with client_id: "
        << selected_client->GetClientId()
        << " and unique_id: " << selected_client->unique_id()
        << " this: " << this << " canvas_app: " << canvas_app_ptr_;
    selected_client->OnSurfaceReady(surface);
    surface->client = selected_client;
  } else {
    KRYPTON_LOGI("[AssignSurfaceToClient] Client with surface id: ")
        << surface->id << " has not registered."
        << " this: " << this;
  }
}

void SurfaceRegistry::ContendForSurfaces(SurfaceClient *new_client) {
  for (auto &surface_info : surface_vec_) {
    if (surface_info->id == new_client->surface_name()) {
      if (surface_info->client && surface_info->client != new_client) {
        if (new_client->GetPriority() >= surface_info->client->GetPriority()) {
          KRYPTON_LOGI(
              "[ContendForSurfaces] SurfaceClient with new_client id: ")
              << new_client->GetClientId()
              << " contend for surface from old client: "
              << surface_info->client->GetClientId()
              << " with surface: " << surface_info->surface_key
              << " this: " << this << " canvas_app: " << canvas_app_ptr_;
          surface_info->client->OnSurfaceRemove(surface_info.get());
          surface_info->client = new_client;
          new_client->OnSurfaceReady(surface_info.get());
        }
      } else {
        KRYPTON_LOGI("[ContendForSurfaces] SurfaceClient with new_client id: ")
            << new_client->GetClientId()
            << " occupy surface as first client with surface key: "
            << surface_info->surface_key << " this: " << this
            << " canvas_app: " << canvas_app_ptr_;
        surface_info->client = new_client;
        new_client->OnSurfaceReady(surface_info.get());
      }
    }
  }
}

// NOTICE: In general, resource provider need to setNeedDraw after this
// surface reassigned to other raster, but all the assign operations
// are happened at gpu thread while the rasters are managed in js thread.
// It only influence the first frame of the reassigned raster
void SurfaceRegistry::ReassignSurfaceClient(SurfaceClient *old_client) {
  auto canvas_name = old_client->surface_name();
  auto *selected_client = GetSurfaceClientWithHighestPriority(canvas_name);
  for (const auto &surface : surface_vec_) {
    if (surface->client == old_client) {
      surface->client = selected_client;
      if (selected_client) {
        KRYPTON_LOGI("[ReassignSurfaceClient] Surface with surface id: ")
            << surface->id << " surface key: " << surface->surface_key
            << " transfer from old surface client: "
            << old_client->GetClientId()
            << " client unique_id: " << old_client->unique_id()
            << " to surface client: " << selected_client->GetClientId()
            << " client unique_id: " << selected_client->unique_id()
            << " this: " << this << " canvas_app: " << canvas_app_ptr_;
        selected_client->OnSurfaceReady(surface.get());
      }
    }
  }
}

bool SurfaceRegistry::InitSurface(Surface *surface) {
  DCHECK(CheckOnGPUThread());
  auto *context = GetContext();
  if (context->MakeCurrent(nullptr)) {
    KRYPTON_LOGI("[InitSurface] InitSurface with surface: ")
        << surface << " this: " << this << " canvas_app: " << canvas_app_ptr_;
    surface->Init();
    return true;
  }
  KRYPTON_LOGI("[InitSurface] InitSurface failed with surface: ")
      << surface << " this: " << this << " canvas_app: " << canvas_app_ptr_;
  return false;
}

GLContext *SurfaceRegistry::GetContext() {
  DCHECK(CheckOnGPUThread());
  if (!context_) {
    context_ = GLContext::CreateVirtual();
    context_->Init();
  }
  return context_.get();
}

bool SurfaceRegistry::CheckOnGPUThread() const {
  return gpu_task_runner_->RunsTasksOnCurrentThread();
}

SurfaceClient *SurfaceRegistry::GetSurfaceClientWithHighestPriority(
    const std::string &canvas_name) {
  auto &client_vec = surface_clients_[canvas_name];
  SurfaceClient *selected_client = nullptr;
  if (!client_vec.empty()) {
    selected_client = client_vec[0];
    for (const auto &client : client_vec) {
      if (selected_client->GetPriority() < client->GetPriority()) {
        selected_client = client;
      }
    }
  }
  return selected_client;
}

void SurfaceRegistry::StoreUninitializedSurface(
    const uintptr_t &surface_key, const std::string &id,
    std::unique_ptr<Surface> surface) {
  auto it = std::find_if(uninitialized_surface_vec_.cbegin(),
                         uninitialized_surface_vec_.cend(),
                         [surface_key_ = surface_key](auto &item) {
                           return item->surface_key == surface_key_;
                         });
  if (it != uninitialized_surface_vec_.cend()) {
    KRYPTON_LOGI(
        "[StoreUninitializedSurface] Store uninitialized surface with "
        "surface_key: ")
        << surface_key << " surface name: " << id << " this: " << this
        << " canvas_app: " << canvas_app_ptr_;
    ;
    auto surface_info = std::make_unique<CanvasSurfaceInfo>(
        CanvasSurfaceInfo{surface_key, id, std::move(surface), {0, 0}, false});
    uninitialized_surface_vec_.emplace_back(std::move(surface_info));
  } else {
    KRYPTON_LOGI(
        "[StoreUninitializedSurface] Uninitialized surface with surface_key: ")
        << surface_key << " surface name: " << id << "has been stored!"
        << " this: " << this << " canvas_app: " << canvas_app_ptr_;
  }
}

void SurfaceRegistry::RetryInitSurface(const uintptr_t &surface_key,
                                       int32_t width, int32_t height) {
  auto it = std::find_if(uninitialized_surface_vec_.begin(),
                         uninitialized_surface_vec_.end(),
                         [surface_key_ = surface_key](auto &item) {
                           return item->surface_key == surface_key_;
                         });
  if (it != uninitialized_surface_vec_.end()) {
    KRYPTON_LOGI("[RetryInitSurface] Retry init surface with surface_key: ")
        << surface_key;
    auto *surface = (*it)->surface.get();
    if (InitSurface(surface)) {
      KRYPTON_LOGI("[RetryInitSurface] Surface with surface_key: ")
          << surface_key << "init success!!"
          << " this: " << this << " canvas_app: " << canvas_app_ptr_;
      (*it)->size = {surface->Width(), surface->Height()};
      // Retry success, need move this surface to on screen vector and assign to
      // surface client.
      AssignSurfaceToClient((*it).get());
      surface_vec_.emplace_back(std::move(*it));
      // remove from uninitialized surface vector
      uninitialized_surface_vec_.erase(it);
    } else {
      KRYPTON_LOGI("[RetryInitSurface] Retry init surface with surface_key: ")
          << surface_key << "failed."
          << " this: " << this << " canvas_app: " << canvas_app_ptr_;
    }
  }
}

void SurfaceRegistry::RemoveUninitializedSurface(const uintptr_t &surface_key) {
  auto it = std::find_if(uninitialized_surface_vec_.cbegin(),
                         uninitialized_surface_vec_.cend(),
                         [surface_key_ = surface_key](auto &item) {
                           return item->surface_key == surface_key_;
                         });
  if (it != uninitialized_surface_vec_.cend()) {
    KRYPTON_LOGI(
        "[RemoveUninitializedSurface] Uninitialized surface with surface_key: ")
        << surface_key << "destroyed!!"
        << " this: " << this << " canvas_app: " << canvas_app_ptr_;
    uninitialized_surface_vec_.erase(it);
  }
}

}  // namespace canvas
}  // namespace lynx
