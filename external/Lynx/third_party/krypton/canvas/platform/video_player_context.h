// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_PLATFORM_VIDEO_PLAYER_CONTEXT_H_
#define CANVAS_PLATFORM_VIDEO_PLAYER_CONTEXT_H_

#include <functional>
#include <memory>

#include "canvas/base/macros.h"
#include "canvas/media/video_context.h"
#include "glue/canvas_runtime.h"
#include "shell/lynx_actor.h"

namespace lynx {
namespace canvas {

class VideoPlayerContext : public VideoContext {
 public:
  static std::unique_ptr<VideoPlayerContext> CreatePlayer(
      const std::shared_ptr<CanvasApp>& canvas_app,
      PlayerLoadOptions load_options);

  VideoPlayerContext(const std::shared_ptr<CanvasApp>& canvas_app);
  virtual ~VideoPlayerContext() = default;

  virtual void Load(const std::string& url) = 0;
  virtual double GetCurrentTime() = 0;
  virtual void SetCurrentTime(double time) = 0;
  virtual void SetVolume(double volume);
  virtual void SetLoop(bool loop);
  virtual bool GetLoop();
  virtual double GetDuration() = 0;
  double GetVolume();
  void SetMuted(bool muted);
  bool GetMuted();
  void SetAutoplay(bool autoplay) { autoplay_ = autoplay; }
  bool GetAutoplay() { return autoplay_; }
  double Timestamp() override { return GetCurrentTime(); }

 private:
  bool muted_{false};
  double volume_{1};
  double last_volume_{0};
  bool autoplay_{false};
  bool loop_{false};

  LYNX_CANVAS_DISALLOW_ASSIGN_COPY(VideoPlayerContext);
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_PLATFORM_VIDEO_PLAYER_CONTEXT_H_
