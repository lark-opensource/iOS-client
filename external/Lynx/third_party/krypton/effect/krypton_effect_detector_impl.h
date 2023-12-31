//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_DETECTOR_IMPL_H_
#define KRYPTON_EFFECT_DETECTOR_IMPL_H_

#include <mutex>

#include "canvas/base/data_holder.h"
#include "canvas/instance_guard.h"
#include "canvas/texture_source.h"
#include "effect/krypton_effect_detector.h"
#include "krypton_effect_video_context.h"
#include "shell/lynx_actor.h"

namespace lynx {
namespace canvas {

class EffectDetectorImpl : public EffectDetector {
 public:
  EffectDetectorImpl(std::string type) : EffectDetector(type) {}

  Napi::ArrayBuffer Detect(CanvasImageSource* image_source) override;

 private:
  std::shared_ptr<InstanceGuard<EffectDetectorImpl>> instance_guard_{nullptr};
  std::unique_ptr<DataHolder> detect_result_{nullptr};
  std::shared_ptr<effect::EffectDetectResult> shared_mem_{nullptr};

  bool DoDetect(uint32_t type, uint32_t size,
                std::shared_ptr<shell::LynxActor<TextureSource>> external_tex);
};

}  // namespace canvas
}  // namespace lynx

#endif /* KRYPTON_EFFECT_DETECTOR_IMPL_H_ */
