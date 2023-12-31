//
//  UILabel+BTDAdditions.h
//  Essay
//
//  Created by Tianhang Yu on 12-7-3.
//  Copyright (c) 2012年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (BTDAdditions)

/**
 根据宽度计算高度

 @param maxWidth 限行的宽度
 @return 高度
 */
- (CGFloat)btd_heightWithWidth:(CGFloat)maxWidth;

/**
 根据高度计算宽度

 @param maxHeight 限定的高度
 @return 宽度
 */
- (CGFloat)btd_widthWithHeight:(CGFloat)maxHeight;

/**
 设置文本并设置行高

 @param text 文本
 @param lineHeight 行高
 */
- (void)btd_SetText:(nonnull NSString *)text lineHeight:(CGFloat)lineHeight;

/**
 设置文本并设置部分文本高亮

 @param originText 文本
 @param needHighlightText 需要高亮的文本
 @param color 高亮文本的颜色
 */
- (void)btd_setText:(nonnull NSString *)originText withNeedHighlightedText:(nonnull NSString *)needHighlightText highlightedColor:(nonnull UIColor *)color;

@end
