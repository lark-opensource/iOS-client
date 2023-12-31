// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxPerfMonitorDarwin.h"
#import "LynxFPSGraph.h"
#include "base/closure.h"

static CGFloat const LynxPerfMonitorBarHeight = 50;

@implementation LynxPerfMonitorDarwin {
  UIView *_container;
  LynxFPSGraph *_uiGraph;
  LynxFPSGraph *_jsGraph;
  UILabel *_uiGraphLabel;
  UILabel *_jsGraphLabel;
  CADisplayLink *_uiDisplayLink;
  CADisplayLink *_jsDisplayLink;
  __weak id<LynxBaseInspectorOwner> _owner;
}

- (instancetype)initWithInspectorOwner:(id<LynxBaseInspectorOwner>)owner {
  self = [super init];
  if (self) {
    _owner = owner;
  }
  return self;
}

- (LynxFPSGraph *)uiGraph {
  if (_uiGraph == nil) {
    _uiGraph = [[LynxFPSGraph alloc] initWithFrame:CGRectMake(0, 14, 40, 30)
                                             color:[UIColor lightGrayColor]];
  }
  return _uiGraph;
}

- (LynxFPSGraph *)jsGraph {
  if (_jsGraph == nil) {
    _jsGraph = [[LynxFPSGraph alloc] initWithFrame:CGRectMake(42, 14, 40, 30)
                                             color:[UIColor lightGrayColor]];
  }
  return _jsGraph;
}

- (UILabel *)uiGraphLabel {
  if (_uiGraphLabel == nil) {
    _uiGraphLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 3, 40, 10)];
    _uiGraphLabel.font = [UIFont systemFontOfSize:11];
    _uiGraphLabel.textAlignment = NSTextAlignmentCenter;
    _uiGraphLabel.text = @"UI";
  }

  return _uiGraphLabel;
}

- (UILabel *)jsGraphLabel {
  if (_jsGraphLabel == nil) {
    _jsGraphLabel = [[UILabel alloc] initWithFrame:CGRectMake(42, 3, 38, 10)];
    _jsGraphLabel.font = [UIFont systemFontOfSize:11];
    _jsGraphLabel.textAlignment = NSTextAlignmentCenter;
    _jsGraphLabel.text = @"JS";
  }

  return _jsGraphLabel;
}

- (UIView *)container {
  if (_container == nil) {
    _container = [[UIView alloc] initWithFrame:CGRectMake(70, 40, 82, LynxPerfMonitorBarHeight)];
    _container.layer.borderWidth = 2;
    _container.layer.borderColor = [UIColor lightGrayColor].CGColor;
    if (@available(iOS 13.0, *)) {
      _container.backgroundColor = [UIColor systemBackgroundColor];
    } else {
      _container.backgroundColor = [UIColor whiteColor];
    }
  }
  return _container;
}

- (void)show {
  if (_container) {
    return;
  }
  [self.container addSubview:self.uiGraph];
  [self.container addSubview:self.uiGraphLabel];

  UIWindow *window = [UIApplication sharedApplication].delegate.window;
  [window addSubview:_container];
  _uiDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(fpsUpdate:)];
  [_uiDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
  if (_owner != nil) {
    _jsDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(fpsUpdate:)];
    lynx::base::closure callback = [displayLink = _jsDisplayLink] {
      [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    };
    [_owner RunOnJSThread:reinterpret_cast<intptr_t>(&callback)];
  }
  [self.container addSubview:self.jsGraph];
  [self.container addSubview:self.jsGraphLabel];
}

- (void)hide {
  if (!_container) {
    return;
  }

  [self.container removeFromSuperview];
  _container = nil;
  _jsGraph = nil;
  _uiGraph = nil;

  [_uiDisplayLink invalidate];
  _uiDisplayLink = nil;

  if (_jsDisplayLink != nil) {
    [_jsDisplayLink invalidate];
    _jsDisplayLink = nil;
  }
}

- (void)fpsUpdate:(CADisplayLink *)displayLink {
  LynxFPSGraph *graph = displayLink == _jsDisplayLink ? _jsGraph : _uiGraph;
  [graph onTick:displayLink.timestamp];
}

@end
