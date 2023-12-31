// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GYROSCOPE_H_
#define CANVAS_GYROSCOPE_H_

#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class Gyroscope : public ImplBase {
 public:
  static std::unique_ptr<Gyroscope> Create() {
    return std::unique_ptr<Gyroscope>(new Gyroscope());
  }

  Gyroscope() = default;

  Gyroscope(const Gyroscope&) = delete;

  ~Gyroscope() override;

  void Start(double frequency);
  void Stop();

  double GetX();
  double GetY();
  double GetZ();
  double GetRoll();
  double GetPitch();
  double GetYaw();
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GYROSCOPE_H_
