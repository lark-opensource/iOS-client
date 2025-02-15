// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_POWER_MONITOR_POWER_MONITOR_SOURCE_H_
#define BASE_POWER_MONITOR_POWER_MONITOR_SOURCE_H_

#include "base/base_export.h"
#include "base/macros.h"
#include "base/memory/ref_counted.h"
#include "base/power_monitor/power_observer.h"
#include "base/synchronization/lock.h"
#include "base/ttnet_implement_buildflags.h"
#include "build/build_config.h"

namespace base {

class PowerMonitor;

// Communicates power state changes to the power monitor.
class BASE_EXPORT PowerMonitorSource {
 public:
  PowerMonitorSource();
  virtual ~PowerMonitorSource();

  // Normalized list of power events.
  enum PowerEvent {
#if BUILDFLAG(TTNET_IMPLEMENT)
    POWER_STATE_EVENT,     // The Power status of the system has changed.
    SUSPEND_EVENT,         // The system is being suspended.
    RESUME_EVENT,          // The system is being resumed.
    INSTANT_SUSPEND_EVENT, // The system is being instant suspended.
    INSTANT_RESUME_EVENT   // The system is being instant resume.
#else
    POWER_STATE_EVENT,  // The Power status of the system has changed.
    SUSPEND_EVENT,      // The system is being suspended.
    RESUME_EVENT        // The system is being resumed.
#endif
  };

  // Is the computer currently on battery power. Can be called on any thread.
  bool IsOnBatteryPower();

#if BUILDFLAG(TTNET_IMPLEMENT)
  bool IsOnSuspened() { return suspended_; }
  bool IsOnInstantSuspended() { return instant_suspended_; }
#endif

  // Reads the current DeviceThermalState, if available on the platform.
  // Otherwise, returns kUnknown.
  virtual PowerObserver::DeviceThermalState GetCurrentThermalState();

#if defined(OS_ANDROID)
  // Read and return the current remaining battery capacity (microampere-hours).
  virtual int GetRemainingBatteryCapacity();
#endif  // defined(OS_ANDROID)

  static const char* DeviceThermalStateToString(
      PowerObserver::DeviceThermalState state);

 protected:
  friend class PowerMonitorTest;

  // Friend function that is allowed to access the protected ProcessPowerEvent.
  friend void ProcessPowerEventHelper(PowerEvent);

  // Process*Event should only be called from a single thread, most likely
  // the UI thread or, in child processes, the IO thread.
  static void ProcessPowerEvent(PowerEvent event_id);
  static void ProcessThermalEvent(
      PowerObserver::DeviceThermalState new_thermal_state);

  // Platform-specific method to check whether the system is currently
  // running on battery power.  Returns true if running on batteries,
  // false otherwise.
  virtual bool IsOnBatteryPowerImpl() = 0;

  // Sets the initial state for |on_battery_power_|, which defaults to false
  // since not all implementations can provide the value at construction. May
  // only be called before a base::PowerMonitor has been created.
  void SetInitialOnBatteryPowerState(bool on_battery_power);

 private:
  bool on_battery_power_ GUARDED_BY(battery_lock_) = false;
  bool suspended_ = false;
#if BUILDFLAG(TTNET_IMPLEMENT)
  bool instant_suspended_ = false;
#endif

  // This lock guards access to on_battery_power_, to ensure that
  // IsOnBatteryPower can be called from any thread.
  Lock battery_lock_;

  DISALLOW_COPY_AND_ASSIGN(PowerMonitorSource);
};

}  // namespace base

#endif  // BASE_POWER_MONITOR_POWER_MONITOR_SOURCE_H_
