// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxBackgroundDrawable.h"
#import "LynxCSSType.h"

#include "base/log/logging.h"

#pragma mark - LynxBackgroundSize

@implementation LynxBackgroundSize

- (instancetype)initWithValue:(CGFloat)value type:(NSInteger)type {
  self = [super init];
  if (self) {
    self.value = value;
    self.type = type;
  }
  return self;
}

- (BOOL)isCover {
  return self.value == LynxBackgroundSizeCover;
}

- (BOOL)isContain {
  return self.value == LynxBackgroundSizeContain;
}

- (BOOL)isAuto {
  return self.value == LynxBackgroundSizeAuto;
}

- (CGFloat)apply:(CGFloat)parentValue currentValue:(CGFloat)currentValue {
  if (self.type == LynxPlatformLengthUnitPercentage) {
    return self.value * parentValue;
  } else if ([self isAuto]) {
    return currentValue;
  } else {
    return self.value;
  }
}
@end

#pragma mark - LynxBackgroundPosition
@implementation LynxBackgroundPosition

- (instancetype)initWithValue:(CGFloat)value type:(NSInteger)type {
  self = [super init];
  if (self) {
    self.value = value;
    self.type = type;
  }
  return self;
}

- (instancetype)initWithValue:(CGFloat)numberValue
                   andPercent:(CGFloat)percentValue
                         type:(NSInteger)type {
  self = [super init];
  if (self) {
    self.value = numberValue;
    self.percentValue = percentValue;
    self.type = type;
  }
  return self;
}

- (CGFloat)apply:(CGFloat)availableValue {
  if (self.type == LynxPlatformLengthUnitPercentage) {
    return self.value * availableValue;
  } else if (self.type == LynxPlatformLengthUnitCalc) {
    return self.percentValue * availableValue + self.value;
  } else {
    return self.value;
  }
}
@end

#pragma mark - LynxbackgroundDrawable

@interface LynxBackgroundDrawable ()

- (void)onDraw:(CGContextRef)ctx rect:(CGRect)rect;
@end

@implementation LynxBackgroundDrawable

- (instancetype)init {
  self = [super init];
  if (self) {
    self.repeatX = LynxBackgroundRepeatRepeat;
    self.repeatY = LynxBackgroundRepeatRepeat;
    self.origin = LynxBackgroundOriginPaddingBox;
    self.clip = LynxBackgroundClipBorderBox;
    self.sizeX = nil;
    self.sizeY = nil;
    self.posX = nil;
    self.posY = nil;
    self.bounds = CGRectZero;
  }
  return self;
}

- (CGFloat)getImageWidth {
  return self.bounds.size.width;
}

- (CGFloat)getImageHeight {
  return self.bounds.size.height;
}

- (BOOL)isReady {
  return YES;
}

- (BOOL)isGradient {
  return NO;
}

- (void)drawInContext:(CGContextRef)ctx
           borderRect:(CGRect)borderRect
          paddingRect:(CGRect)paddingRect
          contentRect:(CGRect)contentRect {
  if (![self isReady]) {
    return;
  }
  // decide painting area
  CGRect paintBox = paddingRect;
  switch (self.origin) {
    case LynxBackgroundOriginBorderBox:
      paintBox = borderRect;
      break;
    case LynxBackgroundOriginContentBox:
      paintBox = contentRect;
      break;
    default:
      paintBox = paddingRect;
      break;
  }
  CGFloat selfWidth = paintBox.size.width;
  CGFloat selfHeight = paintBox.size.height;
  // adjust the size
  CGFloat width = paintBox.size.width;
  CGFloat height = paintBox.size.height;
  CGFloat widthSrc = [self getImageWidth];
  CGFloat heightSrc = [self getImageHeight];

  if ([self isGradient]) {
    width = paintBox.size.width;
    height = paintBox.size.height;
  } else {
    width = widthSrc;
    height = heightSrc;
  }
  CGFloat aspect = widthSrc / heightSrc;
  if ([self.sizeX isCover]) {
    width = selfWidth;
    height = width / aspect;
    if (height < selfHeight) {
      height = selfHeight;
      width = aspect * height;
    }
  } else if ([self.sizeX isContain]) {
    width = selfWidth;
    height = width / aspect;
    if (height > selfHeight) {
      height = selfHeight;
      width = aspect * height;
    }
  } else if (self.sizeX != nil && self.sizeY != nil) {
    width = [self.sizeX apply:selfWidth currentValue:width];
    height = [self.sizeY apply:selfHeight currentValue:height];

    if ([self.sizeX isAuto]) {
      if ([self isGradient]) {
        width = paintBox.size.width;
      } else {
        width = aspect * height;
      }
    }

    if ([self.sizeY isAuto]) {
      if ([self isGradient]) {
        height = paintBox.size.height;
      } else {
        height = width / aspect;
      }
    }
  }

  // OPTME:(tangruiwen) see issue:#4190
  if (width <= 0.01 || height <= 0.01) {
    return;
  }

  [self setBounds:CGRectMake(0, 0, width, height)];

  // decide position
  CGFloat offsetX = paintBox.origin.x;
  CGFloat offsetY = paintBox.origin.y;

  if (self.posX != nil && self.posY != nil) {
    CGSize deltaSize = CGSizeMake(paintBox.size.width - width, paintBox.size.height - height);
    offsetX += [self.posX apply:deltaSize.width];
    offsetY += [self.posY apply:deltaSize.height];
  }

  // repeat type
  CGContextSaveGState(ctx);
  if (self.repeatX == LynxBackgroundRepeatNoRepeat &&
      self.repeatY == LynxBackgroundRepeatNoRepeat) {
    CGContextTranslateCTM(ctx, offsetX, offsetY);
    [self onDraw:ctx rect:CGRectMake(0, 0, width, height)];
  } else {
    CGFloat endX = MAX((paintBox.origin.x + paintBox.size.width),
                       (borderRect.origin.x + borderRect.size.width));
    CGFloat endY = MAX((paintBox.origin.y + paintBox.size.height),
                       (borderRect.origin.y + borderRect.size.height));
    CGFloat startX =
        (self.repeatX == LynxBackgroundRepeatRepeat || self.repeatX == LynxBackgroundRepeatRepeatX)
            ? offsetX - ceil(offsetX / width) * width
            : offsetX;
    CGFloat startY =
        (self.repeatY == LynxBackgroundRepeatRepeat || self.repeatY == LynxBackgroundRepeatRepeatY)
            ? offsetY - ceil(offsetY / height) * height
            : offsetY;

    for (CGFloat x = startX; x < endX; x += width) {
      for (CGFloat y = startY; y < endY; y += height) {
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx, x, y);
        [self onDraw:ctx rect:CGRectMake(0, 0, width, height)];
        CGContextRestoreGState(ctx);

        if (self.repeatY == LynxBackgroundRepeatNoRepeat) {
          break;
        }
      }
      if (self.repeatX == LynxBackgroundRepeatNoRepeat) {
        break;
      }
    }
  }
  CGContextRestoreGState(ctx);
}

- (void)onDraw:(CGContextRef)ctx rect:(CGRect)rect {
}
@end

#pragma mark - LynxBackgroundImageDrawable
@interface LynxBackgroundImageDrawable ()
@property(nonatomic) NSUInteger currentFrame;
@property(nonatomic) NSUInteger *stepArray;
@property(nonatomic) NSUInteger currentStepIndex;
@end

@implementation LynxBackgroundImageDrawable
unsigned long stepArrayLen = 0;

- (void)dealloc {
  if (_stepArray) {
    free(_stepArray);
  }
}

/*
  Returns how many frames should be skipped after drawingInContext;
 */
- (NSUInteger)nextStep {
  if ([_image.images count] / [_image duration] < 30) return 1;
  if (!_stepArray) {
    // Lazy initialization to make sure image is ready.
    [self generateStepArrayWithFPS:([_image.images count] / [_image duration]) andTargetFPS:30];
  }
  _currentStepIndex = _currentStepIndex % stepArrayLen;
  return _stepArray[_currentStepIndex++];
}

- (void)generateStepArrayWithFPS:(NSUInteger)FPS andTargetFPS:(NSUInteger)targetFPS {
  // Every FPS / gcd_ frames should draw targetFPS / gcd_ frames.
  // stepArray[i] means after draw the ith frame should skip next stepArray[i] frames.
  NSUInteger gcdInt, arrayLen, remains;
  gcdInt = gcd(FPS, targetFPS);
  arrayLen = targetFPS / gcdInt;
  remains = FPS / gcdInt;

  unsigned long base = remains / arrayLen;
  remains = remains % arrayLen;

  _stepArray = (NSUInteger *)malloc(arrayLen * sizeof(NSUInteger));
  for (unsigned long i = 0; i < remains; ++i) {
    _stepArray[i] = base + 1;
  }
  for (unsigned long i = remains; i < arrayLen; ++i) {
    _stepArray[i] = base;
  }
  stepArrayLen = arrayLen;
}

NSUInteger gcd(NSUInteger a, NSUInteger b) {
  NSUInteger temp;
  while (b != 0) {
    temp = a % b;
    a = b;
    b = temp;
  }
  return a;
}

- (void)drawInContext:(CGContextRef)ctx
           borderRect:(CGRect)borderRect
          paddingRect:(CGRect)paddingRect
          contentRect:(CGRect)contentRect {
  if (self.image && self.image.images) {
    _currentFrame = _currentFrame % [self.image.images count];
    [super drawInContext:ctx borderRect:borderRect paddingRect:paddingRect contentRect:contentRect];
    _currentFrame += [self nextStep];
  } else {
    [super drawInContext:ctx borderRect:borderRect paddingRect:paddingRect contentRect:contentRect];
  }
}

- (instancetype)initWithURL:(NSURL *)url {
  self = [super init];
  if (self) {
    self.url = url;
    self.image = nil;
  }
  return self;
}

- (instancetype)initWithString:(NSString *)string {
  self = [super init];
  if (self) {
    self.url = [NSURL URLWithString:[self illegalUrlHandler:string]];
    self.image = nil;
  }
  return self;
}

- (NSString *)illegalUrlHandler:(NSString *)value {
  // To handle some illegal symbols, such as chinese characters and [], etc
  // Query + Path characterset will cover all other urlcharacterset
  if (![[NSURL alloc] initWithString:value]) {
    NSMutableCharacterSet *characterSetForEncode = [[NSMutableCharacterSet alloc] init];
    [characterSetForEncode formUnionWithCharacterSet:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [characterSetForEncode formUnionWithCharacterSet:[NSCharacterSet URLPathAllowedCharacterSet]];
    value = [value stringByAddingPercentEncodingWithAllowedCharacters:characterSetForEncode];
  }
  return value;
}

- (BOOL)isReady {
  return self.image != nil;
}

- (CGFloat)getImageWidth {
  if (self.image == nil) {
    return 0;
  }
  return self.image.size.width;
}

- (CGFloat)getImageHeight {
  if (self.image == nil) {
    return 0;
  }
  return self.image.size.height;
}

- (void)onDraw:(CGContextRef)ctx rect:(CGRect)rect {
  UIGraphicsPushContext(ctx);
  if (_image.images && _image.images.count > 0) {
    [_image.images[_currentFrame] drawInRect:rect];
  } else {
    [self.image drawInRect:rect];
  }
  UIGraphicsPopContext();
}
@end

#pragma mark - LynxBackgroundGradientDrawable

@implementation LynxBackgroundGradientDrawable
- (BOOL)isGradient {
  return YES;
}

- (BOOL)isReady {
  return self.gradient != nil;
}

- (void)onDraw:(CGContextRef)ctx rect:(CGRect)rect {
  CGContextSaveGState(ctx);
  CGContextAddRect(ctx, rect);
  CGContextClip(ctx);
  [self.gradient draw:ctx withRect:rect];
  CGContextRestoreGState(ctx);
}
@end

@implementation LynxBackgroundLinearGradientDrawable

- (instancetype)initWithArray:(NSArray *)array {
  self = [super init];
  if (self) {
    if (array == nil) {
      LOGE("linear gradient native parse error, array is null");
    } else if ([array count] < 3) {
      LOGE("linear gradient native parse error, array must have 3 element.");
    } else {
      self.gradient = [[LynxLinearGradient alloc] initWithArray:array];
    }
  }
  return self;
}
@end

@implementation LynxBackgroundRadialGradientDrawable

- (instancetype)initWithArray:(NSArray *)array {
  self = [super init];
  if (self) {
    if (array == nil) {
      LOGE("radial gradient native parse error, array is null");
    } else if ([array count] < 3) {
      LOGE("radial gradient native parse error, array must have 3 element");
    } else {
      self.gradient = [[LynxRadialGradient alloc] initWithArray:array];
    }
  }
  return self;
}
@end

@implementation LynxBackgroundNoneDrawable

- (void)onDraw:(CGContextRef)ctx rect:(CGRect)rect {
  // nothing to do here
}
@end
