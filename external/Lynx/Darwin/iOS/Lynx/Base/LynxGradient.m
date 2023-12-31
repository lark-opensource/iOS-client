// Copyright 2020 The Lynx Authors. All rights reserved.
#import "LynxGradient.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LynxCSSType.h"
#import "LynxColorUtils.h"
#import "LynxConverter+UI.h"

#pragma mark LynxGradient

@implementation LynxGradient {
}

- (instancetype)initWithColors:(NSArray<NSNumber*>*)colors stops:(NSArray<NSNumber*>*)stops {
  self = [super init];
  if (self) {
    NSUInteger count = [colors count];
    self.colors = [NSMutableArray array];
    if ([stops count] == count) {
      self.positions = malloc(count * sizeof(CGFloat));
    } else {
      self.positions = nil;
    }

    for (NSUInteger i = 0; i < count; i++) {
      [self.colors addObject:[LynxConverter toUIColor:colors[i]]];
      if (self.positions) {
        self.positions[i] = [LynxConverter toCGFloat:stops[i]] / 100.0;
        // Color stops should be listed in ascending order
        if (i >= 1 && self.positions[i] < self.positions[i - 1]) {
          self.positions[i] = self.positions[i - 1];
        }
      }
    }
  }
  return self;
}

- (BOOL)isEqualTo:(LynxGradient*)rhs {
  if (![_colors isEqual:rhs.colors]) {
    return false;
  }

  bool hasPosition = _positions != nil;
  bool rhsHasPositon = rhs.positions != nil;

  if (hasPosition != rhsHasPositon) {
    return false;
  }
  // both position is empty
  if (!hasPosition) {
    return true;
  }

  return memcmp(_positions, rhs.positions, [_colors count] * sizeof(CGFloat)) == 0;
}

- (void)draw:(CGContextRef)context withPath:(CGPathRef)path {
}

- (void)draw:(CGContextRef)context withRect:(CGRect)path {
}

- (void)dealloc {
  if (_positions) {
    free(_positions);
    _positions = NULL;
  }
}

@end

#pragma mark LynxBackgroundLinearGradient
@implementation LynxLinearGradient {
}

- (instancetype)initWithArray:(NSArray*)arr {
  self = [super initWithColors:arr[1] stops:arr[2]];
  if (self) {
    // [angle, color, stop, side-or-corner]
    // The parsed value from old css style from binary code (e.g CSSParser) don't have the last
    // field. All values should be treated as <angle>.
    self.directionType = arr.count == 4 ? [arr[3] intValue] : LynxLinearGradientDirectionAngle;
    self.angle = [arr[0] doubleValue] * M_PI / 180.0;
  }
  return self;
}

- (void)draw:(CGContextRef)context withRect:(CGRect)pathRect {
  NSMutableArray* ar = [NSMutableArray array];
  for (UIColor* c in self.colors) {
    [ar addObject:(id)c.CGColor];
  }
  CGColorSpaceRef colorSpace = CGColorGetColorSpace([[self.colors lastObject] CGColor]);
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)ar, self.positions);
  CGPoint start, end, m, center;
  float s, c, t;
  const int w = MAX(pathRect.size.width, 1), h = MAX(pathRect.size.height, 1);
  // diagonal line is 0.5
  const float mul = 2.0f * w * h / (w * w + h * h);
  switch (_directionType) {
    case LynxLinearGradientDirectionToTop:
      start = CGPointMake(0, h);
      end = CGPointMake(0, 0);
      break;
    case LynxLinearGradientDirectionToBottom:
      start = CGPointMake(0, 0);
      end = CGPointMake(0, h);
      break;
    case LynxLinearGradientDirectionNone:
      start = CGPointMake(0, 0);
      end = CGPointMake(0, h);
      break;
    case LynxLinearGradientDirectionToLeft:
      start = CGPointMake(w, 0);
      end = CGPointMake(0, 0);
      break;
    case LynxLinearGradientDirectionToRight:
      start = CGPointMake(0, 0);
      end = CGPointMake(w, 0);
      break;
    case LynxLinearGradientDirectionToTopLeft:
      start = CGPointMake(h * mul, w * mul);
      end = CGPointMake(0, 0);
      break;
    case LynxLinearGradientDirectionToBottomRight:
      start = CGPointMake(0, 0);
      end = CGPointMake(h * mul, w * mul);
      break;
    case LynxLinearGradientDirectionToTopRight:
      start = CGPointMake(w - h * mul, w * mul);
      end = CGPointMake(w, 0);
      break;
    case LynxLinearGradientDirectionToBottomLeft:
      start = CGPointMake(w, 0);
      end = CGPointMake(w - h * mul, w * mul);
      break;
    case LynxLinearGradientDirectionAngle:
      center = CGPointMake(w / 2, h / 2);
      s = sin(_angle);
      c = cos(_angle);
      t = tan(_angle);
      if (s >= 0 && c >= 0) {
        m = CGPointMake(w, 0);
      } else if (s >= 0 && c < 0) {
        m = CGPointMake(w, h);
      } else if (s < 0 && c < 0) {
        m = CGPointMake(0, h);
      } else {
        m = CGPointMake(0, 0);
      }
      end = CGPointMake(center.x + s * (center.y - m.y - t * center.x + t * m.x) / (s * t + c),
                        center.y - (center.y - m.y - t * center.x + t * m.x) / (t * t + 1));
      start = CGPointMake(2 * center.x - end.x, 2 * center.y - end.y);
      break;
  }
  CGContextDrawLinearGradient(
      context, gradient, start, end,
      kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
  CGGradientRelease(gradient);
}

- (void)draw:(CGContextRef)context withPath:(CGPathRef)path {
  CGContextAddPath(context, path);
  CGContextClip(context);
  CGRect pathRect = CGPathGetBoundingBox(path);
  [self draw:context withRect:pathRect];
}

- (BOOL)isEqualTo:(LynxGradient*)object {
  if (![object isKindOfClass:[LynxLinearGradient class]]) {
    return false;
  }
  LynxLinearGradient* rhs = (LynxLinearGradient*)object;
  return [super isEqualTo:rhs] && self.angle == rhs.angle;
}

@end

#pragma mark LynxBackgroundRadialGradient
@implementation LynxRadialGradient {
}

- (instancetype)initWithArray:(NSArray*)arr {
  self = [super initWithColors:arr[1] stops:arr[2]];
  if (self) {
    NSArray* shapeSize = arr[0];
    NSUInteger size = [shapeSize[1] unsignedIntValue];
    if (size == LynxRadialGradientSizeFarthestSide) {
      _extent = LynxRadialGradientDirectionFarthestSide;
    } else if (size == LynxRadialGradientSizeFarthestCorner) {
      _extent = LynxRadialGradientDirectionFarthestCorner;
    } else if (size == LynxRadialGradientSizeClosestSide) {
      _extent = LynxRadialGradientDirectionClosestSide;
    } else if (size == LynxRadialGradientSizeClosestCorner) {
      _extent = LynxRadialGradientDirectionClosestCorner;
    } else {
      _extent = LynxRadialGradientDirectionFarthestCorner;
    }
    _at = CGPointMake(0.5, 0.5);
    // [x-position-type, x-position, y-position-type y-position]
    self.centerX = [shapeSize[2] integerValue];
    self.centerXValue = [shapeSize[3] floatValue];
    self.centerY = [shapeSize[4] integerValue];
    self.centerYValue = [shapeSize[5] floatValue];
  }
  return self;
}

- (void)draw:(CGContextRef)context withRect:(CGRect)pathRect {
  NSMutableArray* ar = [NSMutableArray array];
  for (UIColor* c in self.colors) {
    [ar addObject:(id)c.CGColor];
  }
  CGColorSpaceRef colorSpace = CGColorGetColorSpace([[self.colors lastObject] CGColor]);
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)ar, self.positions);
  int w = pathRect.size.width, h = pathRect.size.height;

  [self calculateCenterWithWidth:w andHeight:h];

  CGPoint center = self.at;
  float radius;
  CGFloat x, y;
  switch (_extent) {
    case LynxRadialGradientDirectionClosestSide:
      x = MIN(_at.x, w - _at.x);
      y = MIN(_at.y, h - _at.y);
      radius = MIN(x, y);
      break;
    case LynxRadialGradientDirectionClosestCorner:
      x = MIN(_at.x, w - _at.x);
      y = MIN(_at.y, h - _at.y);
      radius = sqrt(x * x + y * y);
      break;
    case LynxRadialGradientDirectionFarthestSide:
      x = MAX(_at.x, w - _at.x);
      y = MAX(_at.y, h - _at.y);
      radius = MAX(x, y);
      break;
    case LynxRadialGradientDirectionFarthestCorner:
      x = MAX(_at.x, w - _at.x);
      y = MAX(_at.y, h - _at.y);
      radius = sqrt(x * x + y * y);
      break;
  }
  CGContextDrawRadialGradient(
      context, gradient, center, 0, center, radius,
      kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
  CGGradientRelease(gradient);
}

- (void)draw:(CGContextRef)context withPath:(CGPathRef)path {
  CGContextAddPath(context, path);
  CGContextClip(context);
  CGRect pathRect = CGPathGetBoundingBox(path);
  [self draw:context withRect:pathRect];
}

- (BOOL)isEqualTo:(LynxGradient*)object {
  if (![object isKindOfClass:[LynxRadialGradient class]]) {
    return false;
  }
  LynxRadialGradient* rhs = (LynxRadialGradient*)object;
  return [super isEqualTo:rhs] && CGPointEqualToPoint(self.at, rhs.at);
}

- (void)calculateCenterWithWidth:(CGFloat)width andHeight:(CGFloat)height {
  _at.x = [self calculateValue:self.centerX value:self.centerXValue base:width];
  _at.y = [self calculateValue:self.centerY value:self.centerYValue base:height];
}

- (CGFloat)calculateValue:(NSInteger)type value:(CGFloat)value base:(CGFloat)base {
  switch (type) {
    case -LynxBackgroundPositionCenter:
      return base * 0.5;
    case -LynxBackgroundPositionTop:
    case -LynxBackgroundPositionLeft:
      return 0.0;
    case -LynxBackgroundPositionRight:
    case -LynxBackgroundPositionBottom:
      return base;
    case LynxRadialCenterTypePercentage:
      return base * value / 100.0;
    default:
      // TODO handle REM RPX or other length type
      return value;
  }
}

@end

BOOL LynxSameLynxGradient(LynxGradient* _Nullable left, LynxGradient* _Nullable right) {
  if (left == nil && right == nil) {
    return YES;
  }
  if (left == nil || right == nil) {
    return NO;
  }
  return [left isEqualTo:right];
}
