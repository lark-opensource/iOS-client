// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_HARDWARE_MANAGER_H_
#define CANVAS_HARDWARE_MANAGER_H_

#include <cstdint>
#include <mutex>
#include <set>

namespace lynx {
namespace canvas {

class HardwareManager {
 public:
  HardwareManager() = default;
  virtual ~HardwareManager() = default;

  // implemented in platform-specific derived subclass
  static HardwareManager* Instance();

  void StartMonitorGyroscope(uintptr_t id, int frequency);
  void StopMonitorGyroscope(uintptr_t id);

  virtual double GetGyroscopeDataX() { return gd_.x_; }
  virtual double GetGyroscopeDataY() { return gd_.y_; }
  virtual double GetGyroscopeDataZ() { return gd_.z_; }
  virtual double GetGyroscopeDataRoll() { return gd_.roll_; }
  virtual double GetGyroscopeDataPitch() { return gd_.pitch_; }
  virtual double GetGyroscopeDataYaw() { return gd_.yaw_; }

  void NotifyGyroscopeData(float x, float y, float z, int64_t timestamp);
  void NotifyOrientationData(float roll, float pitch, float yaw,
                             int64_t timestamp);

 protected:
  virtual void StartMonitorGyroscope(int frequency) = 0;
  virtual void StopMonitorGyroscope() = 0;

 private:
  HardwareManager(const HardwareManager&) = delete;
  HardwareManager& operator==(const HardwareManager&) = delete;

  struct GyroscopeData {
    double x_, y_, z_, roll_, pitch_, yaw_;
    int64_t timestamp_{0};
    int32_t frequency_{0};
    std::set<uintptr_t> ids_;
    std::mutex mutex_;
  } gd_{0};
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_HARDWARE_MANAGER_H_
