//
//  UIButton+EMA.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/4.
//

#import "UIButton+EMA.h"


@implementation UIButton (EMA)

- (void)ema_layoutButtonWithEdgeInsetsStyle:(EMAButtonEdgeInsetsStyle)style imageTitlespace:(CGFloat)space {
    self.titleEdgeInsets = UIEdgeInsetsZero;
    self.imageEdgeInsets = UIEdgeInsetsZero;
    CGFloat imageViewWidth = CGRectGetWidth(self.imageView.frame);
    CGFloat labelWidth = CGRectGetWidth(self.titleLabel.frame);

    if (labelWidth == 0) {
        CGSize titleSize = [self.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:self.titleLabel.font}];
        labelWidth  = titleSize.width;
    }

    UIEdgeInsets imageInsets = UIEdgeInsetsZero;
    UIEdgeInsets titleInsets = UIEdgeInsetsZero;

    switch (style) {
        case EMAButtonEdgeInsetsStyleImageRight:
        {
            space = space * 0.5;

            imageInsets.left = labelWidth + space;
            titleInsets.left = - (imageViewWidth + space);

            self.contentEdgeInsets = UIEdgeInsetsMake(0, space, 0, space);
        }
            break;

        case EMAButtonEdgeInsetsStyleImageLeft:
        {
            space = space * 0.5;

            imageInsets.left = -space;
            titleInsets.left = space;

        }
            break;
        case EMAButtonEdgeInsetsStyleImageBottom:
        case EMAButtonEdgeInsetsStyleImageTop:
        {
            CGFloat imageHeight = CGRectGetHeight(self.imageView.frame);
            CGFloat labelHeight = CGRectGetHeight(self.titleLabel.frame);
            CGFloat buttonHeight = CGRectGetHeight(self.frame);
            CGFloat boundsCentery = (imageHeight + space + labelHeight) * 0.5;

            CGFloat centerX_button = CGRectGetMidX(self.bounds); // bounds
            CGFloat centerX_titleLabel = CGRectGetMidX(self.titleLabel.frame);
            CGFloat centerX_image = CGRectGetMidX(self.imageView.frame);

            if (style == EMAButtonEdgeInsetsStyleImageBottom) {
                imageInsets.top = buttonHeight - (buttonHeight * 0.5 - boundsCentery) - CGRectGetMaxY(self.imageView.frame);
                titleInsets.top = (buttonHeight * 0.5 - boundsCentery) - CGRectGetMinY(self.titleLabel.frame);
            } else if (style == EMAButtonEdgeInsetsStyleImageBottom) {
                imageInsets.top = (buttonHeight * 0.5 - boundsCentery) - CGRectGetMinY(self.imageView.frame);
                titleInsets.top = buttonHeight - (buttonHeight * 0.5 - boundsCentery) - CGRectGetMaxY(self.titleLabel.frame);
            }

            imageInsets.left = centerX_button - centerX_image;
            imageInsets.bottom = - imageInsets.top;

            titleInsets.left = -(centerX_titleLabel - centerX_button);
            titleInsets.bottom = - titleInsets.top;

        }
            break;
        default:
            break;
    }

    imageInsets.right = -imageInsets.left;
    titleInsets.right = -titleInsets.left;

    self.imageEdgeInsets = imageInsets;
    self.titleEdgeInsets = titleInsets;
}

@end
