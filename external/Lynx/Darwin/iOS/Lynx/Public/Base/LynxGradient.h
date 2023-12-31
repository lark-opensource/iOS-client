// Copyright 2020 The Lynx Authors. All rights reserved.
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LynxLinearGradientDirection) {
  LynxLinearGradientDirectionNone = 0,
  LynxLinearGradientDirectionToTop,
  LynxLinearGradientDirectionToBottom,
  LynxLinearGradientDirectionToLeft,
  LynxLinearGradientDirectionToRight,
  LynxLinearGradientDirectionToTopRight,
  LynxLinearGradientDirectionToTopLeft,
  LynxLinearGradientDirectionToBottomRight,
  LynxLinearGradientDirectionToBottomLeft,
  LynxLinearGradientDirectionAngle
};

typedef NS_ENUM(NSInteger, LynxRadialGradientExtent) {
  LynxRadialGradientDirectionFarthestCorner = 0,
  LynxRadialGradientDirectionClosestCorner,
  LynxRadialGradientDirectionFarthestSide,
  LynxRadialGradientDirectionClosestSide
};

typedef NS_ENUM(NSInteger, LynxRadialCenterType) {
  LynxRadialCenterTypePercentage = 11,
  LynxRadialCenterTypeRPX = 6,
  LynxRadialCenterTypePX = 5,
};

@interface LynxGradient : NSObject
@property(nonatomic, nullable) NSMutableArray* colors;
@property(nonatomic, nullable) CGFloat* positions;
- (instancetype)initWithColors:(NSArray<NSNumber*>*)colors stops:(NSArray<NSNumber*>*)stops;
- (void)draw:(CGContextRef)context withPath:(CGPathRef)path;
- (void)draw:(CGContextRef)context withRect:(CGRect)pathRect;
- (BOOL)isEqualTo:(LynxGradient*)rhs;
@end

@interface LynxLinearGradient : LynxGradient
@property(nonatomic, assign) double angle;
@property(nonatomic, assign) LynxLinearGradientDirection directionType;
- (instancetype)initWithArray:(NSArray*)arr;
@end

@interface LynxRadialGradient : LynxGradient
@property(nonatomic, assign) LynxRadialCenterType centerX;
@property(nonatomic, assign) LynxRadialCenterType centerY;
@property(nonatomic, assign) CGFloat centerXValue;
@property(nonatomic, assign) CGFloat centerYValue;
@property(nonatomic, assign) CGPoint at;
@property(nonatomic, assign) LynxRadialGradientExtent extent;
- (instancetype)initWithArray:(NSArray*)arr;
@end

BOOL LynxSameLynxGradient(LynxGradient* _Nullable left, LynxGradient* _Nullable right);

NS_ASSUME_NONNULL_END
