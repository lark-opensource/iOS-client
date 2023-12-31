// Copyright 2021 The Lynx Authors. All rights reserved.

#include "canvas/gyroscope.h"

#include "canvas/hardware_manager.h"

namespace lynx {
namespace canvas {

void Gyroscope::Start(double frequency) {
  HardwareManager::Instance()->StartMonitorGyroscope(
      reinterpret_cast<uintptr_t>(this), frequency);
}

Gyroscope::~Gyroscope() { Stop(); }

void Gyroscope::Stop() {
  HardwareManager::Instance()->StopMonitorGyroscope(
      reinterpret_cast<uintptr_t>(this));
}

double Gyroscope::GetX() {
  return HardwareManager::Instance()->GetGyroscopeDataX();
}
double Gyroscope::GetY() {
  return HardwareManager::Instance()->GetGyroscopeDataY();
}
double Gyroscope::GetZ() {
  return HardwareManager::Instance()->GetGyroscopeDataZ();
}
double Gyroscope::GetRoll() {
  return HardwareManager::Instance()->GetGyroscopeDataRoll();
}
double Gyroscope::GetPitch() {
  return HardwareManager::Instance()->GetGyroscopeDataPitch();
}
double Gyroscope::GetYaw() {
  return HardwareManager::Instance()->GetGyroscopeDataYaw();
}

}  // namespace canvas
}  // namespace lynx
