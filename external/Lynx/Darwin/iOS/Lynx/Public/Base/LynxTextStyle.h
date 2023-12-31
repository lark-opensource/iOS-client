// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxBackgroundManager.h"
#import "LynxCSSType.h"

NS_ASSUME_NONNULL_BEGIN

#if !defined(__IPHONE_8_2) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_2

#define UIFontWeightUltraLight -0.8
#define UIFontWeightThin -0.6
#define UIFontWeightLight -0.4
#define UIFontWeightRegular 0
#define UIFontWeightMedium 0.23
#define UIFontWeightSemibold 0.3
#define UIFontWeightBold 0.4
#define UIFontWeightHeavy 0.56
#define UIFontWeightBlack 0.62

#endif
@class LynxFontFaceContext;
@protocol LynxFontFaceObserver;

extern NSAttributedStringKey const LynxTextColorGradientKey;

@interface LynxTextStyle : NSObject <NSCopying>

@property(nonatomic, assign) CGFloat fontSize;
@property(nonatomic, assign) CGFloat lineHeight;
@property(nonatomic, assign) CGFloat lineSpacing;
@property(nonatomic, assign) CGFloat letterSpacing;
@property(nonatomic, assign) NSTextAlignment textAlignment;
@property(nonatomic, assign) NSTextAlignment usedParagraphTextAlignment;
@property(nonatomic, assign) NSWritingDirection direction;
@property(nonatomic, assign) CGFloat fontWeight;
@property(nonatomic, assign) LynxFontStyleType fontStyle;
@property(nonatomic, strong, nullable) UIColor* foregroundColor;
@property(nonatomic, strong, nullable) UIColor* backgroundColor;
@property(nonatomic, nullable) NSString* fontFamilyName;
@property(nonatomic, nullable) NSString* underLine;
@property(nonatomic, nullable) NSString* lineThrough;
@property(nonatomic, assign) NSInteger textDecorationStyle;
@property(nonatomic, nullable) UIColor* textDecorationColor;
@property(nonatomic, strong, nullable) NSShadow* textShadow;
@property(nonatomic, strong, nullable) LynxGradient* textGradient;
@property(nonatomic, assign) BOOL enableFontScaling;
@property(nonatomic, assign) CGFloat textIndent;
@property(nonatomic, assign) CGFloat textStrokeWidth;
@property(nonatomic, strong) UIColor* textStrokeColor;
@property(nonatomic, strong) UIColor* selectionColor;

- (NSDictionary<NSAttributedStringKey, id>*)
    toAttributesWithFontFaceContext:(LynxFontFaceContext*)fontFaceContext
               withFontFaceObserver:(id<LynxFontFaceObserver> _Nullable)observer;

- (NSParagraphStyle*)genParagraphStyle;

- (UIFont*)fontWithFontFaceContext:(LynxFontFaceContext*)fontFaceContext
                  fontFaceObserver:(id<LynxFontFaceObserver>)observer;

- (void)applyTextStyle:(LynxTextStyle*)textStyle;
- (void)setTextAlignment:(NSTextAlignment)textAlignment;

@end

NS_ASSUME_NONNULL_END
