// Copyright 2021 The Lynx Authors. All rights reserved.
//
//  TransformRaw.m
//  Lynx
//
//  Created by lybvinci on 2021/1/24.
//

#import "LynxTransformRaw.h"
#import "LynxCSSType.h"

@implementation LynxTransformRaw {
  LynxPlatformLengthUnit _p0Unit;
  LynxPlatformLengthUnit _p1Unit;
  LynxPlatformLengthUnit _p2Unit;
}

- (instancetype)initWithArray:(NSArray*)arr {
  if (self = [super init]) {
    _type = [arr[0] intValue];
    _p0 = [arr[1] doubleValue];
    _p0Unit = (LynxPlatformLengthUnit)[arr[2] intValue];
    _p1 = [arr[3] doubleValue];
    _p1Unit = (LynxPlatformLengthUnit)[arr[4] intValue];
    _p2 = [arr[5] doubleValue];
    _p2Unit = (LynxPlatformLengthUnit)[arr[6] intValue];
  }
  return self;
}

- (bool)isP0Percent {
  return _p0Unit == LynxPlatformLengthUnitPercentage;
}
- (bool)isP1Percent {
  return _p1Unit == LynxPlatformLengthUnitPercentage;
}
- (bool)isP2Percent {
  return _p2Unit == LynxPlatformLengthUnitPercentage;
}
- (bool)isRotate {
  LynxTransformType type = (LynxTransformType)_type;
  return type == LynxTransformTypeRotate || type == LynxTransformTypeRotateX ||
         type == LynxTransformTypeRotateY || type == LynxTransformTypeRotateZ;
}
- (bool)isRotateXY {
  LynxTransformType type = (LynxTransformType)_type;
  return type == LynxTransformTypeRotateX || type == LynxTransformTypeRotateY;
}

+ (NSArray<LynxTransformRaw*>*)toTransformRaw:(NSArray*)arr {
  if ([arr isEqual:[NSNull null]] || nil == arr || [arr count] == 0) {
    return nil;
  }
  NSMutableArray<LynxTransformRaw*>* result = [[NSMutableArray alloc] init];
  for (NSUInteger i = 0; i < arr.count; i++) {
    if ([arr[i] isKindOfClass:[NSArray class]]) {
      NSArray* item = (NSArray*)arr[i];
      if (item != nil && item.count >= 4) {
        [result addObject:[[LynxTransformRaw alloc] initWithArray:item]];
      }
    }
  }
  return [result copy];
}

+ (bool)hasPercent:(NSArray<LynxTransformRaw*>*)arr {
  if (nil == arr || arr.count == 0) {
    return false;
  }
  for (LynxTransformRaw* raw in arr) {
    if ([raw isP0Percent] || [raw isP1Percent]) {
      return true;
    }
  }
  return false;
}

// TODO: will remove in release/2.2
+ (CGFloat)getRotateZRad:(NSArray<LynxTransformRaw*>*)arr {
  CGFloat rotateZ = 0;
  if (nil == arr || arr.count == 0) {
    return rotateZ;
  }
  for (LynxTransformRaw* raw in arr) {
    LynxTransformType type = (LynxTransformType)raw.type;
    if (type == LynxTransformTypeRotateZ || type == LynxTransformTypeRotate) {
      rotateZ = raw.p0 * M_PI / 180;
    }
  }
  return rotateZ;
}

+ (bool)hasScaleOrRotate:(NSArray<LynxTransformRaw*>*)arr {
  if (nil == arr || arr.count == 0) {
    return false;
  }
  for (LynxTransformRaw* raw in arr) {
    LynxTransformType type = (LynxTransformType)raw.type;
    if (type == LynxTransformTypeScale || type == LynxTransformTypeScaleX ||
        type == LynxTransformTypeScaleY || type == LynxTransformTypeRotate ||
        type == LynxTransformTypeRotateX || type == LynxTransformTypeRotateY ||
        type == LynxTransformTypeRotateZ) {
      return true;
    }
  }
  return false;
}
@end
