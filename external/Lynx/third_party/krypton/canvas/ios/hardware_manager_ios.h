// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_IOS_HARDWARE_MANAGER_IOS_H_
#define CANVAS_IOS_HARDWARE_MANAGER_IOS_H_

#include "canvas/hardware_manager.h"

@class CMMotionManager;

namespace lynx {
namespace canvas {

class HardwareManagerIOS : public HardwareManager {
 public:
  HardwareManagerIOS();
  ~HardwareManagerIOS() override;

  // Gyroscope
  void StartMonitorGyroscope(int frequency) override;
  void StopMonitorGyroscope() override;

  double GetGyroscopeDataX() override;
  double GetGyroscopeDataY() override;
  double GetGyroscopeDataZ() override;
  double GetGyroscopeDataRoll() override;
  double GetGyroscopeDataPitch() override;
  double GetGyroscopeDataYaw() override;

 private:
  CMMotionManager* motion_manager_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_IOS_HARDWARE_MANAGER_IOS_H_
