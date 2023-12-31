// Copyright 2020 The Lynx Authors. All rights reserved.

#import "BDXLynxBlurView.h"
#import "BDXLynxBlurEffect.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxLog.h>
#import <Lynx/LynxPropsProcessor.h>
@interface BDXLynxBlurView ()
@property(nonatomic, assign) UIBlurEffectStyle style;
@property(nonatomic, assign) CGFloat radius;
@end

@implementation BDXLynxBlurView {
  bool _shouldUpdateEffect;
}

#if LYNX_LAZY_LOAD
+ (void)lynxLazyLoad {
  LYNX_BASE_INIT_METHOD
  [LynxComponentRegistry registerUI:self withName:@"blur-view"];
  [LynxComponentRegistry registerUI:self withName:@"x-blur-view"];
}
#else
+ (void)load {
  [LynxComponentRegistry registerUI:self withName:@"blur-view"];
  [LynxComponentRegistry registerUI:self withName:@"x-blur-view"];
}
#endif

- (UIView*)createView {
  self.style = UIBlurEffectStyleLight;
  UIVisualEffectView* view = [[UIVisualEffectView alloc] init];
  return view;
}

- (void)insertChild:(LynxUI*)child atIndex:(NSInteger)index {
  [self didInsertChild:child atIndex:index];
  [self.view.contentView insertSubview:[child view] atIndex:index];
  if (index > 0) {
    LynxUI* ui = [self.children objectAtIndex:index - 1];
    CALayer* layer = ui.view.layer;
    if (index <= self.view.contentView.layer.sublayers.count &&
        layer !=
            [self.view.contentView.layer.sublayers objectAtIndex:index - 1]) {
      CALayer* childLayer = [child view].layer;
      [childLayer removeFromSuperlayer];
      [self.view.contentView.layer insertSublayer:childLayer above:layer];
      LynxBackgroundManager* mgr = [child backgroundManager];
      if (mgr != nil) {
        if (mgr.borderLayer != nil) {
          [mgr.borderLayer removeFromSuperlayer];
          [self.view.contentView.layer insertSublayer:mgr.borderLayer
                                                above:childLayer];
        }
        if (mgr.backgroundLayer != nil) {
          [mgr.backgroundLayer removeFromSuperlayer];
          [self.view.contentView.layer insertSublayer:mgr.backgroundLayer
                                                below:childLayer];
        }
      }
    }
  }
}

LYNX_PROP_SETTER("blur-effect", setBlurEffect, NSString*) {
  if (requestReset) {
    value = @"light";
  }
  UIBlurEffectStyle style = UIBlurEffectStyleLight;
  if ([value isEqualToString:@"dark"]) {
    style = UIBlurEffectStyleDark;
  } else if ([value isEqualToString:@"extra-light"]) {
    style = UIBlurEffectStyleExtraLight;
  } else if (![value isEqualToString:@"light"]) {
    LLogError(@"Lynx Prop setter error: wrong blur-effect, use default "
              @"blur-effect light.");
  }
  if (self.style != style) {
    self.style = style;
    _shouldUpdateEffect = YES;
  }
}

LYNX_PROP_SETTER("background-color", setBackgroundColor, UIColor*) {}

LYNX_PROP_SETTER("background-origin", setBackgroundOrigin, NSString*) {}

LYNX_PROP_SETTER("background-position", setBackgroundPosition, NSString*) {}

LYNX_PROP_SETTER("background-repeat", setBackgroundRepeat, NSString*) {}

LYNX_PROP_SETTER("background-size", setBackgroundSize, NSString*) {}

LYNX_PROP_SETTER("background-capInsets", setBackgroundCapInsets, NSString*) {}

LYNX_PROP_SETTER("background-clip", setBackgroundClip, NSArray*) {}

LYNX_PROP_SETTER("background", setBackground, NSString*) {}

LYNX_PROP_SETTER("background-image", setBackgroundImage, NSString*) {}

/**
 * @name: blur-radius
 * @description: radius for gaussian filter
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.10
 **/
LYNX_PROP_SETTER("blur-radius", setBlurRadius, CGFloat) {
  if (requestReset) {
    value = 0.0;
  }
  if (self.radius != value) {
    self.radius = value;
    _shouldUpdateEffect = YES;
  }
}
- (void)propsDidUpdate {
  if (_shouldUpdateEffect) {
    // Remove the current effect to ensure 'effectSettings' to be invoked. If
    // the effect style doesn't change, the 'effectSettings' will not be invoke
    // again.
    self.view.effect = nil;
    // if radius is 0, remove the effect.
    if (self.radius != 0) {
      UIBlurEffect* effect = [BDXLynxBlurEffect effectWithStyle:self.style
                                                     blurRadius:self.radius];
      self.view.effect = effect;
    }
    _shouldUpdateEffect = NO;
  }
}

@end
