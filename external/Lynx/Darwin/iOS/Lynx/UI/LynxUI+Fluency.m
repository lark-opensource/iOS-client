//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <objc/runtime.h>
#import "LynxFluencyMonitor.h"
#import "LynxUI+Fluency.h"

@implementation LynxUI (Fluency)

- (NSString*)scrollMonitorTagName {
  return _scrollMonitorTagName;
}

- (BOOL)enableScrollMonitor {
  return _enableScrollMonitor;
}

- (LynxScrollInfo*)infoWithScrollView:(UIScrollView*)view selector:(nonnull SEL)selector {
  LynxScrollInfo* info = [LynxScrollInfo infoWithScrollView:view
                                                    tagName:self.tagName
                                       scrollMonitorTagName:self.scrollMonitorTagName];
  info.selector = selector;
  info.lynxView = (LynxView*)self.context.rootView;
  return info;
}

- (void)postFluencyEventWithInfo:(LynxScrollInfo*)info {
  BOOL sendAllScroll = [LynxFluencyMonitor sharedInstance].shouldSendAllScrollEvent;
  id<LynxScrollListener> outerListener = self.context.scrollListener;
  id<LynxScrollListener> innerListener = self.context.scrollFluencyMonitor;

  if (sel_isEqual(info.selector, @selector(scrollerDidEndDragging:willDecelerate:))) {
    if (self.enableScrollMonitor && [outerListener respondsToSelector:info.selector]) {
      [outerListener scrollerDidEndDragging:info willDecelerate:info.decelerate];
    }
    if (sendAllScroll && [innerListener respondsToSelector:info.selector]) {
      [innerListener scrollerDidEndDragging:info willDecelerate:info.decelerate];
    }
    return;
  }

  // All the selector method return void, so we can ignore `-Warc-performSelector-leaks` safely.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  if (self.enableScrollMonitor && [outerListener respondsToSelector:info.selector]) {
    [outerListener performSelector:info.selector withObject:info];
  }
  if (sendAllScroll && [innerListener respondsToSelector:info.selector]) {
    [innerListener performSelector:info.selector withObject:info];
  }
#pragma clang diagnostic pop
}

@end
