// Copyright (c) 2023 The Lynx Authors. All rights reserved.
#ifndef CANVAS_PLATFORM_VIEW_OBSERVER_H_
#define CANVAS_PLATFORM_VIEW_OBSERVER_H_

#include "canvas/canvas_view.h"
#include "canvas/surface_registry.h"

namespace lynx {
namespace canvas {
struct PlatformViewEventListener;
using SurfaceCreatedListener =
    std::function<void(uintptr_t surface_key, const std::string& name,
                       int32_t width, int32_t height)>;
using SurfaceChangedListener =
    std::function<void(uintptr_t surface_key, int32_t width, int32_t height)>;
using SurfaceNeedRedrawListener = std::function<void()>;
using ViewSizeChangedListener =
    std::function<void(int32_t old_width, int32_t old_height, int32_t new_width,
                       int32_t new_height)>;
using SurfaceDestroyedListener = std::function<void(uintptr_t surface_key)>;
using PlatformViewTouchListener =
    std::function<void(std::shared_ptr<DataHolder>)>;
using PlatformViewEventListenerCollector =
    std::unordered_map<std::string,
                       std::vector<std::weak_ptr<PlatformViewEventListener>>>;

struct PlatformViewEventListener {
  // basic info
  std::string platform_view_name;
  uintptr_t unique_key;
  // callbacks
  // TODO(dupengcheng): replace std::function with base class, no more lambda
  // binding.
  struct {
    std::optional<SurfaceCreatedListener> surface_created_callback;
    std::optional<SurfaceChangedListener> surface_changed_callback;
    std::optional<ViewSizeChangedListener> view_size_changed_callback;
    std::optional<SurfaceDestroyedListener> surface_destroyed_callback;
    std::optional<PlatformViewTouchListener> touch_callback;
    std::optional<SurfaceNeedRedrawListener> view_need_redraw_callback;
  } callbacks;
};

struct PlatformViewInfo {
  // basic info
  std::string name;
  uintptr_t view_key;
  // size
  int32_t width = 0;
  int32_t height = 0;
  //  Deprecated, surface size, use client size instead
  //  Touch width / height are used to set canvas element size in js side.
  //  This pair properties is not defined in web specification. Use
  //  client width/height to replace them.
  int32_t touch_width = 0;
  int32_t touch_height = 0;
  // layout
  struct {
    int32_t top = 0;
    int32_t bottom = 0;
    int32_t left = 0;
    int32_t right = 0;
  } layout;
};

class PlatformViewObserver {
 public:
  explicit PlatformViewObserver(
      std::shared_ptr<shell::LynxActor<SurfaceRegistry>> actor,
      uintptr_t canvas_app_ptr);
  PlatformViewObserver(const PlatformViewObserver& observer) = delete;

  PlatformViewObserver& operator=(const PlatformViewObserver&) = delete;
  // surface event
  void OnSurfaceCreated(std::unique_ptr<Surface> surface, uintptr_t surface_key,
                        const std::string& name, int32_t width, int32_t height);

  void OnSurfaceChanged(const std::string& name, uintptr_t surface_key,
                        int32_t new_width, int32_t new_height);

  void OnSurfaceDestroyed(const std::string& name, uintptr_t surface_key);

  // view event
  // In web specifies, surface is not defined, canvas element is generally
  // regarded as HtmlCanvasElement in dom tree. In Lynx environment, we regard
  // the clientWidth/clientHeight/BoundingClientRect properties of
  // HtmlCanvasElement as the properties of lynx UICanvasView
  void OnPlatformViewCreated(const std::string& name, uintptr_t view_key,
                             int32_t width, int32_t height);

  void OnPlatformViewDestroyed(const std::string& name, uintptr_t view_key);

  void OnPlatformViewLayoutUpdate(const std::string& name, uintptr_t view_key,
                                  int32_t width, int32_t height, int32_t top,
                                  int32_t bottom, int32_t left, int32_t right);

  void OnPlatformViewNeedRedraw(const std::string& name);

  void OnTouch(const std::string& name, std::shared_ptr<DataHolder> event);

  // listeners
  void RegisterEventListener(std::shared_ptr<PlatformViewEventListener>);
  void DeregisterEventListener(std::shared_ptr<PlatformViewEventListener>);

  const PlatformViewInfo* GetViewInfoByViewName(const std::string& name);

  bool IsPlatformViewAvailable(const std::string& name);

  std::vector<std::unique_ptr<PlatformViewInfo>>& view_info_vector() {
    return view_info_vector_;
  }

 private:
  void HandleListenerAfterCallbacksLoop();
  void AddListenerToCollector(
      std::shared_ptr<PlatformViewEventListener> listener);
  void RemoveListenerFromCollector(
      std::shared_ptr<PlatformViewEventListener> listener);
  void HandleViewSizeChange(const std::string& name, int32_t old_width,
                            int32_t old_height, int32_t new_width,
                            int32_t new_height);

  std::shared_ptr<shell::LynxActor<SurfaceRegistry>> surface_registry_actor_;
  std::vector<std::unique_ptr<PlatformViewInfo>> view_info_vector_;
  PlatformViewEventListenerCollector listeners_;

  // NOTICE!! In some case, c++ called to js side may cause new element
  // created or deleted synchronous, which makes the iterator of
  // listeners_ invalid. So delay the registered and deRegistered operations in
  // event callbacks loop.
  bool is_running_callback_ = false;
  std::vector<std::weak_ptr<PlatformViewEventListener>>
      pending_register_listener_;
  std::vector<std::weak_ptr<PlatformViewEventListener>>
      pending_deregister_listener_;
  uintptr_t canvas_app_ptr_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_PLATFORM_VIEW_OBSERVER_H_
