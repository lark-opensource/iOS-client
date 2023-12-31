//
//  UILabel+ACCAdditions.m
//  AWEFoundation
//
// Created by Hao Yipeng on December 29, 2017
//  Copyright  ©  Byedance. All rights reserved, 2017
//

#import "UILabel+ACCAdditions.h"
#import <CreativeKit/ACCFontProtocol.h>

@implementation UILabel (ACCAdditions)

- (instancetype)acc_initWithFont:(UIFont *)font textColor:(UIColor *)textColor text:(NSString *)text
{
    UILabel *instance = [[UILabel alloc] init];
    if (instance) {
        instance.font = font;
        instance.textColor = textColor;
        instance.text = text;
    }
    return instance;
}

- (instancetype)acc_initWithFontSize:(CGFloat)fontSize isBold:(BOOL)isBold textColor:(UIColor *)textColor text:(NSString *)text
{
    UIFont *font = isBold ? [ACCFont() boldSystemFontOfSize:fontSize] : [ACCFont() systemFontOfSize:fontSize];
    return [self acc_initWithFont:font textColor:textColor text:text];
}

- (void)acc_addShadowWithShadowColor:(UIColor *)color shadowOffset:(CGSize)offset shadowRadius:(CGFloat)shadowRadius {
    self.layer.shadowColor = color.CGColor;
    self.layer.shadowOffset = offset;
    self.layer.shadowRadius = shadowRadius;
    self.layer.shadowOpacity = 1.0f;
}

- (void)acc_addShadowWithShadowColor:(UIColor *)color shadowOffset:(CGSize)offset shadowRadius:(CGFloat)shadowRadius shadowOpacity:(CGFloat)shadowOpacity {
    [self acc_addShadowWithShadowColor:color shadowOffset:offset shadowRadius:shadowRadius];
    self.layer.shadowOpacity = shadowOpacity;
}

- (void)acc_sizeToFitWidth:(CGFloat)width
{
    CGSize size = [self.text boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                            options:NSStringDrawingUsesLineFragmentOrigin
                         attributes:@{NSFontAttributeName: self.font}
                            context:nil].size;
    CGRect labelFrame = self.frame;
    labelFrame.size.width = size.width;
    labelFrame.size.height = size.height;
    self.frame = labelFrame;
}

@end
