// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_ANIMATOR_VALUE_ANIMATOR_H_
#define ANIMAX_ANIMATOR_VALUE_ANIMATOR_H_

#include <memory>

#include "animax/animator/value_animator_listener.h"
#include "shell/lynx_actor.h"

namespace lynx {
namespace canvas {
class CanvasRuntime;
}  // namespace canvas
}  // namespace lynx

namespace lynx {
namespace animax {

class ValueAnimator : public std::enable_shared_from_this<ValueAnimator> {
 public:
  ValueAnimator(
      std::shared_ptr<lynx::shell::LynxActor<lynx::canvas::CanvasRuntime>>
          canvas_runtime,
      std::shared_ptr<ValueAnimatorListener> listener);
  ~ValueAnimator() = default;

  /**
   * Set loop count for current animation. the default value is 1.
   * @param loop_count a positive number or zero, zero means loop forever. a
   * negative number will be discarded.
   */
  void SetLoopCount(const int32_t loop_count);
  /**
   * Set auto reverse for the even loop. the default value is false.
   * If true, the even loop(counting from 1) will be played from last frame to
   * first frame; the odd loop will be played as usual.
   * @param auto_reverse whether enable auto reverse.
   */
  void SetAutoReverse(const bool auto_reverse);
  /**
   * Set the speed of animation. the default value is 1.
   * @param speed a relative value. Can be positive, negative and 0.
   */
  void SetSpeed(const double speed);
  /**
   * Set origin start frame, end frame and frame rate.
   * These values are corresponding to ip, op, fr of lottie json file.
   * @param origin_start_frame ip of lottie json file, means In Point.
   * @param origin_end_frame   op of lottie json file, means Out Point.
   * @param frame_rate         fr of lottie json file, means frame rate.
   */
  void SetOriginFrameProperty(const double origin_start_frame,
                              const double origin_end_frame,
                              const double frame_rate);
  /**
   * Set play segments of animation.
   * You should call this method after calling SetOriginFrameProperty. the
   * default start frame is the origin start frame, the default end frame is the
   * origin end frame.
   * @param start_frame start frame of animation, a value less than origin start
   * frame will be converted to origin start frame.
   * @param end_frame   end frame of animation, a value greater than origin end
   * frame will be converted to origin end frame; -1.0 will be converted to
   * origin end frame too.
   */
  void SetPlaySegments(double start_frame, double end_frame);
  /**
   * Whether the animation is playing.
   * @return true if the inner state is kPlaying.
   */
  bool IsAnimating();
  /**
   * Whether origin start frame, origin end frame and frame rate set by
   * SetOriginFrameProperty are valid. You can call this method after
   * SetOriginFrameProperty.
   * @return true if origin start frame, origin end frame and frame rate are
   * valid.
   */
  bool CanPlay();
  /**
   * Play animation.
   * You can call Seek before call Play. a common usage is Seek(0, true, true)
   * followed by Play(), animation will be played from the first frame.
   */
  void Play();
  /**
   * Pause animation.
   * You can call Pause after Play.
   */
  void Pause();
  /**
   * Resume animation from Pause.
   * You can call Resume after Pause. a Resume after Stop will do nothing.
   */
  void Resume();
  /**
   * Stop animation.
   * You can call Stop after Play, Pause, Resume. If you want to play again, you
   * can only call Play.
   */
  void Stop();
  /**
   * Seek to a frame or a progress.
   * @param value            if is_frame is true, value is a frame which will be
   * applied without any change; if is_frame is false, value is a progress
   * between origin start frame and origin end frame.
   * @param is_frame         suggest whether value is a frame or a progress.
   * @param reset_loop_count whether reset inner loop count to 0 which is used
   * to compare with total loop count.
   */
  void Seek(double value, bool is_frame, bool reset_loop_count = false);
  /**
   * Destroy this.
   * You should call this if you won't use this anymore.
   */
  void Destroy();

  void OnAppEnterForeground();
  void OnAppEnterBackground();

 private:
  enum class State : uint8_t {
    kUnknown = 0,
    kInited,
    kPlaying,
    kPaused,
    kAutoPaused,
  };
  void SetupOnFrame();
  void OnFrame(double current_time_ms);
  double GetProgress() const;
  bool IsLoopForever();
  void ResetProperty();

  std::shared_ptr<lynx::shell::LynxActor<lynx::canvas::CanvasRuntime>>
      canvas_runtime_;
  std::weak_ptr<ValueAnimatorListener> listener_;
  int32_t loop_count_ = 1;
  bool auto_reverse_ = false;
  double speed_ = 1.0;
  double last_time_ms_ = -1.0;
  int32_t current_loop_count_ = 0;
  double current_frame_ = 0.0;
  bool first_frame_ = false;
  double start_frame_ = 0.0;
  double end_frame_ = 0.0;
  double frame_rate_ = 0.0;
  double origin_start_frame_ = 0.0;
  double origin_end_frame_ = 0.0;
  State state_ = State::kUnknown;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_ANIMATOR_VALUE_ANIMATOR_H_
