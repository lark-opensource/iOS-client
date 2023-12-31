//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxPropsAttributeConverter.h"
#import "LynxConverter+LynxCSSType.h"
#import "LynxConverter+NSShadow.h"
#import "LynxConverter+UI.h"
#import "LynxConverter.h"
#import "LynxFontFaceManager.h"
#import "LynxLog.h"
#import "LynxTextStyle.h"

@interface LynxPropsAttributeConverter ()

@property(nonatomic, strong) LynxTextStyle *textStyle;

@end

@implementation LynxPropsAttributeConverter

- (instancetype)init {
  self = [super init];
  if (self) {
    _textStyle = [LynxTextStyle new];
  }
  return self;
}

// handle css attribute and convert the value to the object value save in textstyle
- (BOOL)updateTextStyleWithCssAttributes:(NSDictionary<NSString *, id> *)props {
  BOOL hasCustomFont = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  for (NSString *key in props) {
    if ([key containsString:@"font"]) {
      hasCustomFont = YES;
    }
    NSString *selectorStr = [self styleMethod][key];
    SEL selector = NSSelectorFromString(selectorStr);
    if (selectorStr && [self respondsToSelector:selector]) {
      [self performSelector:selector withObject:props[key]];
    } else {
      LLogFatal(@"Unexpected style key");
    }
  }
#pragma clang diagnostic pop
  return hasCustomFont;
}

- (NSDictionary<NSAttributedStringKey, id> *)convertDynamicAttributes:
    (NSDictionary<NSString *, id> *)props {
  NSDictionary<NSAttributedStringKey, id> *result = [NSDictionary new];
  BOOL hasFont = [self updateTextStyleWithCssAttributes:props];
  NSMutableDictionary *temp =
      [[self.textStyle toAttributesWithFontFaceContext:[LynxFontFaceContext new]
                                  withFontFaceObserver:nil] mutableCopy];
  if (!hasFont) {
    temp[NSFontAttributeName] = nil;
  }
  result = [temp copy];
  return result;
}

- (NSDictionary<NSAttributedStringKey, id> *)
    convertDynamicAttribute:(NSDictionary<NSString *, id> *)props
       withOriginAttributes:(NSDictionary<NSAttributedStringKey, id> *)attributes {
  NSMutableDictionary<NSAttributedStringKey, id> *currentAttributes = [attributes mutableCopy];
  [currentAttributes addEntriesFromDictionary:[self convertDynamicAttributes:props]];
  return [currentAttributes copy];
}

#pragma mark - text style
- (NSDictionary *)styleMethod {
  return @{
    @"font-size" : @"setFontSize:",
    @"background-color" : @"setBackgroundColor:",
    @"color" : @"setColor:",
    @"font-weight" : @"setFontWeight:",
    @"font-style" : @"setFontStyle:",
    @"line-height" : @"setLineHeight:",
    @"line-spacing" : @"setLineSpacing:",
    @"letter-spacing" : @"setLetterSpacing:",
    @"font-family" : @"setFontFamily:",
    @"direction" : @"setDirection:",
    @"text-align" : @"setTextAlign:",
    @"text-decoration" : @"setTextDecoration:",
    @"text-shadow" : @"setTextShadow:",
    @"enable-font-scaling" : @"setEnableFontScaling:"
  };
}

- (void)setFontSize:(id)prop {
  CGFloat value = [LynxConverter toCGFloat:prop];
  if (_textStyle.fontSize != value) {
    _textStyle.fontSize = value;
  }
}

- (void)setBackgroundColor:(UIColor *)value {
  if (_textStyle.backgroundColor != value) {
    _textStyle.backgroundColor = value;
  }
}

- (void)setColor:(id)value {
  if (value == nil) {
    _textStyle.foregroundColor = [UIColor blackColor];
    _textStyle.textGradient = nil;
  } else if ([value isKindOfClass:NSNumber.class]) {
    _textStyle.foregroundColor = [LynxConverter toUIColor:value];
    _textStyle.textGradient = nil;
  } else {
    _textStyle.foregroundColor = [UIColor blackColor];
    if ([value isKindOfClass:NSArray.class]) {
      [self setTextGradient:(NSArray *)value];
    } else {
      [self setTextGradient:nil];
    }
  }
}

- (void)setTextGradient:(NSArray *)value {
  if (value == nil || [value count] < 2 || ![value[1] isKindOfClass:[NSArray class]]) {
    _textStyle.textGradient = nil;
  } else {
    NSUInteger type = [LynxConverter toNSUInteger:value[0]];
    NSArray *args = (NSArray *)value[1];
    if (type == LynxBackgroundImageLinearGradient) {
      _textStyle.textGradient = [[LynxLinearGradient alloc] initWithArray:args];
    } else if (type == LynxBackgroundImageRadialGradient) {
      _textStyle.textGradient = [[LynxRadialGradient alloc] initWithArray:args];
    }
  }
}

- (void)setFontWeight:(id)prop {
  LynxFontWeightType value = [LynxConverter toLynxFontWeightType:prop];
  if (value == LynxFontWeightNormal) {
    _textStyle.fontWeight = UIFontWeightRegular;
  } else if (value == LynxFontWeightBold) {
    _textStyle.fontWeight = UIFontWeightBold;
  } else if (value == LynxFontWeight100) {
    _textStyle.fontWeight = UIFontWeightUltraLight;
  } else if (value == LynxFontWeight200) {
    _textStyle.fontWeight = UIFontWeightThin;
  } else if (value == LynxFontWeight300) {
    _textStyle.fontWeight = UIFontWeightLight;
  } else if (value == LynxFontWeight400) {
    _textStyle.fontWeight = UIFontWeightRegular;
  } else if (value == LynxFontWeight500) {
    _textStyle.fontWeight = UIFontWeightMedium;
  } else if (value == LynxFontWeight600) {
    _textStyle.fontWeight = UIFontWeightSemibold;
  } else if (value == LynxFontWeight700) {
    _textStyle.fontWeight = UIFontWeightBold;
  } else if (value == LynxFontWeight800) {
    _textStyle.fontWeight = UIFontWeightHeavy;
  } else if (value == LynxFontWeight900) {
    _textStyle.fontWeight = UIFontWeightBlack;
  } else {
    _textStyle.fontWeight = UIFontWeightRegular;
  }
}

- (void)setFontStyle:(id)prop {
  LynxFontStyleType value = [LynxConverter toLynxFontStyleType:prop];
  if (_textStyle.fontStyle != value) {
    _textStyle.fontStyle = value;
  }
}

- (void)setLineHeight:(id)prop {
  CGFloat value = [LynxConverter toCGFloat:prop];
  if (_textStyle.lineHeight != value) {
    _textStyle.lineHeight = value;
  }
}

- (void)setLineSpacing:(id)prop {
  CGFloat value = [LynxConverter toCGFloat:prop];
  if (_textStyle.lineSpacing != value) {
    _textStyle.lineSpacing = value;
  }
}

- (void)setLetterSpacing:(id)prop {
  CGFloat value = [LynxConverter toCGFloat:prop];
  if (_textStyle.letterSpacing != value) {
    _textStyle.letterSpacing = value;
  }
}

- (void)setFontFamily:(NSString *)value {
  if (value && ![value isEqualToString:_textStyle.fontFamilyName]) {
    _textStyle.fontFamilyName = value;
  }
}

- (void)setDirection:(id)prop {
  LynxDirectionType value = [LynxConverter toLynxDirectionType:prop];
  if (value == LynxDirectionNormal) {
    _textStyle.direction = NSWritingDirectionNatural;
  } else if (value == LynxDirectionLtr) {
    _textStyle.direction = NSWritingDirectionLeftToRight;
  } else {
    _textStyle.direction = NSWritingDirectionRightToLeft;
  }
}

- (void)setTextAlign:(id)prop {
  LynxTextAlignType value = [LynxConverter toLynxTextAlignType:prop];
  if (value == LynxTextAlignLeft) {
    _textStyle.textAlignment = NSTextAlignmentLeft;
  } else if (value == LynxTextAlignRight) {
    _textStyle.textAlignment = NSTextAlignmentRight;
  } else if (value == LynxTextAlignCenter) {
    _textStyle.textAlignment = NSTextAlignmentCenter;
  } else if (value == LynxTextAlignStart) {
    _textStyle.textAlignment = NSTextAlignmentNatural;
  } else {
    LLogFatal(@"Unexpected text align type");
  }
}

- (void)setTextDecoration:(NSArray *)value {
  NSInteger textDecorationLine = [LynxConverter toNSInteger:value[0]];
  NSInteger textDecorationStyle = [LynxConverter toNSInteger:value[1]];
  NSInteger color = [LynxConverter toNSInteger:value[2]];
  UIColor *textDecorationColor = [LynxConverter toUIColor:value[2]];

  if (textDecorationLine & LynxTextDecorationUnderLine) {
    _textStyle.underLine = NSUnderlineStyleAttributeName;
  }
  if (textDecorationLine & LynxTextDecorationLineThrough) {
    _textStyle.lineThrough = NSStrikethroughStyleAttributeName;
  }

  switch (textDecorationStyle) {
    case LynxTextDecorationSolid:
      _textStyle.textDecorationStyle = NSUnderlineStylePatternSolid;
      break;
    case LynxTextDecorationDouble:
      _textStyle.textDecorationStyle = NSUnderlineStyleDouble;
      break;
    case LynxTextDecorationDotted:
      _textStyle.textDecorationStyle = NSUnderlineStylePatternDot;
      break;
    case LynxTextDecorationDashed:
      _textStyle.textDecorationStyle = NSUnderlineStylePatternDash;
      break;
    default:
      _textStyle.textDecorationStyle = NSUnderlineStyleSingle;
  }

  if (color != 0) {
    _textStyle.textDecorationColor = textDecorationColor;
  }
}

- (void)setTextShadow:(NSArray *)value {
  NSArray<LynxBoxShadow *> *shadowArr = [LynxConverter toLynxBoxShadow:value];
  _textStyle.textShadow = [LynxConverter toNSShadow:shadowArr];
}

- (void)setEnableFontScaling:(id)prop {
  BOOL value = [LynxConverter toBOOL:prop];
  _textStyle.enableFontScaling = value;
}

@end
