//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_PLATFORM_CAMERA_OPTION_H_
#define CANVAS_PLATFORM_CAMERA_OPTION_H_

namespace lynx {
namespace canvas {

enum EffectAlgorithms {
  kEffectNone = 0,
  kEffectHand = 1 << 1,
  kEffectFace = 1 << 2,
  kEffectBeautify = 1 << 3,
  kEffectSkeleton = 1 << 4,
};

struct CameraOption {
  uint32_t effect_algorithms;
  std::string resolution, face_mode;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_PLATFORM_CAMERA_OPTION_H_
