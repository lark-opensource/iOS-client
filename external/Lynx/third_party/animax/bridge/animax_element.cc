// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/bridge/animax_element.h"

#include "animax/animator/value_animator.h"
#include "animax/base/count_down_event.h"
#include "animax/base/log.h"
#include "animax/base/thread_assert.h"
#include "animax/bridge/animax_onscreen_surface.h"
#include "animax/layer/composition_layer.h"
#include "animax/model/basic_model.h"
#include "animax/parser/layer_parser.h"
#include "animax/render/include/context.h"
#include "animax/render/include/matrix.h"
#include "animax/render/include/surface.h"
#include "animax/resource/composition_fetcher.h"
#include "canvas/canvas_app.h"
#include "third_party/fml/make_copyable.h"

namespace lynx {
namespace animax {

AnimaXElement::AnimaXElement(
    std::shared_ptr<lynx::canvas::CanvasApp> canvas_app, float scale)
    : canvas_app_(canvas_app), scale_(scale) {
  ANIMAX_LOGI("AnimaXElement constructor");
  ANIMAX_LOGI("CanvasApp: ") << std::to_string(!!canvas_app);
  DCHECK(canvas_app);
  gpu_task_runner_ = canvas_app->gpu_task_runner();
  js_task_runner_ = canvas_app->runtime_task_runner();
  count_down_event_ = std::make_unique<CountDownEvent>(2);
  current_src_index_.store(0);
}

AnimaXElement::~AnimaXElement() { ANIMAX_LOGI("AnimaXElement destructor"); }

void AnimaXElement::AddEventListener(EventListener listener) {
  RunOnJSThread([listener = std::move(listener)](AnimaXElement& element) {
    element.event_listeners_.push_back(std::move(listener));
  });
}

void AnimaXElement::Init() {
  record_->Init(this);
  RunOnJSThread([](AnimaXElement& element) {
    ThreadAssert::Init(ThreadAssert::Type::kJS);
    auto shared_element = element.shared_from_this();
    auto canvas_app = element.canvas_app_.lock();
    if (canvas_app) {
      canvas_app->RegisterAppShowStatusObserver(shared_element);
    }
    element.fetcher_ = std::make_shared<CompositionFetcher>(
        shared_element, element.canvas_app_, element.scale_);
    element.value_animator_ = std::make_shared<ValueAnimator>(
        canvas_app->runtime_actor(), shared_element);
  });
  RunOnGPUThread([](AnimaXElement& element) {
    ThreadAssert::Init(ThreadAssert::Type::kGPU);
  });
}

std::unordered_map<std::string, double> AnimaXElement::GetPerfMetrics() {
  return record_->GetPerfMetrics();
}

PerformanceRecord& AnimaXElement::GetRecord() { return *record_; }

void AnimaXElement::Destroy() {
  RunOnJSThread(
      [](AnimaXElement& element) {
        if (element.js_destroyed_) {
          return;
        }
        ANIMAX_LOGI("AnimaXElement JS Destroy");
        element.js_destroyed_ = true;
        if (element.value_animator_) {
          element.value_animator_->Destroy();
          element.value_animator_ = nullptr;
        }
        element.fetcher_ = nullptr;
        element.event_listeners_.clear();
      },
      true);
  RunOnGPUThread(
      [](AnimaXElement& element) {
        if (element.gpu_destroyed_) {
          return;
        }
        ANIMAX_LOGI("AnimaXElement GPU Destroy");
        element.gpu_destroyed_ = true;
        element.surface_created_ = false;
        element.layer_ = nullptr;
        element.model_ = nullptr;
        if (element.offscreen_surface_) {
          element.offscreen_surface_->Destroy();
          element.offscreen_surface_ = nullptr;
        }
        element.onscreen_surface_ = nullptr;
      },
      true);
}

void AnimaXElement::OnSurfaceCreated(
    float width, float height, std::unique_ptr<lynx::canvas::Surface> surface) {
  if (onscreen_surface_) {
    ANIMAX_LOGW("OnSurfaceCreated called more than once");
    return;
  }
  onscreen_surface_ =
      std::make_unique<AnimaXOnScreenSurface>(std::move(surface));

  RunOnGPUThread([width, height](AnimaXElement& element) {
    element.width_ = width;
    element.height_ = height;
    element.onscreen_surface_->Init();
    element.onscreen_surface_->MakeRelatedContextCurrent();
    element.offscreen_surface_ = Context::MakeSurface(
        element.onscreen_surface_.get(), element.width_, element.height_);
    element.surface_created_ = true;
    element.StartAnimationIfNeeded();
  });
}

void AnimaXElement::OnSurfaceChanged(float width, float height) {
  RunOnGPUThread([width, height](AnimaXElement& element) {
    bool success = element.onscreen_surface_->Resize(width, height);
    if (!success) {
      return;
    }
    element.width_ = width;
    element.height_ = height;
    element.offscreen_surface_->Resize(element.onscreen_surface_.get(), width,
                                       height);
    // TODO(liuyufeng): need to redraw current frame
  });
}

void AnimaXElement::SetJson(const char* json) {
  std::string json_string = std::string(json);
  SetJson(std::move(json_string));
}

void AnimaXElement::SetJson(std::string&& json) {
  current_src_.clear();
  auto src_index = ++current_src_index_;
  RunOnJSThread([json = std::move(json), src_index](AnimaXElement& element) {
    element.ParseAndStartAnimationIfNeeded(json.c_str(), json.size(),
                                           src_index);
  });
}

void AnimaXElement::SetSrc(const std::string& src) {
  if (!current_src_.empty() && current_src_ == src) {
    return;
  }
  current_src_ = src;
  auto src_index = ++current_src_index_;
  RunOnJSThread([src, src_index](AnimaXElement& element) {
    std::weak_ptr<AnimaXElement> weak_element = element.shared_from_this();
    ANIMAX_LOGI("SetSrc index: ") << src_index << ", src: " << src;
    element.fetcher_->RequestSource(
        src,
        [weak_element, src_index](std::unique_ptr<lynx::canvas::RawData> data,
                                  const std::string& err_msg) {
          std::shared_ptr<AnimaXElement> element = weak_element.lock();
          if (!element) {
            return;
          }
          element->RunOnJSThread(
              fml::MakeCopyable([src_index, data = std::move(data),
                                 err_msg](AnimaXElement& element) {
                if (src_index != element.current_src_index_.load()) {
                  ANIMAX_LOGI("src has changed, discard the data");
                  return;
                }
                if (!data || !err_msg.empty()) {
                  ANIMAX_LOGI("RequestSource index: ")
                      << src_index << ", error: " << err_msg;
                  auto error_param = std::make_unique<ErrorParams>(
                      EventError::kResourceNotFound, err_msg);
                  element.NotifyEvent(Event::kError, error_param.get());
                  return;
                }
                element.record_->Record(ParseRecord::Stage::kRequestEnd);
                element.ParseAndStartAnimationIfNeeded(
                    reinterpret_cast<const char*>(data->data->Data()),
                    data->length, src_index);
              }));
        });
  });
}

void AnimaXElement::ParseAndStartAnimationIfNeeded(const char* json,
                                                   size_t length,
                                                   int32_t src_index) {
  std::weak_ptr<AnimaXElement> weak_element = shared_from_this();
  fetcher_->ParseJson(
      json, length,
      [weak_element, src_index](std::shared_ptr<CompositionModel> composition) {
        std::shared_ptr<AnimaXElement> element = weak_element.lock();
        if (!element) {
          return;
        }
        element->RunOnGPUThread(
            [src_index, composition](AnimaXElement& element) {
              if (src_index != element.current_src_index_.load()) {
                return;
              }
              element.model_ = composition;
              element.StartAnimationIfNeeded();
            });
      });
}

void AnimaXElement::SetSrcPolyfill(
    std::unordered_map<std::string, std::string>& polyfill) {
  RunOnJSThread([polyfill](AnimaXElement& element) mutable {
    element.fetcher_->SetSrcPolyfill(polyfill);
  });
}

void AnimaXElement::UpdateAnimationID() {
  animation_id_ = std::string("LYNX_ANIMAX_") +
                  std::to_string(reinterpret_cast<intptr_t>(this)) +
                  std::string("_PLAY_") + std::to_string(++play_count_);
}

void AnimaXElement::PlayInternal() {
  current_loop_ = 0;
  value_animator_->Seek(user_progress_, false /*is_frame*/,
                        true /*reset_loop_count*/);
  value_animator_->Play();
  user_progress_ = 0.0;
}

void AnimaXElement::UpdateProperties() {
  float start_frame = model_->GetStartFrame();
  float end_frame = model_->GetEndFrame();
  long duration = model_->GetDuration();
  float frame_rate = model_->GetFrameRate();
  RunOnJSThread(
      [start_frame, end_frame, duration, frame_rate](AnimaXElement& element) {
        element.start_frame_ = start_frame;
        element.end_frame_ = end_frame;
        element.duration_ms_ = duration;
        element.current_frame_ = start_frame;
        element.current_loop_ = 0;

        // stop last animation
        element.value_animator_->Stop();
        element.SetIsAnimating(false);
        element.value_animator_->SetOriginFrameProperty(
            element.start_frame_, element.end_frame_, frame_rate);
        element.value_animator_->SetPlaySegments(element.user_start_frame_,
                                                 element.user_end_frame_);
        element.UpdateAnimationID();
        element.NotifyEvent(Event::kReady);

        element.record_->Record(ParseRecord::Stage::kAnimationStart);

        if (element.autoplay_) {
          ANIMAX_LOGI("AutoPlay true");
          element.PlayInternal();
        } else {
          ANIMAX_LOGI("AutoPlay false, Seek user progress: ")
              << element.user_progress_;
          element.value_animator_->Seek(element.user_progress_, false);
        }
      });
}

void AnimaXElement::StartAnimation() {
  auto& bounds = model_->GetBounds();
  model_width_ = bounds.GetWidth();
  model_height_ = bounds.GetHeight();

  record_->Record(ParseRecord::Stage::kBuildLayerStart);
  std::shared_ptr<LayerModel> layer_model =
      LayerParser::Instance().Parse(*model_);
  layer_ = std::make_unique<CompositionLayer>(layer_model, *model_);
  layer_->SetLayerModels(model_->GetLayers());
  layer_->Init();
  record_->Record(ParseRecord::Stage::kBuildLayerEnd);

  UpdateProperties();
}

void AnimaXElement::StartAnimationIfNeeded() {
  if (!surface_created_ || !model_) {
    return;
  }
  StartAnimation();
}

void AnimaXElement::SetLoop(const bool loop) {
  RunOnJSThread([loop](AnimaXElement& element) {
    element.loop_ = loop;
    element.value_animator_->SetLoopCount(element.loop_ ? 0
                                                        : element.loop_count_);
  });
}

void AnimaXElement::SetLoopCount(const int32_t loop_count) {
  RunOnJSThread([loop_count](AnimaXElement& element) {
    element.loop_count_ = loop_count;
    element.value_animator_->SetLoopCount(element.loop_ ? 0
                                                        : element.loop_count_);
  });
}

void AnimaXElement::SetAutoReverse(const bool auto_reverse) {
  RunOnJSThread([auto_reverse](AnimaXElement& element) {
    element.value_animator_->SetAutoReverse(auto_reverse);
  });
}

void AnimaXElement::SetSpeed(const double speed) {
  RunOnJSThread([speed](AnimaXElement& element) {
    ANIMAX_LOGI("SetSpeed: ") << speed;
    element.value_animator_->SetSpeed(speed);
  });
}

void AnimaXElement::SetFpsEventInterval(const long interval) {
  RunOnJSThread([interval](AnimaXElement& element) {
    ANIMAX_LOGI("SetFpsEventInterval: ") << interval;
    element.record_->SetFpsEventInterval(interval);
  });
}

void AnimaXElement::SetProgress(const double progress) {
  RunOnJSThread([progress](AnimaXElement& element) {
    ANIMAX_LOGI("SetProgress: ") << progress;
    element.user_progress_ = progress;
  });
}

void AnimaXElement::SetAutoplay(const bool autoplay) {
  RunOnJSThread([autoplay](AnimaXElement& element) {
    ANIMAX_LOGI("SetAutoplay: ") << std::to_string(autoplay);
    element.autoplay_ = autoplay;
  });
}

void AnimaXElement::SetStartFrame(const double start_frame) {
  RunOnJSThread([start_frame](AnimaXElement& element) {
    element.user_start_frame_ = start_frame;
  });
}

void AnimaXElement::SetEndFrame(const double end_frame) {
  RunOnJSThread([end_frame](AnimaXElement& element) {
    element.user_end_frame_ = end_frame;
  });
}

void AnimaXElement::SetKeepLastFrame(const bool keep_last_frame) {
  RunOnJSThread([keep_last_frame](AnimaXElement& element) {
    element.keep_last_frame_ = keep_last_frame;
  });
}

void AnimaXElement::SetObjectFit(const ObjectFit object_fit) {
  RunOnGPUThread([object_fit](AnimaXElement& element) {
    element.object_fit_ = object_fit;
  });
}

void AnimaXElement::RunOnGPUThread(std::function<void(AnimaXElement&)> func,
                                   bool strong_element_ref) {
  if (strong_element_ref) {
    gpu_task_runner_->PostTask([element = shared_from_this(),
                                func = std::move(func)]() { func(*element); });
    return;
  }
  std::weak_ptr<AnimaXElement> weak_element = shared_from_this();
  gpu_task_runner_->PostTask([weak_element, func = std::move(func)]() {
    std::shared_ptr<AnimaXElement> element = weak_element.lock();
    if (!element || element->IsDestroyed()) {
      return;
    }
    func(*element);
  });
}

void AnimaXElement::RunOnJSThread(std::function<void(AnimaXElement&)> func,
                                  bool strong_element_ref) {
  if (strong_element_ref) {
    js_task_runner_->PostTask([element = shared_from_this(),
                               func = std::move(func)]() { func(*element); });
    return;
  }
  std::weak_ptr<AnimaXElement> weak_element = shared_from_this();
  js_task_runner_->PostTask([weak_element, func = std::move(func)]() {
    std::shared_ptr<AnimaXElement> element = weak_element.lock();
    if (!element || element->IsDestroyed()) {
      return;
    }
    func(*element);
  });
}

std::string AnimaXElement::GetAnimationID() { return animation_id_; }

double AnimaXElement::GetCurrentFrame() {
  return current_frame_ - start_frame_;
}

float AnimaXElement::GetTotalFrame() { return end_frame_ - start_frame_; }

int32_t AnimaXElement::GetLoopIndex() { return current_loop_; }

double AnimaXElement::GetDurationMs() { return duration_ms_; }

void AnimaXElement::Play() {
  RunOnJSThread([](AnimaXElement& element) {
    ANIMAX_LOGI("USER Play");
    element.UpdateAnimationID();
    element.PlayInternal();
  });
}

void AnimaXElement::Pause() {
  RunOnJSThread([](AnimaXElement& element) {
    ANIMAX_LOGI("USER Pause");
    element.value_animator_->Pause();
    element.SetIsAnimating(false);
  });
}

void AnimaXElement::Resume() {
  RunOnJSThread([](AnimaXElement& element) {
    ANIMAX_LOGI("USER Resume");
    element.value_animator_->Resume();
    element.SetIsAnimating(element.value_animator_->IsAnimating());
  });
}

void AnimaXElement::Stop() {
  RunOnJSThread([](AnimaXElement& element) {
    ANIMAX_LOGI("USER Stop");
    element.value_animator_->Stop();
    element.SetIsAnimating(false);
  });
}

void AnimaXElement::Seek(double frame) {
  RunOnJSThread([frame](AnimaXElement& element) {
    ANIMAX_LOGI("USER Seek: ") << frame;
    element.value_animator_->Seek(frame + element.start_frame_, true);
  });
}

bool AnimaXElement::IsAnimating() { return is_animating_; }

void AnimaXElement::SubscribeUpdateEvent(int32_t frame) {
  RunOnJSThread([frame](AnimaXElement& element) {
    element.subscribed_frames_.insert(frame);
  });
}

void AnimaXElement::UnsubscribeUpdateEvent(int32_t frame) {
  RunOnJSThread([frame](AnimaXElement& element) {
    element.subscribed_frames_.erase(frame);
  });
}

void AnimaXElement::OnStart() {
  if (IsDestroyed()) {
    return;
  }
  ANIMAX_LOGI("OnStart");
  SetIsAnimating(true);
  NotifyEvent(Event::kStart);
}

void AnimaXElement::OnProgress(double progress, double current_frame) {
  if (IsDestroyed()) {
    return;
  }
  if (!count_down_event_->TryCountDown()) {
    return;
  }
  current_frame_ = current_frame;
  auto frame = static_cast<int32_t>(std::trunc(GetCurrentFrame()));
  if (subscribed_frames_.count(frame)) {
    NotifyEvent(Event::kUpdate);
  }

  RunOnGPUThread([progress](AnimaXElement& element) {
    element.count_down_event_->CountUp();

    element.record_->Record(DrawRecord::Stage::kDrawStart);
    element.layer_->SetProgress(progress);

    element.onscreen_surface_->MakeRelatedContextCurrent();
    element.offscreen_surface_->Clear();
    Canvas* canvas = element.offscreen_surface_->GetCanvas();
    element.ResizeCanvas(*canvas);

    std::unique_ptr<Matrix> matrix = Context::MakeMatrix();
    element.layer_->Draw(*canvas, *matrix, 255);

    element.offscreen_surface_->Flush();
    element.onscreen_surface_->Flush();

    element.record_->Record(DrawRecord::Stage::kDrawEnd);
  });
}

void AnimaXElement::ResizeCanvas(Canvas& canvas) {
  float scale_factor = 1.f;
  if (ObjectFit::kCover == object_fit_) {
    scale_factor = std::max(width_ / model_width_, height_ / model_height_);
  } else if (ObjectFit::kContain == object_fit_) {
    scale_factor = std::min(width_ / model_width_, height_ / model_height_);
  }
  canvas.ResetMatrix();
  canvas.Translate((width_ - scale_factor * model_width_) / 2.f,
                   (height_ - scale_factor * model_height_) / 2.f);
  canvas.Scale(scale_factor, scale_factor);
}

void AnimaXElement::NotifyEvent(const Event event, IEventParams* params) {
  for (const auto& listener : event_listeners_) {
    listener(this, event, params);
  }
}

void AnimaXElement::OnNewLoop(int32_t current_loop) {
  if (IsDestroyed()) {
    return;
  }
  current_loop_ = current_loop;
  NotifyEvent(Event::kRepeat);
}

void AnimaXElement::OnEnd() {
  if (IsDestroyed()) {
    return;
  }
  ANIMAX_LOGI("OnEnd");
  if (!keep_last_frame_) {
    value_animator_->Seek(start_frame_, true);
  }
  SetIsAnimating(false);
  NotifyEvent(Event::kCompletion);
}

void AnimaXElement::OnAppEnterForeground() {
  if (IsDestroyed()) {
    return;
  }
  value_animator_->OnAppEnterForeground();
  SetIsAnimating(value_animator_->IsAnimating());
}

void AnimaXElement::OnAppEnterBackground() {
  if (IsDestroyed()) {
    return;
  }
  value_animator_->OnAppEnterBackground();
  SetIsAnimating(false);
}

void AnimaXElement::SetIsAnimating(const bool is_animating) {
  if (is_animating != is_animating_) {
    ANIMAX_LOGI("IsAnimating: ") << std::to_string(is_animating);
  }
  is_animating_ = is_animating;
}

bool AnimaXElement::IsDestroyed() const {
  return js_destroyed_ || gpu_destroyed_;
}

}  // namespace animax
}  // namespace lynx
