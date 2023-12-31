//
//  BDPParagraphHelper.h
//  Timor
//
//  Created by liuxiangxin on 2019/8/22.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface BDPParagraphHelper : NSObject

/**
 计算文本的绘制区域尺寸

 @param text 待计算的字符串
 @param nameList 字体列表
 @param size 字号
 @return 文本的绘制尺寸
 @discussion 计算时会从头开始遍历nameList寻找第一个系统中存在的字体
 */
+ (CGSize)drawSizeForString:(NSString *)text fontNameList:(NSArray<NSString *> *)nameList size:(CGFloat)size;
/**
 以屏幕宽度为最大宽度，计算文本的绘制区域尺寸
 
 最大的绘制宽度是屏幕的宽度

 @param text 待计算的文本字符串
 @param font 字体
 @return 文本的绘制尺寸
 */
+ (CGSize)drawSizeForString:(NSString *)text font:(UIFont *)font window:(UIWindow *)window;
/**
 计算文本绘制区域尺寸

 @param string 带计算的文本字符串
 @param maxWidth 最大显示宽度
 @param font 文本字体
 @return 绘制区域尺寸
 @discussion 行高使用字体默认行间距
 */
+ (CGSize)drawSizeForString:(NSString *)string maxWidth:(CGFloat)maxWidth font:(UIFont *)font;
/**
 计算文本绘制区域尺寸

 @param string 待计算的文本
 @param maxWidth 文本绘制区域最大宽度
 @param font 字体
 @param lineHeight 行号
 @return 绘制区域尺寸
 @discussion 字间距默认使用-0.3f
 */
+ (CGSize)drawSizeForString:(NSString *)string
                   maxWidth:(CGFloat)maxWidth
                       font:(UIFont *)font
                 lineHeight:(CGFloat)lineHeight;
/**
 计算文本绘制区域尺寸
 
 @param string 待计算的文本
 @param maxWidth 文本绘制区域最大宽度
 @param font 字体
 @param lineHeight 行号
 @param kern 字间距
 @return 绘制区域尺寸
 */
+ (CGSize)drawSizeForString:(NSString *)string
                   maxWidth:(CGFloat)maxWidth
                       font:(UIFont *)font
                 lineHeight:(CGFloat)lineHeight
                        kern:(CGFloat)kern;

@end
