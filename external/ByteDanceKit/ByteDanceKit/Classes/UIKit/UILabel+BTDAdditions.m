//
//  UILabel+BTDAdditions.m
//  Essay
//
//  Created by Tianhang Yu on 12-7-3.
//  Copyright (c) 2012年 Bytedance. All rights reserved.
//

#import "UILabel+BTDAdditions.h"
#import <CoreText/CoreText.h>
#import "NSString+BTDAdditions.h"

@implementation UILabel (BTDAdditions)

- (CGFloat)btd_heightWithWidth:(CGFloat)maxWidth
{
    return [self.text btd_heightWithFont:self.font width:maxWidth];
}

- (CGFloat)btd_widthWithHeight:(CGFloat)maxHeight
{
    return [self.text btd_widthWithFont:self.font height:maxHeight];
}

- (void)btd_SetText:(NSString*)text lineHeight:(CGFloat)lineHeight {
    if (lineHeight < 0.01 || !text) {
        self.text = text;
        return;
    }

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    [attributedString addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, [text length])];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:self.lineBreakMode];
    [paragraphStyle setAlignment:self.textAlignment];
    [paragraphStyle setMaximumLineHeight:lineHeight];
    [paragraphStyle setMinimumLineHeight:lineHeight];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [text length])];

    self.attributedText = attributedString;
}

- (void)btd_setText:(NSString *)originText withNeedHighlightedText:(NSString *)needHighlightText highlightedColor:(UIColor *)color
{
    if (!needHighlightText || ![originText containsString:needHighlightText]) {
        self.text = originText;
    } else {
        NSRange range = [originText rangeOfString:needHighlightText];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:originText];
        [attributedString addAttribute:NSForegroundColorAttributeName value:color range:range];
        self.attributedText = attributedString;
    }
}
@end
