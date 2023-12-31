//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "krypton_effect_detector_impl.h"

#include "canvas/base/log.h"
#include "canvas/platform/camera_option.h"
#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace canvas {

Napi::ArrayBuffer EffectDetectorImpl::Detect(CanvasImageSource* image_source) {
  if (!image_source->IsVideoElement() || !image_source->GetTextureSource()) {
    // TODO support image, canvas
    Napi::TypeError::New(Env(), "only support detect camera now")
        .ThrowAsJavaScriptException();
    return Napi::ArrayBuffer::New(Env(), 0);
  }

  if (!image_source->CanDetect()) {
    Napi::TypeError::New(Env(), "image source not enable effect")
        .ThrowAsJavaScriptException();
    return Napi::ArrayBuffer::New(Env(), 0);
  }

  if (type_ == "face") {
    DoDetect(EffectAlgorithms::kEffectFace, sizeof(effect::FaceInfo),
             image_source->GetTextureSource());
  } else if (type_ == "skeleton") {
    DoDetect(EffectAlgorithms::kEffectSkeleton, sizeof(effect::SkeletonInfo),
             image_source->GetTextureSource());
  } else if (type_ == "hand") {
    DoDetect(EffectAlgorithms::kEffectHand, sizeof(effect::HandInfo),
             image_source->GetTextureSource());
  } else {
    Napi::TypeError::New(Env(), "do detect failed")
        .ThrowAsJavaScriptException();
    return Napi::ArrayBuffer::New(Env(), 0);
  }

  return Napi::ArrayBuffer::New(
      Env(), (void*)detect_result_->Data(), detect_result_->Size(),
      [](napi_env env, void* napi_data, void* a) {
        // do not free
      },
      nullptr);
}

bool EffectDetectorImpl::DoDetect(
    uint32_t type, uint32_t size,
    std::shared_ptr<shell::LynxActor<TextureSource>> external_tex) {
  if (!instance_guard_) {
    instance_guard_ =
        InstanceGuard<EffectDetectorImpl>::CreateSharedGuard(this);
  }

  auto weak_guard =
      std::weak_ptr<InstanceGuard<EffectDetectorImpl>>(instance_guard_);
  external_tex->Act([type, weak_guard](auto& impl) {
    auto instance = weak_guard.lock();
    if (!instance) {
      return;
    }

    auto effect_video_context =
        static_cast<effect::EffectVideoOutput*>(impl.get());
    instance->Get()->shared_mem_ = effect_video_context->GetSharedMemory(type);
  });

  if (!detect_result_) {
    detect_result_ = DataHolder::MakeWithMalloc(size);
  }

  if (shared_mem_) {
    shared_mem_->CopyTo(detect_result_);
  }

  return true;
}

}  // namespace canvas
}  // namespace lynx
