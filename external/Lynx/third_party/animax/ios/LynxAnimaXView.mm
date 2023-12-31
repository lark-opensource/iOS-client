// Copyright 2023 The Lynx Authors. All rights reserved.

#import "LynxAnimaXView.h"

@implementation LynxAnimaXView

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.layer.opaque = NO;
    self.layer.contentsScale = [UIScreen mainScreen].scale;
  }
  return self;
}

@end
