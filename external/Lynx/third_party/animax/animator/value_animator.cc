
#include "animax/animator/value_animator.h"

#include <cmath>

#include "animax/base/log.h"
#include "animax/base/thread_assert.h"
#include "glue/canvas_runtime.h"

namespace lynx {
namespace animax {

ValueAnimator::ValueAnimator(
    std::shared_ptr<lynx::shell::LynxActor<lynx::canvas::CanvasRuntime>>
        canvas_runtime,
    std::shared_ptr<ValueAnimatorListener> listener)
    : canvas_runtime_(canvas_runtime), listener_(listener) {
  DCHECK(canvas_runtime_);
  state_ = State::kInited;
}

void ValueAnimator::SetupOnFrame() {
  ThreadAssert::Assert(ThreadAssert::Type::kJS);
  canvas_runtime_->Act(
      [this](std::unique_ptr<lynx::canvas::CanvasRuntime> &runtime) {
        std::weak_ptr<ValueAnimator> weak_value_animator =
            this->shared_from_this();
        runtime->AsyncRequestVSync(
            reinterpret_cast<uintptr_t>(this),
            [weak_value_animator](int64_t frame_start, int64_t frame_end) {
              std::shared_ptr<ValueAnimator> value_animator =
                  weak_value_animator.lock();
              if (!value_animator) {
                return;
              }
              value_animator->SetupOnFrame();
              value_animator->OnFrame(static_cast<double>(frame_start) / 1e6);
            });
      });
}

void ValueAnimator::OnFrame(double current_time_ms) {
  if (State::kPlaying != state_) {
    return;
  }
  bool start = false;
  bool end = false;
  bool new_loop = false;
  if (last_time_ms_ == -1.0) {
    last_time_ms_ = current_time_ms;
  }
  if (first_frame_) {
    first_frame_ = false;
    start = true;
  }

  current_frame_ +=
      speed_ * frame_rate_ * (current_time_ms - last_time_ms_) / 1000.0;
  last_time_ms_ = current_time_ms;

  if (current_frame_ > end_frame_) {
    if (!IsLoopForever() && current_loop_count_ >= loop_count_ - 1) {
      current_frame_ = end_frame_;
      end = true;
    } else {
      ++current_loop_count_;
      new_loop = true;
      current_frame_ = start_frame_ + std::fmod(current_frame_ - start_frame_,
                                                end_frame_ - start_frame_);
    }
  } else if (current_frame_ < start_frame_) {
    if (!IsLoopForever() && current_loop_count_ <= 0) {
      current_frame_ = start_frame_;
      end = true;
    } else {
      --current_loop_count_;
      new_loop = true;
      current_frame_ = end_frame_ + std::fmod(current_frame_ - start_frame_,
                                              end_frame_ - start_frame_);
    }
  }

  auto listener = listener_.lock();
  bool has_listener = listener.get();
  if (start && has_listener) {
    listener->OnStart();
  }
  if (new_loop && has_listener) {
    listener->OnNewLoop(current_loop_count_);
  }
  if (has_listener) {
    double progress = GetProgress();
    listener->OnProgress(progress, current_frame_);
  }
  if (end) {
    Stop();
    if (has_listener) {
      listener->OnEnd();
    }
  }
}

double ValueAnimator::GetProgress() const {
  return (auto_reverse_ && (current_loop_count_ & 1))
             ? (end_frame_ - (current_frame_ - start_frame_)) /
                   (origin_end_frame_ - origin_start_frame_)
             : (current_frame_ - origin_start_frame_) /
                   (origin_end_frame_ - origin_start_frame_);
}

bool ValueAnimator::IsLoopForever() { return loop_count_ == 0.0; }

void ValueAnimator::ResetProperty() {
  loop_count_ = 1;
  auto_reverse_ = false;
  speed_ = 1.0;
  last_time_ms_ = -1.0;
  current_frame_ = 0.0;
  current_loop_count_ = 0;
  first_frame_ = false;
}

bool ValueAnimator::IsAnimating() { return State::kPlaying == state_; }

bool ValueAnimator::CanPlay() {
  return origin_end_frame_ > origin_start_frame_ && frame_rate_ > 0;
}

void ValueAnimator::SetPlaySegments(double start_frame, double end_frame) {
  if (!CanPlay()) {
    ANIMAX_LOGE(
        "ValueAnimator: Can't SetPlaySegments before SetOriginFrameProperty");
    return;
  }
  if (State::kInited != state_) {
    ANIMAX_LOGE("ValueAnimator: Can't SetPlaySegments after Play");
    return;
  }
  if (start_frame < origin_start_frame_) {
    start_frame = origin_start_frame_;
  } else if (start_frame > origin_end_frame_) {
    start_frame = origin_end_frame_;
  }

  if (end_frame == -1.0 || end_frame > origin_end_frame_) {
    end_frame = origin_end_frame_;
  } else if (end_frame < origin_start_frame_) {
    end_frame = origin_start_frame_;
  }

  start_frame_ = start_frame;
  end_frame_ = end_frame;
}

void ValueAnimator::Play() {
  if (State::kUnknown == state_ || !CanPlay()) {
    return;
  }
  if (start_frame_ >= end_frame_) {
    return;
  }

  current_loop_count_ = 0;
  state_ = State::kPlaying;
  last_time_ms_ = -1.0;
  first_frame_ = true;
  SetupOnFrame();
}

void ValueAnimator::Pause() {
  if (State::kPlaying == state_ || State::kAutoPaused == state_) {
    state_ = State::kPaused;
  }
}

void ValueAnimator::Resume() {
  if (State::kPaused == state_) {
    state_ = State::kPlaying;
    last_time_ms_ = -1.0;
    SetupOnFrame();
  }
}

void ValueAnimator::Stop() {
  if (State::kUnknown != state_) {
    state_ = State::kInited;
  }
}

void ValueAnimator::Seek(double value, bool is_frame, bool reset_loop_count) {
  if (State::kUnknown == state_ || !CanPlay()) {
    ANIMAX_LOGE("ValueAnimator: Seek before CanPlay");
    return;
  }
  if (start_frame_ >= end_frame_) {
    ANIMAX_LOGE("ValueAnimator: Invalid start_frame_ and end_frame_ in Seek");
    return;
  }
  if (reset_loop_count) {
    current_loop_count_ = 0;
  }
  current_frame_ = is_frame
                       ? value
                       : (origin_start_frame_ +
                          value * (origin_end_frame_ - origin_start_frame_));
  if (current_frame_ < start_frame_) {
    current_frame_ = start_frame_;
  } else if (current_frame_ > end_frame_) {
    current_frame_ = end_frame_;
  }

  auto listener = listener_.lock();
  if (listener) {
    listener->OnProgress(GetProgress(), current_frame_);
  }
}

void ValueAnimator::Destroy() {
  state_ = State::kUnknown;
  ResetProperty();
}

void ValueAnimator::OnAppEnterForeground() {
  ANIMAX_LOGI("ValueAnimator::OnAppEnterForeground");
  if (State::kAutoPaused == state_) {
    state_ = State::kPlaying;
    last_time_ms_ = -1.0;
    SetupOnFrame();
  }
}

void ValueAnimator::OnAppEnterBackground() {
  ANIMAX_LOGI("ValueAnimator::OnAppEnterBackground");
  if (State::kPlaying == state_) {
    state_ = State::kAutoPaused;
  }
}

// TEST: 0, 1, 2
void ValueAnimator::SetLoopCount(const int32_t loop_count) {
  if (loop_count < 0) {
    ANIMAX_LOGW("ValueAnimator::SetLoopCount less than 0: ") << loop_count;
    return;
  }
  loop_count_ = loop_count;
}

// TEST: true+loopCont=1, true+loopCont=2
void ValueAnimator::SetAutoReverse(const bool auto_reverse) {
  auto_reverse_ = auto_reverse;
}

// TEST: 0.5, 2
void ValueAnimator::SetSpeed(const double speed) { speed_ = speed; }

// progress
// TEST: 0.5, 1, 0.5+speed=0, 0.5+speed=-1

// start-frame, end-frame
// TEST: 0,-1
// TEST: 15,45
// TEST: 15,45,loop
// TEST: 15,45,loop,progress=0.5
// TEST: 15,45,loop,progress=0.5,auto-reverse

void ValueAnimator::SetOriginFrameProperty(const double origin_start_frame,
                                           const double origin_end_frame,
                                           const double frame_rate) {
  origin_start_frame_ = origin_start_frame;
  origin_end_frame_ = origin_end_frame;
  frame_rate_ = frame_rate;

  SetPlaySegments(origin_start_frame, origin_end_frame);
}

}  // namespace animax
}  // namespace lynx
