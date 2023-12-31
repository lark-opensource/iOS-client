// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/hardware_manager.h"

namespace lynx {
namespace canvas {

void HardwareManager::StartMonitorGyroscope(uintptr_t id, int freq) {
  std::lock_guard<std::mutex> lock(gd_.mutex_);
  bool empty = gd_.ids_.empty();
  gd_.ids_.insert(id);

  static constexpr int MIN_FREQUENCY = 16;
  if (freq < MIN_FREQUENCY) {
    freq = MIN_FREQUENCY;
  }
  if (empty) {
    gd_.frequency_ = freq;
    StartMonitorGyroscope(freq);
  } else {
    if (gd_.frequency_ > freq) {
      gd_.frequency_ = freq;
      StopMonitorGyroscope();
      StartMonitorGyroscope(freq);
    }
  }
}

void HardwareManager::StopMonitorGyroscope(uintptr_t id) {
  std::lock_guard<std::mutex> lock(gd_.mutex_);
  gd_.ids_.erase(id);
  if (gd_.ids_.empty()) {
    gd_.frequency_ = 0;
    StopMonitorGyroscope();
  }
}

void HardwareManager::NotifyGyroscopeData(float x, float y, float z,
                                          int64_t timestamp) {
  if (timestamp == 0) {
    return;
  }
  gd_.x_ = x;
  gd_.y_ = y;
  gd_.z_ = z;
  gd_.timestamp_ = timestamp;
}

void HardwareManager::NotifyOrientationData(float roll, float pitch, float yaw,
                                            int64_t timestamp) {
  if (timestamp == 0) {
    return;
  }
  gd_.roll_ = roll;
  gd_.pitch_ = pitch;
  gd_.yaw_ = yaw;
  gd_.timestamp_ = timestamp;
}

}  // namespace canvas
}  // namespace lynx
