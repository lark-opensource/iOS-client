//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_DETECTOR_H_
#define KRYPTON_EFFECT_DETECTOR_H_

#include <string>

#include "canvas/canvas_image_source.h"
#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {

using piper::ImplBase;

class EffectDetector : public ImplBase {
 public:
  EffectDetector(std::string type) : type_(type) {}

  virtual Napi::ArrayBuffer Detect(CanvasImageSource* image_source) {
    return Napi::ArrayBuffer::New(Env(), 0);
  }

 protected:
  std::string type_;
};

}  // namespace canvas
}  // namespace lynx

#endif /* KRYPTON_EFFECT_DETECTOR_H_ */
