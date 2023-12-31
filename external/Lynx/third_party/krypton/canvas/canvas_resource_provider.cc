// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/canvas_resource_provider.h"

#include <utility>

#include "canvas/background_lock.h"
#include "canvas/base/log.h"
#include "canvas/canvas_element.h"
#include "canvas/gpu/gl_global_device_attributes.h"
#include "canvas/gpu/gl_initializer.h"
#include "canvas/gpu/gl_surface.h"
#include "canvas/raster.h"
#include "canvas/surface/surface.h"
#include "canvas/surface_client.h"
#include "canvas/webgl/raster_3d.h"
#include "third_party/fml/make_copyable.h"

namespace lynx {
namespace canvas {

#ifdef LYNX_KRYPTON_TEST
namespace test {
extern void AccumulateGPUTime(const std::function<void()>& task);
extern bool IsAccumulatingJSTime();
extern void FixJSTimeBySubtractingLastGPUTime();
}  // namespace test
#endif

CanvasResourceProvider::CanvasResourceProvider(
    CanvasElement* element,
    std::shared_ptr<shell::LynxActor<CanvasRuntime>> actor,
    std::shared_ptr<shell::LynxActor<SurfaceRegistry>> surface_actor,
    Option option)
    : runtime_actor_(std::move(actor)),
      surface_actor_(std::move(surface_actor)),
      element_(element),
      option_(std::move(option)),
      raster_(nullptr),
      gpu_waitable_event_(std::make_unique<CountDownWaitableEvent>(2)) {
  KRYPTON_CONSTRUCTOR_LOG(CanvasResourceProvider);

  command_recorder_ = std::make_unique<CommandRecorder>(
      [this](CommandRecorder* recorder, bool is_sync) {
        FlushCommandBufferInternal(false, is_sync);
      });
}

bool CanvasResourceProvider::Init(
    const fml::RefPtr<fml::TaskRunner>& gpu_task_runner) {
  // current we must have gpu task runner, maybe replaced by runtime_task_runner
  // by switch
  DCHECK(gpu_task_runner);

  // make sure gl init before context return
  if (!GLInitializer::Instance().InitOnJSThreadBlocked(gpu_task_runner)) {
    return false;
  }

  raster_ =
      CreateRaster(this, gpu_waitable_event_.get(), gpu_task_runner, option_);

  if (element_ && !element_->GetCanvasId().empty()) {
    auto surface_client = std::make_unique<SurfaceClient>(
        surface_actor_, element_->GetCanvasId(), element_->UniqueId(),
        element_->GetRasterPriority());
    raster_->set_surface_client(std::move(surface_client));
  }

  gpu_actor_ = std::make_shared<shell::LynxActor<Raster>>(
      std::unique_ptr<Raster>(raster_), gpu_task_runner);

  // Init Raster on GPU thread
  RunOnGPU(fml::MakeCopyable([this](auto& impl) mutable { raster_->Init(); }));

  FlushNewCanvasSize();

  return true;
}

CanvasResourceProvider::~CanvasResourceProvider() {
  if (gpu_actor_) {
    // if resource provider init fail, no actor nor raster can be used.
    // flush command buffer to avoid resource leak
    FlushCommandBufferInternal(false, false);
    gpu_actor_->ActSync([](auto& impl) { impl = nullptr; });
  }
  KRYPTON_DESTRUCTOR_LOG(CanvasResourceProvider);
}

int CanvasResourceProvider::GetCanvasWidth() const {
  return element_ ? element_->GetWidth() : 0;
}

int CanvasResourceProvider::GetCanvasHeight() const {
  return element_ ? element_->GetHeight() : 0;
}

void CanvasResourceProvider::RequestVSync() {
  if (!app_is_visible_) {
    return;
  }
  if (has_requested_vsync_) {
    // Currently, do not care about race condition, as RequestVSync always
    // running in runtime task
    return;
  }
  has_requested_vsync_ = true;
  std::weak_ptr<CanvasResourceProvider> weak = shared_from_this();
  runtime_actor_->Act([this, weak](auto& runtime) {
    runtime->AsyncRequestVSync(
        reinterpret_cast<uintptr_t>(this),
        [weak](int64_t frame_start, int64_t frame_end) {
          auto shared = weak.lock();
          if (shared) {
            shared->DoFrame(frame_start, frame_end);
          }
        },
        true);
  });
}

void CanvasResourceProvider::DoFrame(int64_t frame_start, int64_t frame_end) {
  has_requested_vsync_ = false;

  Flush();
}

void CanvasResourceProvider::RunOnGPU(
    std::function<void(const std::unique_ptr<Raster>&)> func) {
  DCHECK(gpu_actor_);
#ifdef LYNX_KRYPTON_TEST
  gpu_actor_->Act([func = std::move(func), this](auto& raster) {
    test::AccumulateGPUTime([&] { func(raster); });
  });
#else
  gpu_actor_->Act([func = std::move(func)](auto& raster) {
#ifdef OS_IOS
    BackgroundLock::Instance().WaitForForeground();
#endif
    func(raster);
  });
#endif
}

void CanvasResourceProvider::SyncRunOnGPU(
    std::function<void(const std::unique_ptr<Raster>&)> func) {
  DCHECK(gpu_actor_);
#ifdef LYNX_KRYPTON_TEST
  gpu_actor_->ActSync([func = std::move(func), this](auto& raster) {
    test::AccumulateGPUTime([&] { func(raster); });
  });
#else
  gpu_actor_->ActSync(func);
#endif
}

FlushResult CanvasResourceProvider::FlushIgnoreClientSide(bool blit_to_screen,
                                                          bool is_sync,
                                                          bool force) {
  if (need_redraw_ || force) {
    DoRaster(blit_to_screen, is_sync);
    if (blit_to_screen) {
      need_redraw_ = false;
    }
  }
  return {};
}

FlushResult CanvasResourceProvider::Flush(bool blit_to_screen, bool is_sync,
                                          bool force) {
  // Flush client command buffer if necessary.
  if (client_on_frame_) {
    client_on_frame_();
  }

  return FlushIgnoreClientSide(blit_to_screen, is_sync, force);
}

void CanvasResourceProvider::SetNeedRedraw() {
  need_redraw_ = true;
  RequestVSync();
}

void CanvasResourceProvider::SetCanvasElement(CanvasElement* element) {
  element_ = element;
}

void CanvasResourceProvider::OnAppEnterForeground() {
  if (app_is_visible_) {
    return;
  }
  app_is_visible_ = true;
  RequestVSync();
}

void CanvasResourceProvider::OnAppEnterBackground() { app_is_visible_ = false; }

void CanvasResourceProvider::OnCanvasSizeChanged() {
  // make sure all prev commands execute before resize.
  Flush(false, false, true);
  FlushNewCanvasSize();
  OnCanvasSizeChangedInternal();
  SetNeedRedraw();
}

void CanvasResourceProvider::FlushNewCanvasSize() {
  int width = GetCanvasWidth();
  int height = GetCanvasHeight();
  // webgl may adjust size due to device limitation
  AdjustCanvasSizeInResizeIfNeeded(width, height);
  RunOnGPU([width, height](auto& impl) {
    impl->OnCanvasSizeChanged(width, height);
  });
}

void CanvasResourceProvider::WaitForLastGPUTaskFinished() {
  gpu_waitable_event_->CountDown();
}

void CanvasResourceProvider::AttachToOnscreenCanvas() {
  DCHECK(element_ && !element_->GetCanvasId().empty());
  auto surface_client = std::make_unique<SurfaceClient>(
      surface_actor_, element_->GetCanvasId(), element_->UniqueId(),
      element_->GetRasterPriority());

  RunOnGPU(fml::MakeCopyable(
      [client = std::move(surface_client)](auto& raster) mutable {
        client->Init();
        raster->set_surface_client(std::move(client));
      }));
  SetNeedRedraw();
}

void CanvasResourceProvider::UpdateRasterPriority(int32_t priority) {
  RunOnGPU([raster_priority = priority](auto& raster) {
    raster->UpdateSurfaceClientPriority(raster_priority);
  });
  SetNeedRedraw();
}

void CanvasResourceProvider::DetachFromOnscreenCanvas() {
  RunOnGPU([](auto& raster) { raster->ReleaseSurfaceClient(); });
}

#ifdef ENABLE_LYNX_CANVAS_SKIA
sk_sp<SkImage> CanvasResourceProvider::MakeSnapshot(const SkIRect& rect,
                                                    const SkPixmap* pixmap) {
  Flush();
  sk_sp<SkImage> res_image;
  SyncRunOnGPU([rect, pixmap, &res_image](auto& impl) {
    res_image = impl->MakeSnapshot(rect, pixmap);
  });
  return res_image;
}
#endif

void CanvasResourceProvider::FlushCommandBufferInternal(bool blit_to_screen,
                                                        bool is_sync) {
  auto runnable_buffer = command_recorder_->FinishRecordingAndRestart();

  WaitForLastGPUTaskFinished();

#ifdef LYNX_KRYPTON_TEST
  bool fixJSTime = !is_sync && test::IsAccumulatingJSTime();
  if (fixJSTime) {
    // Make raster sync and subtract GPU time from JS time.
    is_sync = true;
  }
#endif

  if (is_sync) {
    SyncRunOnGPU([runnable_buffer, blit_to_screen](auto& raster) {
      raster->DoRaster(runnable_buffer, blit_to_screen);
    });
  } else {
    RunOnGPU([runnable_buffer, blit_to_screen](auto& raster) {
      raster->DoRaster(runnable_buffer, blit_to_screen);
    });
  }

#ifdef LYNX_KRYPTON_TEST
  if (fixJSTime) {
    test::FixJSTimeBySubtractingLastGPUTime();
  }
#endif
}

uint32_t CanvasResourceProvider::reading_fbo() const {
  return raster_->reading_fbo();
}

uint32_t CanvasResourceProvider::drawing_fbo() const {
  return raster_->drawing_fbo();
}

}  // namespace canvas
}  // namespace lynx
