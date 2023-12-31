// Copyright 2021 The Lynx Authors. All rights reserved.
//
//  TransformRaw.h
//  Lynx
//
//  Created by lybvinci on 2021/1/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxTransformRaw : NSObject

- (instancetype)initWithArray:(NSArray*)arr;

@property(nonatomic, assign) float p0;
@property(nonatomic, assign) float p1;
@property(nonatomic, assign) float p2;
@property(nonatomic, assign) int type;

- (bool)isP0Percent;
- (bool)isP1Percent;
- (bool)isP2Percent;
- (bool)isRotate;
- (bool)isRotateXY;

+ (NSArray<LynxTransformRaw*>*)toTransformRaw:(NSArray*)arr;
+ (bool)hasPercent:(NSArray<LynxTransformRaw*>*)arr;
+ (bool)hasScaleOrRotate:(NSArray<LynxTransformRaw*>*)arr;
+ (CGFloat)getRotateZRad:(NSArray<LynxTransformRaw*>*)arr;
@end

NS_ASSUME_NONNULL_END
