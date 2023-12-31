// Copyright 2021 The Lynx Authors. All rights reserved.

#include "media_stream.h"

#if ENABLE_KRYPTON_EFFECT
#include "effect/krypton_effect_helper.h"
#endif

namespace lynx {
namespace canvas {

MediaStream::MediaStream(Type type, std::unique_ptr<VideoContext> video_context)
    : video_context_(std::move(video_context)), type_(type) {}

void MediaStream::OnWrapped() {}

void MediaStream::SetBeautifyParam(float whiten, float smoothen,
                                   float enlarge_eye, float slim_face) {
#if ENABLE_KRYPTON_EFFECT
  if (!video_context_) {
    KRYPTON_LOGE("ignore set beautify param video context == nullptr");
    return;
  }

  if (!video_context_->CanDetect()) {
    KRYPTON_LOGE("ignore set beautify param video context can not detect");
    return;
  }

  EffectHelper::Instance().SetBeautifyParam(video_context_.get(), whiten,
                                            smoothen, enlarge_eye, slim_face);
#endif
}

}  // namespace canvas
}  // namespace lynx
