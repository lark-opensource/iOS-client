//
//  UIButton+CJExtension.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/22.
//

#import "UIButton+CJPay.h"
#import "UIImage+CJPay.h"
#import "UIColor+CJPay.h"
#import "CJPayUIMacro.h"
#import "CJPayProtocolManager.h"
#import "CJPayGurdService.h"
#import <BDWebImage/UIButton+BDWebImage.h>

@implementation UIButton (CJPay)

- (void)cj_setBtnTitle:(NSString *)title {
    [self setTitle:title forState:UIControlStateNormal];
    [self setTitle:title forState:UIControlStateSelected];
    [self setTitle:title forState:UIControlStateHighlighted];
}

- (void)cj_setBtnAttributeTitle:(NSAttributedString *)title {
    [self setAttributedTitle:title forState:UIControlStateNormal];
    [self setAttributedTitle:title forState:UIControlStateSelected];
    [self setAttributedTitle:title forState:UIControlStateHighlighted];
}

- (void)cj_setBtnImage:(UIImage *)image {
    [self setImage:image forState:UIControlStateNormal];
    [self setImage:image forState:UIControlStateSelected];
    [self setImage:image forState:UIControlStateHighlighted];
}

- (void)cj_setBtnImageWithName:(NSString *)imageName {
    [self cj_setImageName:imageName forState:UIControlStateNormal];
    [self cj_setImageName:imageName forState:UIControlStateSelected];
    [self cj_setImageName:imageName forState:UIControlStateHighlighted];
}

- (void)cj_setBtnBGImage:(UIImage *)bgImage {
    
    [self setBackgroundImage:bgImage forState:UIControlStateNormal];
    [self setBackgroundImage:bgImage forState:UIControlStateSelected];
    [self setBackgroundImage:bgImage forState:UIControlStateHighlighted];
}

- (void)cj_setBtnBGColor:(UIColor *)color {
    UIColor *disableColor = [color cj_NewColorWith:color alpha:0.3];
    UIImage *disableBgImage = [UIImage cj_imageWithColor:disableColor];
    UIImage *normalBgImage = [UIImage cj_imageWithColor:color];
    [self setBackgroundImage:disableBgImage forState:UIControlStateSelected];
    [self setBackgroundImage:disableBgImage forState:UIControlStateHighlighted];
    [self setBackgroundImage:normalBgImage forState:UIControlStateNormal];
}

- (void)cj_setBtnTitleColor:(UIColor *)color {
    UIColor *disableColor = [color cj_NewColorWith:color alpha:0.3];
    [self setTitleColor:disableColor forState:UIControlStateSelected];
    [self setTitleColor:disableColor forState:UIControlStateHighlighted];
    [self setTitleColor:color forState:UIControlStateNormal];
}

- (void)cj_setBtnSelectColor:(UIColor *)color {
    [self setTitleColor:color forState:UIControlStateSelected];
    [self setTitleColor:color forState:UIControlStateSelected|UIControlStateHighlighted];
}



- (void)cj_setImageName:(NSString *)imageName forState:(UIControlState)state {
    NSString *urlString = [CJ_OBJECT_WITH_PROTOCOL(CJPayGurdService)i_getImageUrlOrName:imageName];
    if (!Check_ValidString(urlString)) {
        return;
    }
    NSString *preStr = [NSString stringWithFormat:@"CJ%@//", UP_Gecko];
    if ([urlString hasPrefix:@"http"]) {
        NSURL *imageUrl = [NSURL URLWithString:urlString];
        [self bd_setImageWithURL:imageUrl forState:state placeholderImage:nil options:BDImageProgressiveDownload|BDImageNoRetry progress:nil completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from){
            if (error) {
                [CJMonitor trackService:@"wallet_rd_cdn_img_fail"
                               category:@{@"image_name" : CJString(imageName),
                                          @"url" : CJString(request.currentRequestURL.absoluteString)
                               }
                                  extra:@{}];
            }
        }];
    } else if([urlString hasPrefix:preStr]){
        NSURL *url = [NSURL fileURLWithPath:[urlString stringByReplacingOccurrencesOfString:preStr withString:@""]];
        [self bd_setImageWithURL:url forState:state placeholderImage:nil options:BDImageProgressiveDownload|BDImageNoRetry progress:nil completed:nil];
    } else {
        UIImage *image = [UIImage cj_imageWithName:urlString];
        [self setImage:image forState:state];
    }
}

- (void)cj_setBtnBGImageName:(NSString *)imageName forState:(UIControlState)state {
    NSString *urlString = [CJ_OBJECT_WITH_PROTOCOL(CJPayGurdService)i_getImageUrlOrName:imageName];
    if (!Check_ValidString(urlString)) {
        return;
    }
    NSString *preStr = [NSString stringWithFormat:@"CJ%@//", UP_Gecko];
    if ([urlString hasPrefix:@"http"]) {
        NSURL *imageUrl = [NSURL URLWithString:urlString];
        [self bd_setBackgroundImageWithURL:imageUrl forState:state placeholderImage:nil options:BDImageProgressiveDownload|BDImageNoRetry progress:nil completed:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from){
            if (error) {
                [CJMonitor trackService:@"wallet_rd_cdn_img_fail"
                               category:@{@"image_name" : CJString(imageName),
                                          @"url" : CJString(request.currentRequestURL.absoluteString)
                               }
                                  extra:@{}];
            }
        }];
    } else if([urlString hasPrefix:preStr]){
        NSURL *url = [NSURL fileURLWithPath:[urlString stringByReplacingOccurrencesOfString:preStr withString:@""]];
        [self bd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:BDImageProgressiveDownload|BDImageNoRetry progress:nil completed:nil];
    } else {
        UIImage *image = [UIImage cj_imageWithName:urlString];
        [self setBackgroundImage:image forState:state];
    }
}

@end
