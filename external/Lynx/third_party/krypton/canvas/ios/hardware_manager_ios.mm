// Copyright 2021 The Lynx Authors. All rights reserved.

#include "hardware_manager_ios.h"
#include <CoreMotion/CoreMotion.h>
#include <new>
#include "base/no_destructor.h"

namespace lynx {
namespace canvas {

HardwareManager* HardwareManager::Instance() {
  static base::NoDestructor<HardwareManagerIOS> instance_;
  return instance_.get();
}

HardwareManagerIOS::HardwareManagerIOS() : HardwareManager() {
  motion_manager_ = [[CMMotionManager alloc] init];
}

HardwareManagerIOS::~HardwareManagerIOS() {}

void HardwareManagerIOS::StartMonitorGyroscope(int frequency) {
  motion_manager_.deviceMotionUpdateInterval = frequency * 0.001f;
  [motion_manager_ startDeviceMotionUpdates];
}

void HardwareManagerIOS::StopMonitorGyroscope() { [motion_manager_ stopDeviceMotionUpdates]; }

double HardwareManagerIOS::GetGyroscopeDataX() {
  return motion_manager_.deviceMotion.rotationRate.x;
}

double HardwareManagerIOS::GetGyroscopeDataY() {
  return motion_manager_.deviceMotion.rotationRate.y;
}

double HardwareManagerIOS::GetGyroscopeDataZ() {
  return motion_manager_.deviceMotion.rotationRate.z;
}

double HardwareManagerIOS::GetGyroscopeDataRoll() {
  return motion_manager_.deviceMotion.attitude.roll;
}

double HardwareManagerIOS::GetGyroscopeDataPitch() {
  return motion_manager_.deviceMotion.attitude.pitch;
}

double HardwareManagerIOS::GetGyroscopeDataYaw() {
  return motion_manager_.deviceMotion.attitude.yaw;
}

}  // namespace canvas
}  // namespace lynx
