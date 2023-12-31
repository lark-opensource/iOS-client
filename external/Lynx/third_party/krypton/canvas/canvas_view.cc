// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/canvas_view.h"

#include "canvas/canvas_app.h"
#include "canvas/canvas_ui_proxy.h"
#include "canvas/gpu/gl_global_device_attributes.h"
#include "canvas/platform_view_observer.h"
#include "canvas/workaround/runtime_flags_for_workaround.h"
#include "third_party/fml/make_copyable.h"

namespace lynx {
namespace canvas {

CanvasView::CanvasView(
    std::string id,
    std::shared_ptr<shell::LynxActor<CanvasRuntime>> runtime_actor,
    std::weak_ptr<CanvasApp> weak_canvas_app)
    : id_(std::move(id)), surface_(nullptr), weak_canvas_app_(weak_canvas_app) {
  runtime_actor_ = runtime_actor;
  key_ = reinterpret_cast<uintptr_t>(this);
}

CanvasView::~CanvasView() = default;

static inline std::shared_ptr<CanvasApp> GetCanvasApp(
    std::weak_ptr<CanvasApp> weak_canvas_app) {
  return weak_canvas_app.lock();
}

void CanvasView::OnSurfaceCreated(std::unique_ptr<Surface> surface,
                                  int32_t width, int32_t height) {
  surface_ptr_ = reinterpret_cast<uintptr_t>(surface.get());
  auto canvas_app = GetCanvasApp(weak_canvas_app_);
  if (canvas_app) {
    canvas_app->GetUIProxy()->SetSurfaceAbstract(surface_ptr_, id_, width,
                                                 height);
  }
  runtime_actor_->Act(fml::MakeCopyable(
      [weak_canvas_app = weak_canvas_app_, id = id_, surface_key = surface_ptr_,
       surface = std::move(surface), width, height](auto& impl) mutable {
        auto canvas_app = GetCanvasApp(weak_canvas_app);
        if (!canvas_app) return;
        canvas_app->platform_view_observer()->OnSurfaceCreated(
            std::move(surface), surface_key, id, width, height);
      }));
}

void CanvasView::OnSurfaceChanged(int32_t width, int32_t height) {
  auto canvas_app = GetCanvasApp(weak_canvas_app_);
  if (canvas_app) {
    canvas_app->GetUIProxy()->UpdateSurfaceAbstract(surface_ptr_, width,
                                                    height);
  }
  auto& attribute = GLGlobalDeviceAttributes::Instance();
  // if attribute do not valid, no context created, do not need set flag.
  if (attribute.Valid() && attribute.GetDeviceAttributesRef()
                               .need_workaround_egl_sync_after_resize) {
    KRYPTON_LOGI("workaround set surface resize flag");
    workaround::any_surface_resized.store(true, std::memory_order_relaxed);
  }
  runtime_actor_->Act([weak_canvas_app = weak_canvas_app_, id = id_, width,
                       height, surface_key = surface_ptr_](auto& impl) {
    auto canvas_app = GetCanvasApp(weak_canvas_app);
    if (!canvas_app) return;
    canvas_app->platform_view_observer()->OnSurfaceChanged(id, surface_key,
                                                           width, height);
  });
}

void CanvasView::OnSurfaceDestroyed() {
  auto canvas_app = GetCanvasApp(weak_canvas_app_);
  if (canvas_app) {
    canvas_app->GetUIProxy()->DeleteSurfaceAbstract(surface_ptr_);
  }
  runtime_actor_->Act([weak_canvas_app = weak_canvas_app_, id = id_,
                       surface_ptr = surface_ptr_](auto& impl) {
    auto canvas_app = GetCanvasApp(weak_canvas_app);
    if (!canvas_app) return;
    canvas_app->platform_view_observer()->OnSurfaceDestroyed(id, surface_ptr);
  });
}

void CanvasView::OnTouch(const CanvasTouchEvent* event) {
  auto eventHolder = DataHolder::MakeWithCopy(event, sizeof(CanvasTouchEvent));
  runtime_actor_->Act(fml::MakeCopyable(
      [id = id_, eventHolder = std::move(eventHolder),
       weak_canvas_app = weak_canvas_app_](auto& impl) mutable {
        auto canvas_app = GetCanvasApp(weak_canvas_app);
        if (canvas_app) {
          canvas_app->platform_view_observer()->OnTouch(id,
                                                        std::move(eventHolder));
        }
      }));
}

void CanvasView::OnLayoutUpdate(int32_t left, int32_t right, int32_t top,
                                int32_t bottom, int32_t width, int32_t height) {
  runtime_actor_->Act(fml::MakeCopyable(
      [id = id_, key = key_, weak_canvas_app = weak_canvas_app_, left_ = left,
       right_ = right, top_ = top, bottom_ = bottom, width_ = width,
       height_ = height](auto& impl) {
        auto canvas_app = GetCanvasApp(weak_canvas_app);
        if (canvas_app) {
          canvas_app->platform_view_observer()->OnPlatformViewLayoutUpdate(
              id, key, width_, height_, top_, bottom_, left_, right_);
        }
      }));
}

void CanvasView::OnCanvasViewCreated(const std::string& id, int32_t width,
                                     int32_t height) {
  runtime_actor_->Act([key = key_, id_ = id, width_ = width, height_ = height,
                       weak_canvas_app = weak_canvas_app_](auto& impl) {
    auto canvas_app = GetCanvasApp(weak_canvas_app);
    if (canvas_app) {
      canvas_app->platform_view_observer()->OnPlatformViewCreated(
          id_, key, width_, height_);
    }
  });
}

void CanvasView::OnCanvasViewDestroyed() {
  runtime_actor_->Act([id = id_, key = key_,
                       weak_canvas_app = weak_canvas_app_](auto& impl) {
    auto canvas_app = GetCanvasApp(weak_canvas_app);
    if (canvas_app) {
      canvas_app->platform_view_observer()->OnPlatformViewDestroyed(id, key);
    }
  });
}

void CanvasView::OnCanvasViewNeedRedraw() {
  runtime_actor_->Act(
      [weak_canvas_app = weak_canvas_app_, id = id_](auto& impl) {
        auto canvas_app = GetCanvasApp(weak_canvas_app);
        if (!canvas_app) return;
        canvas_app->platform_view_observer()->OnPlatformViewNeedRedraw(id);
      });
}

}  // namespace canvas
}  // namespace lynx
