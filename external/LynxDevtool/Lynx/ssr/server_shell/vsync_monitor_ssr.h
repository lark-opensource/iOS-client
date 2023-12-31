// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_SSR_SERVER_SHELL_VSYNC_MONITOR_SSR_H_
#define LYNX_SSR_SERVER_SHELL_VSYNC_MONITOR_SSR_H_

#include "shell/common/vsync_monitor.h"

namespace lynx {
namespace shell {

class VSyncMonitorSSR : public VSyncMonitor {
 public:
  VSyncMonitorSSR();
  ~VSyncMonitorSSR() override;

  void Init() override;

  void RequestVSync() override;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SSR_SERVER_SHELL_VSYNC_MONITOR_SSR_H_
