// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_HEADLESS_VSYNC_MONITOR_HEADLESS_H_
#define LYNX_SHELL_HEADLESS_VSYNC_MONITOR_HEADLESS_H_

#include "shell/common/vsync_monitor.h"

namespace lynx {
namespace shell {

class VSyncMonitorHeadless : public VSyncMonitor {
 public:
  VSyncMonitorHeadless(bool init_in_current_loop = true);
  ~VSyncMonitorHeadless() override;

  void Init() override;

  void RequestVSync() override;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_HEADLESS_VSYNC_MONITOR_HEADLESS_H_
