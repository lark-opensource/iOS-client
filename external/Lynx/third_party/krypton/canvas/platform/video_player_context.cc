// Copyright 2021 The Lynx Authors. All rights reserved.

#include "video_player_context.h"

namespace lynx {
namespace canvas {

VideoPlayerContext::VideoPlayerContext(
    const std::shared_ptr<CanvasApp>& canvas_app)
    : VideoContext(canvas_app) {}

void VideoPlayerContext::SetVolume(double volume) { volume_ = volume; }

double VideoPlayerContext::GetVolume() { return volume_; }

void VideoPlayerContext::SetMuted(bool muted) {
  if (muted != muted_) {
    if (muted) {
      last_volume_ = volume_;
      SetVolume(0);
    } else {
      SetVolume(last_volume_);
    }
  }
  muted_ = muted;
}

bool VideoPlayerContext::GetMuted() { return muted_; }

void VideoPlayerContext::SetLoop(bool loop) { loop_ = loop; }

bool VideoPlayerContext::GetLoop() { return loop_; }

}  // namespace canvas
}  // namespace lynx
