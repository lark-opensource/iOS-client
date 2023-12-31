// Copyright 2021 The Lynx Authors. All rights reserved.

#import "shell/ios/vsync_monitor_darwin.h"
#import <Foundation/Foundation.h>
#import <QuartzCore/CADisplayLink.h>

@implementation LynxVSyncPulse {
  lynx::shell::VSyncMonitor::Callback _callback;
  CADisplayLink *_displayLink;
}

- (instancetype)initWithCallback:(lynx::shell::VSyncMonitor::Callback)callback {
  self = [super init];
  if (self) {
    _callback = std::move(callback);
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onMainDisplay:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    _displayLink.paused = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
  }
  return self;
}

- (void)appWillEnterForeground:(UIApplication *)application {
  _isInBackground = NO;
}

- (void)appDidEnterBackground:(UIApplication *)application {
  _isInBackground = YES;
}

- (void)requestPulse {
  _displayLink.paused = NO;
}

- (void)onMainDisplay:(CADisplayLink *)link {
  // TODO: This is a temporary solution, and a more reasonable solution should only stop GL related
  // operations.
  if (_isInBackground) {
    return;
  }
  link.paused = YES;
  if (_callback) {
    CFTimeInterval timestamp = _displayLink.timestamp;
    _callback(timestamp * 1e+9, (timestamp + _displayLink.duration) * 1e+9);
  }
}

- (void)invalidate {
  [_displayLink invalidate];
}

- (void)dealloc {
  [_displayLink invalidate];
  _displayLink = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

namespace lynx {
namespace shell {

VSyncMonitorIOS::VSyncMonitorIOS(bool init_in_current_loop) {
  if (init_in_current_loop) {
    Init();
  }
}

void VSyncMonitorIOS::Init() {
  if (!delegate_) {
    delegate_ = [[LynxVSyncPulse alloc]
        initWithCallback:std::bind(&VSyncMonitor::OnVSync, this, std::placeholders::_1,
                                   std::placeholders::_2)];
  }
}

VSyncMonitorIOS::~VSyncMonitorIOS() { [delegate_ invalidate]; }

void VSyncMonitorIOS::RequestVSync() {
  if (!delegate_) {
    Init();
  }
  [delegate_ requestPulse];
}

}  // namespace shell
}  // namespace lynx
