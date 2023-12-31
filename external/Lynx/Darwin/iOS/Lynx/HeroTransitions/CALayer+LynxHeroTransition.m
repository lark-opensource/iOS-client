// Copyright 2019 The Lynx Authors. All rights reserved.

#import "CALayer+LynxHeroTransition.h"

@implementation CALayer (LynxHeroTransition)

- (CATransform3D)flatTransformTo:(CALayer*)layer {
  CALayer* curLayer = layer;
  CALayer* superLayer = curLayer.superlayer;
  CATransform3D curTrans = layer.transform;
  while (superLayer && superLayer != self && ![superLayer.delegate isKindOfClass:UIWindow.class]) {
    curTrans = CATransform3DConcat(superLayer.transform, curTrans);
    superLayer = superLayer.superlayer;
  }
  return curTrans;
}

@end
