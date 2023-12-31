// Copyright 2020 The Lynx Authors. All rights reserved.

#import "DevtoolMonitorView.h"

@implementation DevtoolMonitorView

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
  UIView* view = [super hitTest:point withEvent:event];
  if (view == self) {
    return nil;
  }
  return view;
}

@end
