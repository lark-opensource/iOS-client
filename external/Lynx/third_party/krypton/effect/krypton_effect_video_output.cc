//  Copyright 2023 The Lynx Authors. All rights reserved.

#include "effect/krypton_effect_video_output.h"

#include "canvas/gpu/gl/gl_api.h"
#include "canvas/media/video_context.h"
#include "canvas/platform/camera_option.h"
#include "effect/krypton_effect_output_struct.h"
#ifdef OS_IOS
#include "canvas/platform/ios/pixel_buffer.h"
#elif OS_ANDROID
#include "canvas/platform/android/surface_texture_android.h"
#endif

namespace lynx {
namespace canvas {
namespace effect {

EffectVideoOutput::EffectVideoOutput(uint32_t algorithms)
    : algorithms_(algorithms) {
  face_info_res_ = std::make_shared<EffectDetectResult>(sizeof(FaceInfo));
  skeleton_info_res_ =
      std::make_shared<EffectDetectResult>(sizeof(SkeletonInfo));
  hand_info_res_ = std::make_shared<EffectDetectResult>(sizeof(HandInfo));
}

EffectVideoOutput::~EffectVideoOutput() {}

void EffectVideoOutput::InitOnGPU(
    std::shared_ptr<shell::LynxActor<TextureSource>> texture_source_actor) {
  texture_source_actor_ = texture_source_actor;
  auto texture_source = texture_source_actor->Impl();
  wrapper_ = std::make_unique<EffectWrapper>(
      texture_source->Width(), texture_source->Height(), algorithms_);
  wrapper_->Init();
  if (algorithms_ & kEffectBeautify) {
    wrapper_->ComposerSetMode(1, 0);
    wrapper_->ComposerSetNodes(nullptr, 2);
  }

  if (should_update_beautify_param_) {
    should_update_beautify_param_ = false;
    wrapper_->ComposerUpdateNode(nullptr, kEFFECT_TAG_WHITEN, whiten_);
    wrapper_->ComposerUpdateNode(nullptr, kEFFECT_TAG_BLUR, smoothen_);
    wrapper_->ComposerUpdateNode(nullptr, kEFFECT_TAG_EYE, enlargeEye_);
    wrapper_->ComposerUpdateNode(nullptr, kEFFECT_TAG_CHEEK, slimFace_);
  }
}

void EffectVideoOutput::SetBeautifyParam(float whiten, float smoothen,
                                         float enlargeEye, float slimFace) {
  if (!wrapper_) {
    should_update_beautify_param_ = true;
    whiten_ = whiten;
    smoothen_ = smoothen;
    enlargeEye_ = enlargeEye;
    slimFace_ = slimFace;
    return;
  }

  wrapper_->ComposerUpdateNode(nullptr, kEFFECT_TAG_WHITEN, whiten);
  wrapper_->ComposerUpdateNode(nullptr, kEFFECT_TAG_BLUR, smoothen);
  wrapper_->ComposerUpdateNode(nullptr, kEFFECT_TAG_EYE, enlargeEye);
  wrapper_->ComposerUpdateNode(nullptr, kEFFECT_TAG_CHEEK, slimFace);
}

void EffectVideoOutput::Play() { wrapper_->Resume(); }

void EffectVideoOutput::Pause() { wrapper_->Pause(); }

std::shared_ptr<EffectDetectResult> EffectVideoOutput::GetSharedMemory(
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

uint32_t EffectVideoOutput::reading_fbo() {
  if (algorithms_ & EffectAlgorithms::kEffectBeautify) {
    processed_fbo_ = std::make_unique<Framebuffer>(processed_tex_->Texture());
    processed_fbo_->InitOnGPUIfNeed();
    return processed_fbo_->Fbo();
  }

  fbo_ = std::make_unique<Framebuffer>(texture_);
  fbo_->InitOnGPUIfNeed();
  return fbo_->Fbo();
}

uint32_t EffectVideoOutput::Texture() {
  if (algorithms_ & EffectAlgorithms::kEffectBeautify) {
    return processed_tex_->Texture();
  }
  return texture_;
}

void EffectVideoOutput::UpdateTextureOrFramebufferOnGPU() {
  auto texture_source = texture_source_actor_->Impl();
  texture_source->UpdateTextureOrFramebufferOnGPU();

  uint32_t tex_dst = 0;
  if (algorithms_ & EffectAlgorithms::kEffectBeautify) {
    if (!processed_tex_) {
      processed_tex_ = std::make_unique<GLTexture>(texture_source->Width(),
                                                   texture_source->Height());
    }

    tex_dst = processed_tex_->Texture();
  }

#ifdef OS_IOS
  double ts = static_cast<PixelBuffer*>(texture_source)->GetTimestamp();
#elif OS_ANDROID
  double ts =
      static_cast<SurfaceTextureAndroid*>(texture_source)->GetTimestamp();
#endif
  texture_ = texture_source->Texture();
  wrapper_->ProcessTexture(texture_, tex_dst, BEF_CLOCKWISE_ROTATE_0, ts);

  if (algorithms_ & EffectAlgorithms::kEffectFace) {
    UpdateFaceDetectResult();
  }

  if (algorithms_ & EffectAlgorithms::kEffectSkeleton) {
    UpdateSkeletonDetectResult();
  }

  if (algorithms_ & EffectAlgorithms::kEffectHand) {
    UpdateHandDetectResult();
  }
}

void EffectVideoOutput::UpdateTextureSource(
    std::shared_ptr<shell::LynxActor<TextureSource>> texture_source_actor) {
  texture_source_actor_ = texture_source_actor;
}

void EffectVideoOutput::UpdateFaceDetectResult() {
  FaceInfo result;
  if (!wrapper_->GetFaceDetectResult(result)) {
    return;
  }

  face_info_res_->Write([&result](auto& data) {
    auto res = reinterpret_cast<FaceInfo*>(data->WritableData());
    memcpy(res, &result, sizeof(FaceInfo));
  });
}

void EffectVideoOutput::UpdateSkeletonDetectResult() {
  SkeletonInfo result;
  if (!wrapper_->GetSkeletonDetectResult(result)) {
    return;
  }

  skeleton_info_res_->Write([&result](auto& data) {
    auto res = reinterpret_cast<SkeletonInfo*>(data->WritableData());
    memcpy(res, &result, sizeof(SkeletonInfo));
  });
}

void EffectVideoOutput::UpdateHandDetectResult() {
  HandInfo result;
  if (!wrapper_->GetHandDetectResult(result)) {
    return;
  }

  hand_info_res_->Write([&result](auto& data) {
    auto res = reinterpret_cast<HandInfo*>(data->WritableData());
    memcpy(res, &result, sizeof(HandInfo));
  });
}

}  // namespace effect
}  // namespace canvas
}  // namespace lynx
