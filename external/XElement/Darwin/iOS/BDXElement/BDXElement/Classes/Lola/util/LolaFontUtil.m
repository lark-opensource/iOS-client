//
//  LolaFontUtil.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/4.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "LolaFontUtil.h"

@implementation LolaTextStyle

@end

@implementation LolaFontUtil

+(UIFont *)parseFontWithStyle:(NSString *)stringStyle
{
    LolaTextStyle *fontStyle = [LolaTextStyle new];
    NSArray *styleArr = [stringStyle componentsSeparatedByString:@" "];
    
    for (NSString *style in styleArr) {
        if ([style hasSuffix:@"px"]) {
            fontStyle.fontSize = [[style stringByReplacingOccurrencesOfString:@"px" withString:@""] floatValue];
        } else if ([self fontWeightWithKey:style]) {
            fontStyle.fontWeight = [[self fontWeightWithKey:style] floatValue];
        } else if ([self fontStyleWithValue:style]) {
            fontStyle.fontStyle = [[self fontStyleWithValue:style] intValue];
        }
    }
    
    return [self getFontFromTextStyle:fontStyle];
}

+ (UIFont *)getFontFromTextStyle:(LolaTextStyle *)style
{
    UIFont *font = [UIFont systemFontOfSize:style.fontSize];
    
    UIFontWeight fontWeight = style.fontWeight;
    NSInteger fontSize = style.fontSize;
    
    if (@available(iOS 8.2, *)) {
      font = [UIFont systemFontOfSize:fontSize weight:fontWeight];
    } else if (fontWeight >= UIFontWeightBold) {
      font = [UIFont boldSystemFontOfSize:fontSize];
    } else if (fontWeight >= UIFontWeightMedium) {
      font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:fontSize];
    } else if (fontWeight <= UIFontWeightLight) {
      font = [UIFont fontWithName:@"HelveticaNeue-Light" size:fontSize];
    } else {
      font = [UIFont systemFontOfSize:fontSize];
    }
    
    if (style.fontStyle != LolaFontStyleNormal) {
        
        CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);
        //fix CN italic
        UIFontDescriptor * fontD = [font.fontDescriptor fontDescriptorByAddingAttributes:@{
            UIFontDescriptorMatrixAttribute : [NSValue valueWithCGAffineTransform:matrix]
        }];
        font = [UIFont fontWithDescriptor:fontD size:0];
    }
    
    return font;
}

+(NSNumber *)fontWeightWithKey:(NSString *)key
{
    if (key.length <= 0) {
        return nil;
    }
    
    static dispatch_once_t onceToken;
    static NSDictionary *weightDic = nil;

    dispatch_once(&onceToken, ^{
        weightDic = @{
            @"normal" : @(UIFontWeightRegular),
            @"bold"   : @(UIFontWeightBold),
            @"100"    : @(UIFontWeightUltraLight),
            @"200"    : @(UIFontWeightThin),
            @"300"    : @(UIFontWeightLight),
            @"400"    : @(UIFontWeightRegular),
            @"500"    : @(UIFontWeightMedium),
            @"600"    : @(UIFontWeightSemibold),
            @"700"    : @(UIFontWeightBold),
            @"800"    : @(UIFontWeightHeavy),
            @"200"    : @(UIFontWeightBlack),
        };
    });
    
    NSNumber *weight = [weightDic objectForKey:key];
//    return weight ? [weight floatValue] : UIFontWeightRegular;
    return weight;
}

+ (NSNumber *)fontStyleWithValue:(NSString *)value {
    if (value.length <= 0) {
        return nil;
    }
    static dispatch_once_t onceToken;
    static NSDictionary *styleDic = nil;

    dispatch_once(&onceToken, ^{
        styleDic = @{
            @"normal"   : @(LolaFontStyleNormal),
            @"italic"   : @(LolaFontStyleItalic),
            @"oblique"  : @(LolaFontStyleOblique),
        };
    });
    
    NSNumber *style = [styleDic objectForKey:value];
    return style;
}

- (CGFloat)fontWeightOfFont:(UIFont *)font {
  static NSArray *fontNames;
  static NSArray *fontWeights;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    fontNames = @[
      @"normal", @"ultralight", @"thin", @"light", @"regular", @"medium", @"semibold", @"demibold",
      @"extrabold", @"bold", @"heavy", @"black"
    ];
      
    fontWeights = @[
      @(UIFontWeightRegular), @(UIFontWeightUltraLight), @(UIFontWeightThin), @(UIFontWeightLight),
      @(UIFontWeightRegular), @(UIFontWeightMedium), @(UIFontWeightSemibold),
      @(UIFontWeightSemibold), @(UIFontWeightHeavy), @(UIFontWeightBold), @(UIFontWeightHeavy),
      @(UIFontWeightBlack)
    ];
  });

  for (NSInteger i = 0; i < fontNames.count; i++) {
    if ([font.fontName.lowercaseString hasSuffix:fontNames[i]]) {
      return [fontWeights[i] doubleValue];
    }
  }

  NSDictionary *traits = [font.fontDescriptor objectForKey:UIFontDescriptorTraitsAttribute];
  return [traits[UIFontWeightTrait] doubleValue];
}

@end
