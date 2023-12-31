//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxScrollFluency.h"
#import "LynxFluencyMonitor.h"

@implementation LynxScrollFluency

- (void)scrollerWillBeginDragging:(LynxScrollInfo *)info {
  [[LynxFluencyMonitor sharedInstance] startWithScrollInfo:info];
}

- (void)scrollerDidEndDragging:(LynxScrollInfo *)info willDecelerate:(BOOL)decelerate {
  if (!decelerate) {
    [[LynxFluencyMonitor sharedInstance] stopWithScrollInfo:info];
  }
}

- (void)scrollerDidEndDecelerating:(LynxScrollInfo *)info {
  [[LynxFluencyMonitor sharedInstance] stopWithScrollInfo:info];
}

@end
