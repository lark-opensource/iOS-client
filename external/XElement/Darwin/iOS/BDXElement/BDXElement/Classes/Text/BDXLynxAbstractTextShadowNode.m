//
//  BDXLynxAbstractTextShadowNode.m
//  BDXElement
//
//  Created by li keliang on 2020/6/8.
//

#import "BDXLynxAbstractTextShadowNode.h"

#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxConverter+NSShadow.h>
#import <Lynx/LynxFontFaceManager.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>

#import <objc/runtime.h>

@interface BDXLynxAbstractTextShadowNode() <LynxFontFaceObserver>

@end

@implementation BDXLynxAbstractTextShadowNode

LYNX_PROP_SETTER("color", color, UIColor*)
{
    UIColor *oldValue = self.textStyle.textColor;
    if (requestReset) {
        self.textStyle.textColor = [UIColor blackColor];
    }
    if ([value isKindOfClass:UIColor.class]) {
        self.textStyle.textColor = value;
    }
    if (oldValue != self.textStyle.textColor) {
        [self setNeedsLayout];
    }
}

LYNX_PROP_SETTER("no-trim", noTrim, BOOL) {
    self.textStyle.noTrim = value;
    [self setNeedsLayout];
}

LYNX_PROP_SETTER("font-size", setFontSize, CGFloat) {
  if (self.textStyle.fontSize != value) {
    self.textStyle.fontSize = value;
    [self resetFontWithTextStyle];
    [self setNeedsLayout];
  }
}

LYNX_PROP_SETTER("background-color", setBackgroundColor, UIColor*) {
    UIColor *oldValue = self.textStyle.backgroundColor;
    if (requestReset) {
        self.textStyle.backgroundColor = nil;
    }
    if ([value isKindOfClass:UIColor.class]) {
        self.textStyle.backgroundColor = value;
    }
    if (oldValue != self.textStyle.backgroundColor) {
        [self setNeedsLayout];
    }
}

LYNX_PROP_SETTER("font-weight", setFontWeight, LynxFontWeightType) {
  if (requestReset) {
    value = LynxFontWeightNormal;
  }
  if (value == LynxFontWeightNormal) {
    self.textStyle.fontWeight = UIFontWeightRegular;
  } else if (value == LynxFontWeightBold) {
    self.textStyle.fontWeight = UIFontWeightBold;
  } else if (value == LynxFontWeight100) {
    self.textStyle.fontWeight = UIFontWeightUltraLight;
  } else if (value == LynxFontWeight200) {
    self.textStyle.fontWeight = UIFontWeightThin;
  } else if (value == LynxFontWeight300) {
    self.textStyle.fontWeight = UIFontWeightLight;
  } else if (value == LynxFontWeight400) {
    self.textStyle.fontWeight = UIFontWeightRegular;
  } else if (value == LynxFontWeight500) {
    self.textStyle.fontWeight = UIFontWeightMedium;
  } else if (value == LynxFontWeight600) {
    self.textStyle.fontWeight = UIFontWeightSemibold;
  } else if (value == LynxFontWeight700) {
    self.textStyle.fontWeight = UIFontWeightBold;
  } else if (value == LynxFontWeight800) {
    self.textStyle.fontWeight = UIFontWeightHeavy;
  } else if (value == LynxFontWeight900) {
    self.textStyle.fontWeight = UIFontWeightBlack;
  } else {
    self.textStyle.fontWeight = UIFontWeightRegular;
  }
  [self resetFontWithTextStyle];
  [self setNeedsLayout];
}

LYNX_PROP_SETTER("font-style", setFontStyle, LynxFontStyleType) {
  if (requestReset) {
    value = LynxFontStyleNormal;
  }
  if (self.textStyle.fontStyle != value) {
    self.textStyle.fontStyle = value;
    [self resetFontWithTextStyle];
    [self setNeedsLayout];
  }
}

LYNX_PROP_SETTER("line-height", setLineHeight, CGFloat) {
    if (self.textStyle.paragraphStyle.minimumLineHeight != value) {
        [self resetParagraphStyle:^(NSMutableParagraphStyle *paragraphStyle) {
            paragraphStyle.minimumLineHeight = value;
            paragraphStyle.maximumLineHeight = value;
        }];
        [self setNeedsLayout];
    }
}

LYNX_PROP_SETTER("line-spacing", setLineSpacing, CGFloat) {
    if (self.textStyle.paragraphStyle.lineSpacing != value) {
        [self resetParagraphStyle:^(NSMutableParagraphStyle *paragraphStyle) {
            paragraphStyle.lineSpacing = value;
        }];
        [self setNeedsLayout];
    }
}

LYNX_PROP_SETTER("letter-spacing", setLetterSpacing, CGFloat) {
    if (self.textStyle.letterSpacing != value) {
        self.textStyle.letterSpacing = value;
    }
    [self setNeedsLayout];
}

LYNX_PROP_SETTER("font-family", setFontFamily, NSString*) {
    if (requestReset) {
        value = nil;
    }
    if ((requestReset && self.textStyle.fontFamily) ||
      (value && ![value isEqualToString:self.textStyle.fontFamily])) {
        self.textStyle.fontFamily = value;
       [self resetFontWithTextStyle];
       [self setNeedsLayout];
   }
}

LYNX_PROP_SETTER("text-align", setTextAlign, LynxTextAlignType) {
    if (requestReset) {
        value = LynxTextAlignStart;
    }
    
    NSTextAlignment lineAlignment = NSTextAlignmentNatural;
    if (value == LynxTextAlignLeft) {
        lineAlignment = NSTextAlignmentLeft;
    } else if (value == LynxTextAlignCenter) {
        lineAlignment = NSTextAlignmentCenter;
    } else if (value == LynxTextAlignRight) {
        lineAlignment = NSTextAlignmentRight;
    } else if (value == LynxTextAlignStart) {
        lineAlignment = NSTextAlignmentNatural;
    }
    
    [self resetParagraphStyle:^(NSMutableParagraphStyle *paragraphStyle) {
        paragraphStyle.alignment = lineAlignment;
    }];
    [self setNeedsLayout];
}

LYNX_PROP_SETTER("direction", setDirection, LynxDirectionType) {
    if (requestReset) {
        value = LynxDirectionNormal;
    }
    
    NSWritingDirection direction = NSWritingDirectionNatural;
    if (value == LynxDirectionNormal) {
        direction = NSWritingDirectionNatural;
    } else if (value == LynxDirectionLtr) {
        direction = NSWritingDirectionLeftToRight;
    } else if (value == LynxDirectionRtl) {
        direction = NSWritingDirectionRightToLeft;
    }
    
    [self resetParagraphStyle:^(NSMutableParagraphStyle *paragraphStyle) {
        paragraphStyle.baseWritingDirection = direction;
    }];
    [self setNeedsLayout];
}

LYNX_PROP_SETTER("text-decoration", setTextDecoration, LynxTextDecorationType) {
    if (requestReset) {
        value = LynxTextDecorationNone;
    }
  
    self.textStyle.textDecoration = value;
    [self setNeedsLayout];
}

LYNX_PROP_SETTER("text-shadow", setTextShadow, NSArray*) {
    if (requestReset) {
        value = nil;
    }
    NSArray<LynxBoxShadow*>* shadowArr = [LynxConverter toLynxBoxShadow:value];
    self.textStyle.textShadow = [LynxConverter toNSShadow:shadowArr];
    [self setNeedsLayout];
}

LYNX_PROP_SETTER("text-maxline", numberOfLines, NSInteger) {
    self.textStyle.numberOfLines = value;
    [self setNeedsLayout];
}

LYNX_PROP_SETTER("text-stroke-width", setTextStrokeWidth, CGFloat) {
  if (requestReset) {
    value = NAN;
  }
  if (self.textStyle.textStrokeWidth != value) {
    self.textStyle.textStrokeWidth = value;
    [self setNeedsLayout];
  }
}

LYNX_PROP_SETTER("text-stroke-color", setTextStrokeColor, UIColor*) {
  if (requestReset) {
    value = nil;
  }
  if ([value isKindOfClass:UIColor.class]) {
    self.textStyle.textStrokeColor = value;
  } else if (!value) {
    self.textStyle.textStrokeColor = [UIColor blackColor];
  }
  if (self.textStyle.textStrokeWidth != NAN) {
    [self setNeedsLayout];
  }
}


LYNX_PROP_SETTER("ellipsize-mode", ellipsizeMode, NSString*){
    if ([value isEqualToString:@"head"]) {
        self.textStyle.truncatingMode = BDXLynxRichTextTruncatingHead;
    } else if ([value isEqualToString:@"middle"]) {
        self.textStyle.truncatingMode = BDXLynxRichTextTruncatingMiddle;
    } else if ([value isEqualToString:@"tail"]) {
        self.textStyle.truncatingMode = BDXLynxRichTextTruncatingTail;
    } else if ([value isEqualToString:@"clip"]) {
        self.textStyle.truncatingMode = BDXLynxRichTextTruncatingClip;
    }
    [self setNeedsLayout];
}

- (void)onFontFaceLoad {
    [self setNeedsLayout];
}

#pragma mark - Helpers

- (void)resetFontWithTextStyle
{
    LynxFontFaceContext* fontFaceContext = [self.uiOwner fontFaceContext];
    UIFont *font = [[LynxFontFaceManager sharedManager]
      generateFontWithSize:self.textStyle.fontSize
                    weight:self.textStyle.fontWeight
                     style:self.textStyle.fontStyle
            fontFamilyName:self.textStyle.fontFamily
           fontFaceContext:fontFaceContext
          fontFaceObserver:self];
    self.textStyle.font = font;
}

- (void)resetParagraphStyle:(void(^)(NSMutableParagraphStyle *paragraphStyle))block
{
    if (block) {
        NSMutableParagraphStyle *style = [self.textStyle.paragraphStyle mutableCopy];
        block(style);
        self.textStyle.paragraphStyle = style;
    }
}

#pragma mark - Accessors

- (BDXLynxRichTextStyle *)textStyle
{
    if (!_textStyle) {
        _textStyle = [[BDXLynxRichTextStyle alloc] init];
        _textStyle.enableTextLanguageAlignment = self.uiOwner.uiContext.enableTextLanguageAlignment;
        
        LynxLayoutNode *parent = self.parent;
        while ([parent isKindOfClass:LynxLayoutNode.class] && !_textStyle.defaultAttriutes) {
            if ([parent isKindOfClass:BDXLynxAbstractTextShadowNode.class]) {
                _textStyle.defaultAttriutes = [((BDXLynxAbstractTextShadowNode *)parent).textStyle.defaultAttriutes mutableCopy];
            }
            parent = parent.parent;
        }
    }
    return _textStyle;
}

- (nullable NSAttributedString *)inlineAttributeString
{
    return nil;
}

@end

