// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_BRIDGE_ANIMAX_ELEMENT_H_
#define ANIMAX_BRIDGE_ANIMAX_ELEMENT_H_

#include <functional>
#include <memory>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "animax/animator/value_animator_listener.h"
#include "animax/bridge/animax_event.h"
#include "animax/resource/composition_fetcher.h"
#include "canvas/canvas_app.h"

namespace lynx {
namespace canvas {
class CanvasApp;
}  // namespace canvas
}  // namespace lynx

namespace lynx {
namespace animax {
class CompositionModel;
class CompositionLayer;
class AnimaXOnScreenSurface;
class ValueAnimator;
class CountDownEvent;
class Canvas;
class Surface;

class AnimaXElement : public std::enable_shared_from_this<AnimaXElement>,
                      public ValueAnimatorListener,
                      public lynx::canvas::AppShowStatusObserver {
 public:
  /**
   * Constructor.
   * Make sure managing AnimaXElement by std::shared_ptr, since AnimaXElement is
   * derived from std::enable_shared_from_this<AnimaXElement>.
   * @param canvas_app CanvasApp shouldn't be nullptr.
   * @param scale      screen scale.
   */
  AnimaXElement(std::shared_ptr<lynx::canvas::CanvasApp> canvas_app,
                float scale);
  /**
   * Destructor.
   * DON'T FORGET TO CALL Destroy().
   */
  ~AnimaXElement() override;

  /**
   * Add listener to inner event of AnimaXElement.
   * If you want to listen Event, you should call this before
   * using AnimaXElement. It doesn't matter calling this before or after Init().
   * @param listener listener to inner event of AnimaXElement.
   */
  void AddEventListener(EventListener listener);
  /**
   * Init the AnimaXElement.
   * You should always call this before using AnimaXElement.
   */
  void Init();
  /**
   * Destroy all resource of AnimaXElement.
   * You should always call this if you don't use AnimaXElement anymore.
   */
  void Destroy();

  /**
   * Setup the onscreen surface.
   * main thread only.
   */
  void OnSurfaceCreated(float width, float height,
                        std::unique_ptr<lynx::canvas::Surface> surface);
  /**
   * Notify onscreen surface change its size.
   * main thread only.
   * You should call this after OnSurfaceCreated.
   */
  void OnSurfaceChanged(float width, float height);

  void SetSrc(const std::string &src);
  void SetSrcPolyfill(std::unordered_map<std::string, std::string> &polyfill);
  void SetJson(const char *json);
  void SetJson(std::string &&json);
  void SetLoop(const bool loop);
  void SetLoopCount(const int32_t loop_count);
  void SetAutoReverse(const bool auto_reverse);
  void SetSpeed(const double speed);
  void SetProgress(const double progress);
  void SetAutoplay(const bool autoplay);
  void SetStartFrame(const double start_frame);
  void SetEndFrame(const double end_frame);
  void SetKeepLastFrame(const bool keep_last_frame);
  void SetFpsEventInterval(const long interval);
  /**
   * Describe how to show the animation when the size of the animation and of
   * the onscreen surface aren't match.
   */
  enum class ObjectFit : uint8_t {
    kCenter = 0,  // animation won't be resized, and the animation will be
                  // placed on the center of the onscreen surface.
    kCover,  // animation will be proportional scaled. one of the animation side
             // will be scaled to match the onscreen surface, and the other will
             // greater than the onscreen surface. Some parts of animation may
             // be invisible.
    kContain,  // animation will be proportional scaled. one of the animation
               // side will be scaled to match the onscreen surface, and the
               // other will less than the onscreen surface. It looks like the
               // onscreen surface contains the animation.
  };
  void SetObjectFit(const ObjectFit object_fit);
  void Play();
  void Pause();
  void Resume();
  void Stop();
  void Seek(double frame);
  void SubscribeUpdateEvent(int32_t frame);
  void UnsubscribeUpdateEvent(int32_t frame);

  /**
   * Animation ID.
   * js thread only.
   * Every time you call Play() will change animation ID.
   * @return animation ID.
   */
  std::string GetAnimationID();
  /**
   * Current frame of current animation.
   * js thread only.
   * @return current frame.
   */
  double GetCurrentFrame();
  /**
   * Total frame of current animation.
   * js thread only.
   * @return total frame.
   */
  float GetTotalFrame();
  /**
   * Current loop index of current animation.
   * js thread only.
   * @return current loop index, counting from 0.
   */
  int32_t GetLoopIndex();
  /**
   * Total time of current animation in microsecond.
   * js thread only.
   * @return total time of current animation in microsecond.
   */
  double GetDurationMs();
  /**
   * Whether the animation is playing or not.
   * js thread only.
   * @return true if the animation is playing.
   */
  bool IsAnimating();

  std::unordered_map<std::string, double> GetPerfMetrics();
  PerformanceRecord &GetRecord();

  void OnStart() override;
  void OnProgress(double progress, double current_frame) override;
  void OnNewLoop(int32_t current_loop) override;
  void OnEnd() override;
  void OnAppEnterForeground() override;
  void OnAppEnterBackground() override;

  void RunOnGPUThread(std::function<void(AnimaXElement &)> func,
                      bool strong_element_ref = false);
  void RunOnJSThread(std::function<void(AnimaXElement &)> func,
                     bool strong_element_ref = false);

  void NotifyEvent(const Event event, IEventParams *params = nullptr);

 private:
  void ParseAndStartAnimationIfNeeded(const char *json, size_t length,
                                      int32_t src_index);
  void StartAnimationIfNeeded();
  void StartAnimation();
  void UpdateProperties();
  void UpdateAnimationID();
  void PlayInternal();
  void SetIsAnimating(const bool is_animating);
  void ResizeCanvas(Canvas &canvas);
  bool IsDestroyed() const;

  std::weak_ptr<lynx::canvas::CanvasApp> canvas_app_;
  std::unique_ptr<CountDownEvent> count_down_event_;

  fml::RefPtr<fml::TaskRunner> gpu_task_runner_;
  fml::RefPtr<fml::TaskRunner> js_task_runner_;

  // js thread only
  std::vector<EventListener> event_listeners_;
  std::shared_ptr<ValueAnimator> value_animator_;
  std::shared_ptr<CompositionFetcher> fetcher_;
  std::unordered_set<int32_t> subscribed_frames_;

  // gpu thread only
  std::unique_ptr<AnimaXOnScreenSurface> onscreen_surface_;
  std::unique_ptr<Surface> offscreen_surface_;
  std::shared_ptr<CompositionModel> model_;
  std::unique_ptr<CompositionLayer> layer_;

  // multi thread
  std::shared_ptr<PerformanceRecord> record_ =
      std::make_shared<PerformanceRecord>();

  float width_ = 0.f;
  float height_ = 0.f;
  float scale_ = 1.f;

  ObjectFit object_fit_ = ObjectFit::kContain;

  std::atomic<bool> js_destroyed_ = false;
  std::atomic<bool> gpu_destroyed_ = false;
  std::atomic<bool> surface_created_ = false;
  std::atomic<int32_t> current_src_index_ = 0;

  float start_frame_ = 0.f;
  float end_frame_ = 0.f;
  double duration_ms_ = 0.0;
  int32_t model_width_ = 0;
  int32_t model_height_ = 0;
  double current_frame_ = 0.0;
  int32_t current_loop_ = 0;
  bool is_animating_ = false;

  int32_t play_count_ = 0;
  std::string animation_id_;
  std::string current_src_;

  bool loop_ = false;
  int32_t loop_count_ = 1;
  bool keep_last_frame_ = true;
  bool autoplay_ = true;
  double user_start_frame_ = 0.0;
  double user_end_frame_ = -1.0;
  double user_progress_ = 0.0;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_BRIDGE_ANIMAX_ELEMENT_H_
