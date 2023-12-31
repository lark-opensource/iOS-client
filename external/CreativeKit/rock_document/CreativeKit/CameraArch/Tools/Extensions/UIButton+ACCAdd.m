//
//  UIButton+ACCAdd.m
//  CameraClient
//
//  Created by luochaojing on 2019/12/20.
//

#import "UIButton+ACCAdd.h"

@implementation UIButton (ACCAdd)

- (void)acc_fitWithImageLayout:(ACCButtonImageLayout)layout space:(CGFloat)space {
    UIImageView *imageV = self.imageView;
    UILabel *label = self.titleLabel;
    if (!imageV || !label) {
        return;
    }
    
    CGFloat imageH = imageV.intrinsicContentSize.height;
    CGFloat imageW = imageV.intrinsicContentSize.width;
    CGFloat titleH = label.intrinsicContentSize.height;
    CGFloat titleW = label.intrinsicContentSize.width;
    
    UIEdgeInsets imageInsets = UIEdgeInsetsZero;
    UIEdgeInsets labelInsets = UIEdgeInsetsZero;
    switch (layout) {
        case ACCButtonImageLayoutLeft: {
            imageInsets = UIEdgeInsetsMake(0, -space * 0.5, 0, space * 0.5);
            labelInsets = UIEdgeInsetsMake(0, space * 0.5, 0, -space * 0.5);
        }
            break;
        case ACCButtonImageLayoutRight: {
            CGFloat imageOffset = titleW + space * 0.5;
            CGFloat titleOffset = imageW + space * 0.5;
            imageInsets = UIEdgeInsetsMake(0, imageOffset, 0, -imageOffset);
            labelInsets = UIEdgeInsetsMake(0, -titleOffset, 0, titleOffset);
        }
            break;
        case ACCButtonImageLayoutTop: {
            imageInsets = UIEdgeInsetsMake(-titleH - space, 0, 0, -titleW);
            labelInsets = UIEdgeInsetsMake(0, -imageW, -imageH - space, 0);
        }
            break;
        case ACCButtonImageLayoutBottom: {
            imageInsets = UIEdgeInsetsMake(titleH + space, 0, 0, -titleW);
            labelInsets = UIEdgeInsetsMake(0, -imageW, imageH + space, 0);
        }
            break;
    }
    
    self.imageEdgeInsets = imageInsets;
    self.titleEdgeInsets = labelInsets;
}

@end
