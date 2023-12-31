// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_VSYNC_MONITOR_RENDERKIT_H_
#define LYNX_SHELL_RENDERKIT_VSYNC_MONITOR_RENDERKIT_H_

#include "shell/common/vsync_monitor.h"
#include "third_party/fml/time/time_point.h"

namespace lynx {
namespace shell {

class VSyncMonitorRenderkit : public VSyncMonitor {
 public:
  VSyncMonitorRenderkit(bool init_in_current_loop = true);
  ~VSyncMonitorRenderkit() override;

  void Init() override;

  void RequestVSync() override;

 private:
  fml::TimePoint phase_;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_VSYNC_MONITOR_RENDERKIT_H_
