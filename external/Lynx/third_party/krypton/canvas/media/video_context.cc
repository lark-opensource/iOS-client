// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/media/video_context.h"

namespace lynx {
namespace canvas {

VideoContext::VideoContext(const std::shared_ptr<CanvasApp>& canvas_app)
    : canvas_app_(canvas_app) {}

void VideoContext::RegisterStateListener(StateListener listener) {
  state_listener_ = listener;
}

void VideoContext::NotifyState(State state) {
  if (!state_listener_) {
    return;
  }
  state_listener_(state);
}
}  // namespace canvas
}  // namespace lynx
