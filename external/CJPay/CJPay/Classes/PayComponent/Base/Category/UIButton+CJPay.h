//
//  UIButton+CJPay.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/22.
//

#import <UIKit/UIKit.h>

@interface UIButton (CJPay)

- (void)cj_setBtnTitle:(NSString *)title;

- (void)cj_setBtnAttributeTitle:(NSAttributedString *)title;

- (void)cj_setBtnImage:(UIImage *)image;

- (void)cj_setBtnImageWithName:(NSString *)imageName;

- (void)cj_setBtnBGImage:(UIImage *)bgImage; 

- (void)cj_setBtnBGColor:(UIColor *)color;

- (void)cj_setBtnTitleColor:(UIColor *)color;

- (void)cj_setImageName:(NSString *)imageName forState:(UIControlState)state;

- (void)cj_setBtnSelectColor:(UIColor *)color;

@end
