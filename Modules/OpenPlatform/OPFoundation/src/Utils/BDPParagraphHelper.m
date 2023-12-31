//
//  BDPParagraphHelper.m
//  Timor
//
//  Created by liuxiangxin on 2019/8/22.
//

#import <Foundation/Foundation.h>
#import "BDPParagraphHelper.h"
#import "UIFont+BDPExtension.h"
#import "BDPResponderHelper.h"

static CGFloat kDefaultLinheHeight = 0.f;

@implementation BDPParagraphHelper

+ (CGSize)drawSizeForString:(NSString *)text font:(UIFont *)font window:(UIWindow *)window
{
    // 原始逻辑为取[[UIScreen mainScreen] bounds].size.width
    // 适配iPad时解除屏幕依赖，统一换成用[BDPResponderHelper windowSize]取window的width
    CGFloat width = [BDPResponderHelper windowSize:window].width;
    return [self drawSizeForString:text maxWidth:width font:font];
}

+ (CGSize)drawSizeForString:(NSString *)string maxWidth:(CGFloat)maxWidth font:(UIFont *)font
{
    return [self drawSizeForString:string maxWidth:maxWidth font:font lineHeight:kDefaultLinheHeight];
}

+ (CGSize)drawSizeForString:(NSString *)string
               maxWidth:(CGFloat)maxWidth
                       font:(UIFont *)font
                 lineHeight:(CGFloat)lineHeight
{
    return [self drawSizeForString:string maxWidth:maxWidth font:font lineHeight:lineHeight kern:-0.3f];
}

+ (CGSize)drawSizeForString:(NSString *)string
                   maxWidth:(CGFloat)maxWidth
                       font:(UIFont *)font
                 lineHeight:(CGFloat)lineHeight
                        kern:(CGFloat)kern
{
    if (!font || !string.length) {
        return CGSizeZero;
    }
    
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    NSDictionary *attributes = @{NSParagraphStyleAttributeName: paragraphStyle,
                                 NSFontAttributeName: font,
                                 NSKernAttributeName: @(kern)};
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
    CGRect textRect = [attributedString boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT)
                                                     options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin)
                                                     context:nil];
    return CGSizeMake(textRect.size.width, textRect.size.height);
}

+ (CGSize)drawSizeForString:(NSString *)text fontNameList:(NSArray<NSString *> *)nameList size:(CGFloat)size
{
    if (!text.length || size <= 0) {
        return CGSizeZero;
    }
    
    UIFont *font = [self matchedFontForNameList:nameList size:size];
    return [self drawSizeForString:text maxWidth:MAXFLOAT font:font];
}

+ (UIFont *)matchedFontForNameList:(NSArray<NSString *> *)nameList size:(CGFloat)size
{
    __block UIFont *font = nil;
    [nameList enumerateObjectsUsingBlock:^(NSString * _Nonnull fontName, NSUInteger idx, BOOL * _Nonnull stop) {
        font = [UIFont bdp_fontWithName:fontName size:size];
        if (font) {
            *stop = YES;
        }
    }];
    
    if (!font) {
        font = [UIFont systemFontOfSize:size];
    }
    
    return font;
}

@end
