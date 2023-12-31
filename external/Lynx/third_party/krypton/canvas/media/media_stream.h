// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_MEDIA_MEDIA_STREAM_H_
#define CANVAS_MEDIA_MEDIA_STREAM_H_

#include <memory>

#include "canvas/media/video_context.h"
#include "jsbridge/napi/base.h"
#include "shell/lynx_actor.h"

namespace lynx {
namespace canvas {

using piper::ImplBase;

class MediaStream : public ImplBase {
 public:
  enum Type { Unknow, Camera, Microphone };

  MediaStream(Type type, std::unique_ptr<VideoContext> video_context);

  Type GetType() { return type_; }

  void OnWrapped() override;

  std::shared_ptr<VideoContext> GetVideoContext() { return video_context_; }

  void SetBeautifyParam(float whiten, float smoothen, float enlarge_eye,
                        float slim_face);

 private:
  std::shared_ptr<VideoContext> video_context_;
  Type type_{Unknow};
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_MEDIA_MEDIA_STREAM_H_
