// Copyright 2021 The Lynx Authors. All rights reserved.

#import <CoreFoundation/CoreFoundation.h>
#import "LynxCSSType.h"
#import "LynxGradient.h"

@interface LynxBackgroundSize : NSObject
// FIXME: this property is fit for old background logical
@property(nonatomic, assign) NSInteger type;
@property(nonatomic, assign) CGFloat value;

- (instancetype _Nullable)initWithValue:(CGFloat)value type:(NSInteger)type;
- (BOOL)isCover;
- (BOOL)isContain;
- (BOOL)isAuto;
- (CGFloat)apply:(CGFloat)parentValue currentValue:(CGFloat)currentValue;
@end

@interface LynxBackgroundPosition : NSObject
// FIXME: this property is fit for old background logical
@property(nonatomic, assign) NSInteger type;
@property(nonatomic, assign) CGFloat value;
@property(nonatomic, assign) CGFloat percentValue;

- (instancetype _Nullable)initWithValue:(CGFloat)value type:(NSInteger)type;
- (instancetype _Nullable)initWithValue:(CGFloat)numberValue
                             andPercent:(CGFloat)percentValue
                                   type:(NSInteger)type;

- (CGFloat)apply:(CGFloat)avaiableValue;
@end

@interface LynxBackgroundDrawable : NSObject
@property(nonatomic, assign) LynxBackgroundRepeatType repeatX;
@property(nonatomic, assign) LynxBackgroundRepeatType repeatY;
@property(nonatomic, assign) LynxBackgroundClipType clip;
@property(nonatomic, assign) LynxBackgroundOriginType origin;

@property(nonatomic, strong, nullable) LynxBackgroundPosition* posX;
@property(nonatomic, strong, nullable) LynxBackgroundPosition* posY;
@property(nonatomic, strong, nullable) LynxBackgroundSize* sizeX;
@property(nonatomic, strong, nullable) LynxBackgroundSize* sizeY;

@property(nonatomic, assign) CGRect bounds;

- (CGFloat)getImageWidth;
- (CGFloat)getImageHeight;

- (void)drawInContext:(CGContextRef _Nonnull)ctx
           borderRect:(CGRect)borderRect
          paddingRect:(CGRect)paddingRect
          contentRect:(CGRect)contentRect;
@end

@interface LynxBackgroundImageDrawable : LynxBackgroundDrawable
@property(nonatomic, strong, nullable) NSURL* url;
@property(atomic, strong, nullable) UIImage* image;

- (instancetype _Nullable)initWithString:(NSString* _Nullable)string;
- (instancetype _Nullable)initWithURL:(NSURL* _Nullable)url;
@end

@interface LynxBackgroundGradientDrawable : LynxBackgroundDrawable
@property(nonatomic, strong, nullable) LynxGradient* gradient;
@end

@interface LynxBackgroundLinearGradientDrawable : LynxBackgroundGradientDrawable
- (instancetype _Nullable)initWithArray:(NSArray* _Nonnull)array;
@end

@interface LynxBackgroundRadialGradientDrawable : LynxBackgroundGradientDrawable
- (instancetype _Nullable)initWithArray:(NSArray* _Nonnull)array;
@end

@interface LynxBackgroundNoneDrawable : LynxBackgroundDrawable
@end
