//
//  UILabel+BTDAdditions.h
//  Essay
//
//  Created by Tianhang Yu on 12-7-3.
//  Copyright (c) 2012 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (BTDAdditions)

/**
 Return the height according to he maxWidth.

 @param maxWidth The max width.
 @return The height.
 */
- (CGFloat)btd_heightWithWidth:(CGFloat)maxWidth;

/**
 Return the width according to he maxHeight.

 @param maxHeight The max height.
 @return The width.
 */
- (CGFloat)btd_widthWithHeight:(CGFloat)maxHeight;

/**
 Set the label's text and the text's line height.

 @param text The text.
 @param lineHeight The line height of the text.
 */
- (void)btd_SetText:(nonnull NSString *)text lineHeight:(CGFloat)lineHeight;

/**
 Set the label's text and highlight the partial text.

 @param originText The text.
 @param needHighlightText The highlighting text.
 @param color The highlighting color.
 */
- (void)btd_setText:(nonnull NSString *)originText withNeedHighlightedText:(nonnull NSString *)needHighlightText highlightedColor:(nonnull UIColor *)color;

@end
