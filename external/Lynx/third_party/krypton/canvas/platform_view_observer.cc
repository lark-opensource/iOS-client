// Copyright (c) 2023 The Lynx Authors. All rights reserved.
#include "canvas/platform_view_observer.h"

#include "third_party/fml/make_copyable.h"

namespace lynx {
namespace canvas {
PlatformViewObserver::PlatformViewObserver(
    std::shared_ptr<shell::LynxActor<SurfaceRegistry>> actor,
    uintptr_t canvas_app_ptr)
    : surface_registry_actor_(std::move(actor)),
      canvas_app_ptr_(canvas_app_ptr) {
  KRYPTON_CONSTRUCTOR_LOG(PlatformViewObserver);
}

void PlatformViewObserver::OnSurfaceCreated(std::unique_ptr<Surface> surface,
                                            uintptr_t surface_key,
                                            const std::string &name,
                                            int32_t width, int32_t height) {
  KRYPTON_LOGI("[OnSurfaceCreated] Surface created with name: ")
      << name << " surface_key: " << surface_key << " this: " << this
      << " canvas_app: " << canvas_app_ptr_;
  DCHECK(surface_registry_actor_);

  surface_registry_actor_->Act(fml::MakeCopyable(
      [surface_ = std::move(surface), surface_key_ = surface_key,
       name_ = name](auto &impl) mutable {
        impl->OnSurfaceCreated(surface_key_, name_, std::move(surface_));
      }));
  auto it = listeners_.find(name);
  if (it != listeners_.end()) {
    is_running_callback_ = true;
    const auto &listener_vec = it->second;
    for (const auto &listener_weak : listener_vec) {
      auto listener = listener_weak.lock();
      if (listener &&
          listener->callbacks.surface_created_callback.has_value()) {
        auto callback = listener->callbacks.surface_created_callback;
        (*callback)(surface_key, name, width, height);
      }
    }
    is_running_callback_ = false;
    HandleListenerAfterCallbacksLoop();
  }
}

void PlatformViewObserver::OnSurfaceChanged(const std::string &name,
                                            uintptr_t surface_key,
                                            int32_t new_width,
                                            int32_t new_height) {
  KRYPTON_LOGI("[OnSurfaceChanged] Surface changed with name: ")
      << name << " surface_key: " << surface_key << " new_width: " << new_width
      << " new_height: " << new_height << " this: " << this
      << " canvas_app: " << canvas_app_ptr_;
  DCHECK(surface_registry_actor_);
  surface_registry_actor_->Act(
      fml::MakeCopyable([surface_key_ = surface_key, new_width_ = new_width,
                         new_height_ = new_height](auto &impl) {
        impl->OnSurfaceChanged(surface_key_, new_width_, new_height_);
      }));
  auto it = listeners_.find(name);
  if (it != listeners_.end()) {
    is_running_callback_ = true;
    const auto &listener_vec = it->second;
    for (const auto &listener_weak : listener_vec) {
      auto listener = listener_weak.lock();
      if (listener &&
          listener->callbacks.surface_changed_callback.has_value()) {
        auto callback = listener->callbacks.surface_changed_callback;
        (*callback)(surface_key, new_width, new_height);
      }
    }
    is_running_callback_ = false;
    HandleListenerAfterCallbacksLoop();
  }
}

void PlatformViewObserver::OnSurfaceDestroyed(const std::string &name,
                                              uintptr_t surface_key) {
  KRYPTON_LOGI("[OnSurfaceDestroyed] Surface destroyed with name: ")
      << name << " surface_key: " << surface_key << " this: " << this
      << " canvas_app: " << canvas_app_ptr_;
  DCHECK(surface_registry_actor_);
  surface_registry_actor_->Act(
      fml::MakeCopyable([surface_key_ = surface_key](auto &impl) {
        impl->OnSurfaceDestroyed(surface_key_);
      }));
  auto it = listeners_.find(name);
  if (it != listeners_.end()) {
    is_running_callback_ = true;
    const auto &listener_vec = it->second;
    for (const auto &listener_weak : listener_vec) {
      auto listener = listener_weak.lock();
      if (listener &&
          listener->callbacks.surface_destroyed_callback.has_value()) {
        auto callback = listener->callbacks.surface_destroyed_callback;
        (*callback)(surface_key);
      }
    }
    is_running_callback_ = false;
    HandleListenerAfterCallbacksLoop();
  }
}

void PlatformViewObserver::OnPlatformViewCreated(const std::string &name,
                                                 uintptr_t view_key,
                                                 int32_t width,
                                                 int32_t height) {
  auto it = std::find_if(
      view_info_vector_.cbegin(), view_info_vector_.cend(),
      [view_key](auto &item) { return item->view_key == view_key; });
  if (it == view_info_vector_.cend()) {
    KRYPTON_LOGI("[OnPlatformViewCreated] Canvas view created with name: ")
        << name << " view_key: " << view_key << " this: " << this
        << " canvas_app: " << canvas_app_ptr_;
    auto view_info = std::make_unique<PlatformViewInfo>(PlatformViewInfo{
        .name = name,
        .view_key = view_key,
        .width = width,
        .height = height,
        .touch_width = width,
        .touch_height = height,
    });
    view_info_vector_.emplace_back(std::move(view_info));
    HandleViewSizeChange(name, 0, 0, width, height);
  } else {
    KRYPTON_LOGI("[OnPlatformViewCreated] Canvas view with name: ")
        << name << " view_key: " << view_key << " has been registered."
        << " this: " << this << " canvas_app: " << canvas_app_ptr_;
  }
}

void PlatformViewObserver::OnPlatformViewLayoutUpdate(
    const std::string &name, uintptr_t view_key, int32_t width, int32_t height,
    int32_t top, int32_t bottom, int32_t left, int32_t right) {
  auto it = std::find_if(
      view_info_vector_.cbegin(), view_info_vector_.cend(),
      [view_key](auto &item) { return item->view_key == view_key; });
  if (it != view_info_vector_.cend()) {
    KRYPTON_LOGI(
        "[OnPlatformViewLayoutUpdate] Canvas view update layout with name: ")
        << name << " view_key: " << view_key << " this: " << this
        << " canvas_app: " << canvas_app_ptr_;
    int32_t old_width = (*it)->width;
    int32_t old_height = (*it)->height;
    (*it)->width = width;
    (*it)->height = height;
    (*it)->touch_width = width;
    (*it)->touch_height = height;
    (*it)->layout.top = top;
    (*it)->layout.bottom = bottom;
    (*it)->layout.left = left;
    (*it)->layout.right = right;
    HandleViewSizeChange(name, old_width, old_height, width, height);
  } else {
    KRYPTON_LOGI("[OnPlatformViewLayoutUpdate] Canvas view with name: ")
        << name << " view_key: " << view_key << " has been registered"
        << " this: " << this << " canvas_app: " << canvas_app_ptr_;
  }
}

void PlatformViewObserver::OnPlatformViewDestroyed(const std::string &name,
                                                   uintptr_t view_key) {
  auto it = std::find_if(
      view_info_vector_.cbegin(), view_info_vector_.cend(),
      [view_key](auto &item) { return item->view_key == view_key; });

  if (it != view_info_vector_.cend()) {
    view_info_vector_.erase(it);
    KRYPTON_LOGI("[OnPlatformViewDestroyed] Canvas view destroyed with name: ")
        << name << " view_key: " << view_key << " this: " << this
        << " canvas_app: " << canvas_app_ptr_;
  } else {
    KRYPTON_LOGI("[OnPlatformViewDestroyed] Canvas view with name: ")
        << name << " view_key: " << view_key << " has been registered."
        << " this: " << this << " canvas_app: " << canvas_app_ptr_;
  }
}

void PlatformViewObserver::OnPlatformViewNeedRedraw(const std::string &name) {
  KRYPTON_LOGI("[OnPlatformViewNeedRedraw] CanvasView need redraw with name: ")
      << name;

  auto it = listeners_.find(name);
  if (it != listeners_.end()) {
    is_running_callback_ = true;
    const auto &listener_vec = it->second;
    for (const auto &listener_weak : listener_vec) {
      auto listener = listener_weak.lock();
      if (listener &&
          listener->callbacks.view_need_redraw_callback.has_value()) {
        auto callback = listener->callbacks.view_need_redraw_callback;
        (*callback)();
      }
    }
    is_running_callback_ = false;
    HandleListenerAfterCallbacksLoop();
  }
}

void PlatformViewObserver::OnTouch(const std::string &name,
                                   std::shared_ptr<DataHolder> event) {
  auto it = listeners_.find(name);
  if (it != listeners_.end()) {
    is_running_callback_ = true;
    const auto &listener_vec = it->second;
    for (const auto &listener_weak : listener_vec) {
      auto listener = listener_weak.lock();
      if (listener && listener->callbacks.touch_callback.has_value()) {
        auto callback = listener->callbacks.touch_callback;
        (*callback)(event);
      }
    }
    is_running_callback_ = false;
    HandleListenerAfterCallbacksLoop();
  }
}

void PlatformViewObserver::RegisterEventListener(
    std::shared_ptr<PlatformViewEventListener> listener) {
  if (is_running_callback_) {
    KRYPTON_LOGI(
        "[RegisterEventListener] Register listener from canvas element in "
        "callback loop!")
        << " canvas name: " << listener->platform_view_name
        << " canvas id: " << listener->unique_key << " this: " << this
        << " canvas_app: " << canvas_app_ptr_;
    pending_register_listener_.emplace_back(std::move(listener));
  } else {
    AddListenerToCollector(listener);
  }
}

void PlatformViewObserver::DeregisterEventListener(
    std::shared_ptr<PlatformViewEventListener> listener) {
  if (is_running_callback_) {
    KRYPTON_LOGI(
        "[DeregisterEventListener] DeRegister listener from canvas element in "
        "callback loop!")
        << " canvas name: " << listener->platform_view_name
        << " canvas id: " << listener->unique_key << " this: " << this
        << " canvas_app: " << canvas_app_ptr_;
    pending_deregister_listener_.emplace_back(std::move(listener));
  } else {
    RemoveListenerFromCollector(listener);
  }
}

void PlatformViewObserver::HandleListenerAfterCallbacksLoop() {
  for (const auto &register_listener : pending_deregister_listener_) {
    auto register_listener_share = register_listener.lock();
    if (register_listener_share) {
      AddListenerToCollector(register_listener_share);
    }
  }

  for (const auto &deregister_listener : pending_deregister_listener_) {
    auto deregister_listener_share = deregister_listener.lock();
    if (deregister_listener_share) {
      RemoveListenerFromCollector(deregister_listener_share);
    }
  }

  // clear after loop
  pending_register_listener_.clear();
  pending_deregister_listener_.clear();
}

void PlatformViewObserver::AddListenerToCollector(
    std::shared_ptr<PlatformViewEventListener> listener) {
  auto unique_key = listener->unique_key;
  auto platform_name = listener->platform_view_name;
  auto &listener_vec = listeners_[platform_name];
  auto it = std::find_if(listener_vec.cbegin(), listener_vec.cend(),
                         [unique_key](auto &item) {
                           if (auto share_listener = item.lock()) {
                             return share_listener->unique_key == unique_key;
                           }
                           return false;
                         });
  if (it == listener_vec.cend()) {
    KRYPTON_LOGI(
        "[AddListenerToCollector] Register listener from canvas element: ")
        << " name: " << platform_name << " unique_id: " << unique_key
        << " this: " << this << " canvas_app: " << canvas_app_ptr_;
    listener_vec.emplace_back(std::move(listener));
  } else {
    KRYPTON_LOGI("[AddListenerToCollector] listener with name: ")
        << listener->platform_view_name
        << " unique_id: " << listener->unique_key << " has been registered"
        << " this: " << this << " canvas_app: " << canvas_app_ptr_;
  }
}

void PlatformViewObserver::RemoveListenerFromCollector(
    std::shared_ptr<PlatformViewEventListener> listener) {
  auto platform_name = listener->platform_view_name;
  auto unique_key = listener->unique_key;
  auto listener_it = listeners_.find(platform_name);
  if (listener_it != listeners_.end()) {
    auto &listener_vec = listener_it->second;
    for (auto it = listener_vec.cbegin(); it != listener_vec.cend();) {
      auto listener_share = (*it).lock();
      if (listener_share && listener_share->unique_key == unique_key) {
        KRYPTON_LOGI(
            "[RemoveListenerFromCollector] DeRegister listener from canvas "
            "element: ")
            << " name: " << platform_name << " unique_id: " << unique_key
            << " this: " << this << " canvas_app: " << canvas_app_ptr_;
        it = listener_vec.erase(it);
        return;
      } else {
        ++it;
      }
    }
  }
  KRYPTON_LOGI("[RemoveListenerFromCollector] listener with name: ")
      << listener->platform_view_name << " unique_id: " << listener->unique_key
      << " has not been registered!!"
      << " this: " << this << " canvas_app: " << canvas_app_ptr_;
}

void PlatformViewObserver::HandleViewSizeChange(const std::string &name,
                                                int32_t old_width,
                                                int32_t old_height,
                                                int32_t new_width,
                                                int32_t new_height) {
  if (old_width != new_width || old_height != new_height) {
    auto it = listeners_.find(name);
    if (it != listeners_.end()) {
      is_running_callback_ = true;
      const auto &listener_vec = it->second;
      for (const auto &listener_weak : listener_vec) {
        auto listener = listener_weak.lock();
        if (listener &&
            listener->callbacks.view_size_changed_callback.has_value()) {
          auto callback = listener->callbacks.view_size_changed_callback;
          (*callback)(old_width, old_height, new_width, new_height);
        }
      }
      is_running_callback_ = false;
      HandleListenerAfterCallbacksLoop();
    }
  }
}

const PlatformViewInfo *PlatformViewObserver::GetViewInfoByViewName(
    const std::string &name) {
  auto it =
      std::find_if(view_info_vector_.cbegin(), view_info_vector_.cend(),
                   [name_ = name](auto &impl) { return impl->name == name_; });
  if (it != view_info_vector_.end()) {
    return (*it).get();
  }
  return nullptr;
}

bool PlatformViewObserver::IsPlatformViewAvailable(const std::string &name) {
  const auto *view_info = GetViewInfoByViewName(name);
  if (view_info) {
    return view_info->width > 0 && view_info->height > 0;
  }
  return false;
}

}  // namespace canvas
}  // namespace lynx
