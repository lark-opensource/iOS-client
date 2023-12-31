// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_IOS_VSYNC_MONITOR_DARWIN_H_
#define LYNX_SHELL_IOS_VSYNC_MONITOR_DARWIN_H_

#include "shell/common/vsync_monitor.h"

@interface LynxVSyncPulse : NSObject
@property(atomic) CADisplayLink* displayLink;
@property(atomic) BOOL isInBackground;

- (instancetype)initWithCallback:(lynx::shell::VSyncMonitor::Callback)callback;

- (void)requestPulse;

- (void)invalidate;

@end

namespace lynx {
namespace shell {

class VSyncMonitorIOS : public VSyncMonitor {
 public:
  VSyncMonitorIOS(bool init_in_current_loop = true);
  ~VSyncMonitorIOS() override;

  void Init() override;

  void RequestVSync() override;

 private:
  LynxVSyncPulse* delegate_;
};

}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_IOS_VSYNC_MONITOR_DARWIN_H_
