// Copyright 2021 The Lynx Authors. All rights reserved.

#include <functional>
#include <memory>

#include "base/base_export.h"
#include "canvas/canvas_app.h"
#include "canvas/gpu/frame_buffer.h"
#include "canvas/texture_source.h"

#ifndef CANVAS_MEDIA_VIDEO_CONTEXT_H_
#define CANVAS_MEDIA_VIDEO_CONTEXT_H_

namespace lynx {
namespace canvas {
class BASE_EXPORT VideoContext {
 public:
  enum class State {
    kCanPlay = 0,
    kEnd = 2,
    kError = 3,
    kCanDraw = 4,
    kSeekEnd = 5,
    kStartPlay = 6,
    kPaused = 7,
  };

  struct PlayerLoadOptions {
    bool use_custom_player{false};
  };

  VideoContext(const std::shared_ptr<CanvasApp>& canvas_app);
  virtual ~VideoContext() = default;

  uint32_t Width() { return width_; }
  uint32_t Height() { return height_; }

  virtual void Play() = 0;

  virtual void Pause() = 0;

  virtual double Timestamp() = 0;

  virtual std::shared_ptr<shell::LynxActor<TextureSource>>
  GetNewTextureSource() = 0;

  virtual bool CanDetect() { return false; }

  using StateListener = std::function<void(State)>;
  void RegisterStateListener(StateListener listener);

  void NotifyState(State state);

 protected:
  uint32_t width_{0}, height_{0};
  StateListener state_listener_;

  /// TODO: replace by LynxKryptonContext
  std::shared_ptr<CanvasApp> canvas_app_{nullptr};
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_MEDIA_VIDEO_CONTEXT_H_
