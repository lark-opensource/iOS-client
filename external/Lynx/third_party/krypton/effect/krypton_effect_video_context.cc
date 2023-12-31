//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "krypton_effect_video_context.h"

#include "canvas/platform/camera_option.h"
#include "krypton_effect.h"
#include "krypton_effect_resource_downloader.h"

namespace lynx {
namespace canvas {
namespace effect {

EffectVideoContext::EffectVideoContext(
    const std::shared_ptr<CanvasApp>& canvas_app,
    std::unique_ptr<VideoContext> video_impl, uint32_t algorithms)
    : VideoContext(canvas_app),
      algorithms_(algorithms),
      video_impl_(std::move(video_impl)) {
  KRYPTON_LOGI("EffectVideoContext construct");
  width_ = video_impl_->Width();
  height_ = video_impl_->Height();

  auto output = std::make_unique<EffectVideoOutput>(algorithms);

  face_info_res_ = output->GetSharedMemory(EffectAlgorithms::kEffectFace);
  hand_info_res_ = output->GetSharedMemory(EffectAlgorithms::kEffectHand);
  skeleton_info_res_ =
      output->GetSharedMemory(EffectAlgorithms::kEffectSkeleton);
  output_actor_ = std::make_shared<shell::LynxActor<TextureSource>>(
      std::move(output), canvas_app->gpu_task_runner());
  instance_guard_ = InstanceGuard<EffectVideoContext>::CreateSharedGuard(this);
}

EffectVideoContext::~EffectVideoContext() {
  if (output_actor_) {
    output_actor_->Act([](auto& impl) { impl = nullptr; });
  }
}

void EffectVideoContext::SetBeautifyParam(float whiten, float smoothen,
                                          float enlargeEye, float slimFace) {
  if (!(algorithms_ & kEffectBeautify)) {
    KRYPTON_LOGE("beautify not enabled");
    return;
  }

  output_actor_->Act([whiten, smoothen, enlargeEye, slimFace](auto& impl) {
    static_cast<EffectVideoOutput*>(impl.get())
        ->SetBeautifyParam(whiten, smoothen, enlargeEye, slimFace);
  });
}

void EffectVideoContext::Play() {
  video_impl_->Play();
  auto weak_guard =
      std::weak_ptr<InstanceGuard<EffectVideoContext>>(instance_guard_);
  output_actor_->Act([weak_guard](auto& impl) {
    auto instance = weak_guard.lock();
    if (!instance) {
      return;
    }
    auto output = static_cast<EffectVideoOutput*>(impl.get());
    output->InitOnGPU(instance->Get()->video_impl_->GetNewTextureSource());
    output->Play();
  });
}

void EffectVideoContext::Pause() {
  video_impl_->Pause();
  output_actor_->Act(
      [](auto& impl) { static_cast<EffectVideoOutput*>(impl.get())->Pause(); });
}

double EffectVideoContext::Timestamp() { return video_impl_->Timestamp(); }

std::shared_ptr<EffectDetectResult> EffectVideoContext::GetSharedMemory(
    uint32_t type) {
  switch (type) {
    case EffectAlgorithms::kEffectFace:
      return face_info_res_;
    case EffectAlgorithms::kEffectHand:
      return hand_info_res_;
    case EffectAlgorithms::kEffectSkeleton:
      return skeleton_info_res_;
  }

  return nullptr;
}

std::shared_ptr<shell::LynxActor<TextureSource>>
EffectVideoContext::GetNewTextureSource() {
  video_impl_->GetNewTextureSource();
  return output_actor_;
}

}  // namespace effect
}  // namespace canvas
}  // namespace lynx
